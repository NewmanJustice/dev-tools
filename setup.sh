#!/usr/bin/env bash
set -e

# Ensure a `node` executable is available for CLIs that hardcode `#!/usr/bin/env node`.
ensure_node_runtime() {
	if command -v node >/dev/null 2>&1; then
		return 0
	fi

	# Fallback to VS Code server's bundled Node runtime.
	local vscode_node
	vscode_node=$(find /home/vscode/.vscode-server/bin -maxdepth 2 -type f -name node 2>/dev/null | sort | tail -n 1 || true)

	if [ -n "$vscode_node" ]; then
		mkdir -p "$HOME/.local/bin"
		ln -sf "$vscode_node" "$HOME/.local/bin/node"
		export PATH="$HOME/.local/bin:$PATH"
	fi

	if ! command -v node >/dev/null 2>&1; then
		echo "❌ Node runtime not found. Rebuild the devcontainer or install nodejs before running setup."
		exit 1
	fi
}

ensure_node_runtime

# Install Bun
echo "Installing Bun..."
curl -fsSL https://bun.sh/install | bash

# Load Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Verify installation
echo "Bun version: $(bun --version)"

# Install GitHub Copilot CLI
echo "Installing GitHub Copilot CLI..."
bun install -g @github/copilot

# Verify GitHub Copilot CLI installation
echo "GitHub Copilot CLI installed: version $(copilot --version | head -n 1)"

# Optional: ensure Playwright browsers are installed globally
# npx playwright install --with-deps

# Install kubelogin for AKS authentication
echo "Installing kubelogin..."
KUBELOGIN_VERSION=$(curl -s https://api.github.com/repos/Azure/kubelogin/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -sSL "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip" -o /tmp/kubelogin.zip
unzip -q /tmp/kubelogin.zip -d /tmp
sudo mv /tmp/bin/linux_amd64/kubelogin /usr/local/bin/
sudo chmod +x /usr/local/bin/kubelogin
rm -rf /tmp/kubelogin.zip /tmp/bin
echo "✅ kubelogin ${KUBELOGIN_VERSION} installed"

# Configure bash history for unlimited size
echo "Configuring bash history..."
BASHRC_PATH="/home/vscode/.bashrc"
if ! grep -q "# CourtArrival devcontainer shell settings" "$BASHRC_PATH"; then
cat >> "$BASHRC_PATH" << 'EOF'

# CourtArrival devcontainer shell settings
# Ensure local user binaries are on PATH
export PATH="$HOME/.local/bin:$PATH"

# Ensure Bun global binaries are on PATH
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Unlimited bash history
HISTSIZE=-1
HISTFILESIZE=-1
EOF
else
	echo "Bash shell settings already configured; skipping append."
fi
echo "✅ Bash history configured"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ ! -d "$repo_root/.github" ]; then
	cp -R "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.github" "$repo_root/"
fi

echo "✅ Dev container setup complete."

exec $SHELL