# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Add to path for both bash and pwsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc

# Download and install Node.js:
nvm install 22

# Verify the Node.js version:
node -v # Should print "v22.17.0".
nvm current # Should print "v22.17.0".

# Verify npm version:
npm -v # Should print "10.9.2".

# Copilot CLI
#npm install -g @github/copilot
#copilot --version

# Claude 
npm install -g @anthropic-ai/claude-code
claude --version

# Gemini Cli
npm install -g @google/gemini-cli

# BMAD
npx bmad-method install -f -i gemini claude-code github-copilot -d .