#!/bin/bash

# Dotfiles Installation Script
# Creates symlinks and sets up the dotfiles environment

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Print section header
section() {
  echo -e "\n${GREEN}==>${NC} ${BLUE}$1${NC}"
}

# Print info message
info() {
  echo -e "  ${BLUE}Info:${NC} $1"
}

# Print success message
success() {
  echo -e "  ${GREEN}Success:${NC} $1"
}

# Print warning message
warning() {
  echo -e "  ${YELLOW}Warning:${NC} $1"
}

# Print error message
error() {
  echo -e "  ${RED}Error:${NC} $1"
}

# Create a symlink if it doesn't exist
create_symlink() {
  local src="$1"
  local dest="$2"
  
  if [ -L "$dest" ]; then
    local current_target=$(readlink "$dest")
    if [ "$current_target" = "$src" ]; then
      info "Link already exists: $dest -> $src"
    else
      warning "Different link exists: $dest -> $current_target"
      warning "Updating to: $dest -> $src"
      rm "$dest"
      ln -s "$src" "$dest"
      success "Updated link: $dest -> $src"
    fi
  elif [ -e "$dest" ]; then
    warning "File exists at $dest"
    read -p "  Backup and replace? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      mv "$dest" "${dest}.backup.$(date +%Y%m%d%H%M%S)"
      ln -s "$src" "$dest"
      success "Backed up original and created link: $dest -> $src"
    else
      warning "Skipped: $dest"
    fi
  else
    ln -s "$src" "$dest"
    success "Created link: $dest -> $src"
  fi
}

# Check for required tools
check_requirements() {
  section "Checking requirements"
  
  local required_cmds=("zsh" "git")
  local missing=0
  
  for cmd in "${required_cmds[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      error "Missing required command: $cmd"
      missing=1
    else
      info "Found required command: $cmd"
    fi
  done
  
  # Check for optional but recommended tools
  local optional_cmds=("mise")
  for cmd in "${optional_cmds[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      warning "Missing recommended tool: $cmd"
    else
      info "Found recommended tool: $cmd"
    fi
  done
  
  if [ $missing -eq 1 ]; then
    error "Please install missing requirements and run again"
    exit 1
  fi
}

# Create required directories
create_directories() {
  section "Creating required directories"
  
  # Create bin directory if it doesn't exist
  if [ ! -d "$HOME/bin" ]; then
    mkdir -p "$HOME/bin"
    success "Created $HOME/bin directory"
  else
    info "$HOME/bin directory already exists"
  fi
}

# Setup ZSH configuration
setup_zsh() {
  section "Setting up ZSH configuration"
  
  # Check if .zshrc already sources our files
  if [ -f "$HOME/.zshrc" ]; then
    local found_source=0
    if grep -q "dotfiles/zsh" "$HOME/.zshrc"; then
      found_source=1
    fi
    
    if [ $found_source -eq 1 ]; then
      info "Dotfiles are already sourced in .zshrc"
    else
      warning ".zshrc exists but doesn't source dotfiles"
      warning "Please add the following to your .zshrc:"
      echo -e "${YELLOW}"
      echo "# Source dotfiles modules"
      echo "source $DOTFILES_DIR/zsh/aliases.zsh"
      echo "source $DOTFILES_DIR/zsh/path.zsh"
      echo "source $DOTFILES_DIR/zsh/plugins.zsh"
      echo "source $DOTFILES_DIR/zsh/mise.zsh"
      echo "source $DOTFILES_DIR/zsh/dev-tools.zsh"
      echo -e "${NC}"
    fi
  else
    # If .zshrc doesn't exist, create a simple one that sources our modules
    cat > "$HOME/.zshrc" << EOF
# Machine-specific variables
export MACHINE_TYPE="personal"  # Change to "work", "server", etc. as needed

# Source dotfiles modules
source $DOTFILES_DIR/zsh/aliases.zsh
source $DOTFILES_DIR/zsh/path.zsh
source $DOTFILES_DIR/zsh/plugins.zsh
source $DOTFILES_DIR/zsh/mise.zsh
source $DOTFILES_DIR/zsh/dev-tools.zsh

# Machine-specific configurations below this line
# Example: if [[ "\$MACHINE_TYPE" == "work" ]]; then
#   source ~/work-config.zsh
# fi
EOF
    success "Created new .zshrc file with dotfiles sourcing"
  fi
}

# Setup Git configuration
setup_git() {
  section "Setting up Git configuration"
  
  if [ -d "$DOTFILES_DIR/git" ]; then
    create_symlink "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
    create_symlink "$DOTFILES_DIR/git/gitignore_global" "$HOME/.gitignore_global"
  else
    warning "No git configuration found in dotfiles"
  fi
}

# Install scripts to bin
install_scripts() {
  section "Installing scripts to bin directory"
  
  if [ -d "$DOTFILES_DIR/bin" ]; then
    for script in "$DOTFILES_DIR/bin"/*; do
      if [ -f "$script" ]; then
        local script_name=$(basename "$script")
        create_symlink "$script" "$HOME/bin/$script_name"
        chmod +x "$script"
        chmod +x "$HOME/bin/$script_name"
      fi
    done
    success "Installed scripts to $HOME/bin"
  else
    warning "No bin directory found in dotfiles"
  fi
}

# Setup mise (if installed)
setup_mise() {
  section "Setting up mise version manager"
  
  if command -v mise &> /dev/null; then
    if [ ! -f "$HOME/.mise.toml" ]; then
      cat > "$HOME/.mise.toml" << EOF
[tools]
# Default tool versions
node = "latest"
# Add more tools as needed
# ruby = "latest"
# python = "latest"
EOF
      success "Created default .mise.toml configuration"
    else
      info "Existing .mise.toml configuration found"
    fi
  else
    warning "mise not installed, skipping configuration"
    warning "To install mise: brew install mise (macOS) or see https://mise.jdx.dev/getting-started.html"
  fi
}

# Main installation
main() {
  echo -e "${GREEN}==============================================${NC}"
  echo -e "${GREEN}       Dotfiles Installation Script         ${NC}"
  echo -e "${GREEN}==============================================${NC}"
  echo -e "Installing dotfiles from: ${BLUE}$DOTFILES_DIR${NC}"
  
  check_requirements
  create_directories
  setup_zsh
  setup_git
  install_scripts
  setup_mise
  
  echo -e "\n${GREEN}==============================================${NC}"
  echo -e "${GREEN}       Installation Complete!               ${NC}"
  echo -e "${GREEN}==============================================${NC}"
  echo -e "\nTo apply changes immediately, run: ${BLUE}source ~/.zshrc${NC}"
}

# Run the installation
main "$@"