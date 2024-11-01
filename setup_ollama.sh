#!/bin/bash

echo "🚀 Starting Ollama Setup..."

# Step 1: Configure environment and install dependencies
echo "⚙️ Configuring environment..."
# Install GPU detection tools and CUDA dependencies
sudo apt-get update
sudo apt-get install -y lshw nvidia-cuda-toolkit

# Check for GPU and install appropriate drivers
echo "🔍 Checking for GPU..."
if sudo lshw -C display | grep -i nvidia > /dev/null; then
    echo "NVIDIA GPU detected"
    # Install NVIDIA drivers if not present
    if ! command -v nvidia-smi &> /dev/null; then
        echo "Installing NVIDIA drivers..."
        sudo apt-get install -y nvidia-driver-525
        sudo systemctl restart docker
    fi
elif sudo lshw -C display | grep -i amd > /dev/null; then
    echo "AMD GPU detected"
    # Install ROCm for AMD GPUs
    echo "Installing ROCm drivers..."
    sudo apt-get install -y rocm-opencl-runtime
else
    echo "No GPU detected, continuing with CPU-only setup"
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Starting Docker service..."
    sudo service docker start
fi

# Step 2: Download and install Ollama
echo "📥 Downloading and installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Step 3: Start Ollama server in the background
echo "🔄 Starting Ollama server..."
ollama serve &
# Wait for server to start
sleep 10

# Step 4: Model Selection Menu
echo "📋 Available Models:"
echo "1) llama3.1"
echo "2) mistral-nemo"
echo "3) deepseek-coder-v2"
echo "4) codestral"
echo "5) Install All Models"

read -p "Select a model to install (1-5): " model_choice

install_model() {
    local model=$1
    echo "🤖 Installing $model..."
    ollama pull $model
    if ollama list | grep -q "$model"; then
        echo "✅ $model installed successfully"
    else
        echo "❌ Failed to install $model"
    fi
}

case $model_choice in
    1)
        install_model "llama3.1"
        ;;
    2)
        install_model "mistral-nemo"
        ;;
    3)
        install_model "deepseek-coder-v2"
        ;;
    4)
        install_model "codestral"
        ;;
    5)
        echo "🔄 Installing all models..."
        install_model "llama3.1"
        install_model "mistral-nemo"
        install_model "deepseek-coder-v2"
        install_model "codestral"
        ;;
    *)
        echo "❌ Invalid choice. Exiting..."
        exit 1
        ;;
esac

# Step 5: Install and configure Ngrok
echo "🔄 Setting up Ngrok tunnel..."

# Install Ngrok if not present
if ! command -v ngrok &> /dev/null; then
    echo "Installing Ngrok..."
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
    sudo apt update && sudo apt install ngrok
fi

# Load Ngrok auth token from .env file
if [ -f .env ]; then
    source .env
    if [ -n "$NGROK_AUTH_TOKEN" ]; then
        ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
    else
        echo "❌ NGROK_AUTH_TOKEN not found in .env file"
        exit 1
    fi
else
    echo "❌ .env file not found"
    exit 1
fi

# Start Ngrok tunnel with the correct configuration
echo "🌐 Starting Ngrok tunnel..."
ngrok http --log stderr 11434 --host-header "localhost:11434" --domain solid-hugely-gorilla.ngrok-free.app &

echo "✅ Setup complete! Ollama is now running and accessible through Ngrok at https://solid-hugely-gorilla.ngrok-free.app"