#!/bin/bash

set -e

EXT_VERSION="0.12.2"
EXT_ID="srl-labs.vscode-containerlab"
VSIX_URL="https://github.com/srl-labs/containerlab-vscode-extension/releases/download/v${EXT_VERSION}/${EXT_ID}-${EXT_VERSION}.vsix"
EXT_DIR="$HOME/.local/share/code-server/extensions/${EXT_ID}-${EXT_VERSION}-universal"

# Prompt user for password
read -s -p "🔐 Enter a strong password for code-server: " CODE_SERVER_PASSWORD
echo ""

echo "✅ Installing code-server..."
curl -fsSL https://code-server.dev/install.sh | sh

echo "🔐 Generating self-signed certificate..."
mkdir -p ~/.config/code-server
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout ~/.config/code-server/self-signed.key \
  -out ~/.config/code-server/self-signed.crt \
  -subj "/CN=localhost"

echo "⚙️ Creating code-server config..."
cat > ~/.config/code-server/config.yaml <<EOF
bind-addr: 0.0.0.0:8443
auth: password
password: ${CODE_SERVER_PASSWORD}
cert: ~/.config/code-server/self-signed.crt
cert-key: ~/.config/code-server/self-signed.key
EOF

echo "▶️ Enabling code-server as a service..."
sudo systemctl enable --now code-server@$USER

echo "🧩 Installing Containerlab extension..."
mkdir -p ~/.local/share/code-server/extensions
cd ~/.local/share/code-server/extensions
wget -q "$VSIX_URL" -O containerlab.vsix
code-server --install-extension ./containerlab.vsix

echo "🩹 Patching extension to increase maxBuffer..."
# Patch inspect.js
INSPECT_JS="${EXT_DIR}/out/commands/inspect.js"
if grep -q "execAsync(command" "$INSPECT_JS"; then
  sed -i 's/execAsync(command, {/execAsync(command, { timeout: 15000, maxBuffer: 10 * 1024 * 1024, /g' "$INSPECT_JS"
fi

# Patch clabTreeDataProvider.js
TREE_JS="${EXT_DIR}/out/clabTreeDataProvider.js"
if grep -q "execAsync(cmd)" "$TREE_JS"; then
  sed -i 's/execAsync(cmd)/execAsync(cmd, { timeout: 15000, maxBuffer: 10 * 1024 * 1024 })/g' "$TREE_JS"
fi

echo "🔁 Restarting code-server..."
sudo systemctl restart code-server@$USER

echo "✅ Done!"
echo ""
echo "🌐 Access code-server at: https://<your-server-ip>:8443"
echo "⚠️ WARNING:"
echo "   You will likely see a certificate warning in your browser."
echo "   ⚠️ Google Chrome and Microsoft Edge have known issues trusting self-signed certs with localhost/remote IPs."
echo "   ✅ It's best to use Firefox which handles self-signed certs more reliably."
echo "   🐞 More details: https://github.com/coder/code-server/issues/3410"
