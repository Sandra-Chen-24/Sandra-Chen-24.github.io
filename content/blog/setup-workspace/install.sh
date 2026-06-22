# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# ohmyzsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 基本設置
brew install --cask tunnelblick
brew install --cask iterm2
brew install --cask sourcetree
brew install --cask orbstack
## cp image
brew install crane
brew install k9s
brew install kubectx
brew install go
npm install -g wscat
brew install --cask postman

## gcp
brew install --cask google-cloud-sdk
gcloud components install gke-gcloud-auth-plugin

## terraform
brew install terraform
brew install tfenv
tfenv install 1.7.5
tfenv install 1.10.5
brew install terragrunt

## helm
brew install kubernetes-helm
helm plugin install https://github.com/databus23/helm-diff --verify=false

＃ DB
brew install --cask another-redis-desktop-manager
brew install --cask tableplus

# 小工具
brew install --cask raycast
brew install fzf

# AI
brew install node
npm install -g @google/gemini-cli
