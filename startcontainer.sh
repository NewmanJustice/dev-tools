CONTAINER_NAME="CourtArrival_devcontainer"

# Check if F5 VPN is running
if ! pgrep -f "F5 VPN" > /dev/null; then
  echo "WARNING: F5 VPN is not running. Please start the F5 VPN client (BIG-IP Edge Client) before continuing."
  echo "To start the VPN, open: https://portal.platform.hmcts.net/saml/sp/profile/post/acs"
  read -p "Press Enter to continue after starting F5 VPN..."
else
  echo "F5 VPN is running."
fi
if docker info > /dev/null 2>&1; then
  echo "Docker Desktop is running."
else
  echo "Docker Desktop is not running."
  open -a docker
fi
# Wait for Docker to be available
until docker info > /dev/null 2>&1; do
  echo "Waiting for Docker Desktop to start..."
  sleep 5
done
docker run --privileged -it --rm \
  --name $CONTAINER_NAME \
  -v "$HOME/.bash_history:/home/vscode/.bash_history" \
  -v "$HOME/.zsh_history:/home/vscode/.zsh_history" \
  -v "$HOME/.azure:/home/vscode/.azure" \
  -v "$HOME/.kube:/home/vscode/.kube" \
  -v "$(pwd):/workspaces/$(basename $(pwd))" \
  -w /workspaces/$(basename $(pwd)) \
  mcr.microsoft.com/devcontainers/base:ubuntu

container_id=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.ID}}")
code --remote-container $container_id