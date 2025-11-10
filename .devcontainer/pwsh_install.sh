###################################
# Prerequisites

# Update the list of packages
# Install sudo 
apt-get update 
apt-get install -y sudo
sudo apt-get update

# Install pre-requisite packages.
sudo apt-get install -y wget



if [ "$(uname -m)" = "aarch64" ]; then
    # If ARM, install the necessary packages for ARM architecture
    # ARM Version Below:
    sudo apt install -y \
        libc6 \
        libgcc-s1 \
        libgssapi-krb5-2 \
        libicu72 \
        libssl3 \
        libstdc++6 \
        zlib1g
    wget https://github.com/PowerShell/PowerShell/releases/download/v7.5.3/powershell-7.5.3-linux-arm64.tar.gz
    sudo mkdir -p ~/powershell
    sudo tar -xvf powershell-*-linux-arm64.tar.gz -C ~/powershell
    sudo chmod +x ~/powershell/pwsh
    sudo ln -s ~/powershell/pwsh /usr/local/bin/pwsh
    # Remove the downloaded tar file
    rm powershell-*-linux-arm64.tar.gz
else
    # If not ARM, we assume it's x86_64 and proceed with the x86_64 installation
    echo "Detected architecture is not ARM, proceeding with x86_64 installation."
    # If x86_64, install the necessary packages for x86_64 architecture
    # Get the version of Debian
    source /etc/os-release

    # Download the Microsoft repository GPG keys
    wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.5.3/powershell-7.5.3-linux-x64.tar.gz
    
    sudo mkdir -p ~/powershell
    sudo tar -xvf powershell-*-linux-x64.tar.gz -C ~/powershell
    sudo chmod +x ~/powershell/pwsh
    sudo ln -s ~/powershell/pwsh /usr/local/bin/pwsh
    # Remove the downloaded tar file
    rm powershell-*-linux-x64.tar.gz

    # Start PowerShell
    # pwsh
    # Container postCreate won't proceed to dev tools install if this is uncommented
    
fi