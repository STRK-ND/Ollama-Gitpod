#!/bin/bash

echo "🚀 Starting Ollama Setup..."

# Step 1: Configure environment
echo "⚙️ Configuring environment..."
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

# Step 4: Pull and install Llama2 model
echo "🤖 Installing Llama2 model..."
ollama pull llama2

# Step 5: Install Cloudflared if not present
echo "☁️ Setting up Cloudflare tunnel..."
if ! command -v cloudflared &> /dev/null; then
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
fi

# Fix for Cloudflared group ID error
echo "🔧 Configuring Cloudflared permissions..."
# Create cloudflared group if it doesn't exist
sudo groupadd -g 65534 cloudflared || true
# Add current user to cloudflared group
sudo usermod -a -G cloudflared $USER
# Set proper permissions
sudo chown root:cloudflared /usr/local/bin/cloudflared
sudo chmod 755 /usr/local/bin/cloudflared

# Start Cloudflare tunnel
echo "🌐 Starting Cloudflare tunnel..."
# Run cloudflared with the correct group
sudo -g cloudflared cloudflared tunnel --url http://localhost:11434 --http-host-header="localhost:11434"

echo "✅ Setup complete! Ollama is now running and accessible through Cloudflare tunnel." 