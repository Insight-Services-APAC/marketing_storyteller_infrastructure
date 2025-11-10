# Install zip
sudo apt-get update
sudo apt-get install -y curl
sudo apt-get install -y zip

# Install Oh My Posh
curl -s https://ohmyposh.dev/install.sh | bash -s -- -t "/.local/bin/themes/"

# Add /bin to the PATH environment variable
$env:PATH += ":/bin"

sudo apt-get install -y fontconfig
oh-my-posh font install CascadiaCode 

# Suggest setting font to Cascadia Code NFM in vs code settings
# "terminal.integrated.fontFamily": "CaskaydiaCove Nerd Font, monospace",
# PowerShell script to set VS Code terminal font family

# Define the path to VS Code user settings
$settingsPath = "$env:APPDATA\Code\User\settings.json"

# Check if the settings file exists
if (-Not (Test-Path $settingsPath)) {
    # Create an empty JSON if it does not exist
    '{}' | Out-File -FilePath $settingsPath -Encoding utf8
}

# Read the existing settings JSON
$settingsContent = Get-Content -Raw -Path $settingsPath | ConvertFrom-Json

# Set the terminal font family
$settingsContent."terminal.integrated.fontFamily" = "CaskaydiaCove Nerd Font, monospace"

# Save the updated settings back to settings.json
$settingsContent | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding utf8

Write-Host "VS Code terminal font family set to 'CaskaydiaCove Nerd Font, monospace' successfully!"


Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
Install-Module -Name posh-git -Scope CurrentUser -Force

# Install Git 
sudo apt install git -y

#### GH CLI for Authentication with GitHub ####
bash .devcontainer/git_cli_install.sh 

# Copy sample profile to home directory
if (-not (Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}
cp .devcontainer/pwsh_profile_sample.txt $PROFILE

# Pip Installs 
apt-get install python3-pip -y
sudo apt install python3.12-venv -y
if (-not (Test-Path ".venv")) {
    python3 -m venv .venv
}
if ((Test-Path ".venv/bin/activate.ps1")) {
    ./.venv/bin/activate.ps1
}
if ((Test-Path ".venv/lib/activate.ps1")) {
    ./.venv/lib/activate.ps1
}

python3 -m venv .venv
source ./.venv/bin/activate
pip install uv

# NPM
bash .devcontainer/npm_install.sh

# Speckit
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git