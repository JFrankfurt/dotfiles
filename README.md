# Dotfiles

A modular configuration system for shell environments and developer tools.

## Structure

```
dotfiles/
├── bin/                    # Executable scripts (added to PATH)
│   └── git-leaderboard     # Git contributor statistics script
├── zsh/                    # ZSH configuration modules
│   ├── aliases.zsh         # Command shortcuts and functions
│   ├── path.zsh            # PATH and environment variables
│   ├── plugins.zsh         # Plugin configuration
│   ├── mise.zsh            # mise runtime version manager setup
│   └── dev-tools.zsh       # Development tools configuration
├── git/                    # Git configuration
│   ├── gitconfig           # Global git settings
│   └── gitignore_global    # Global gitignore rules
├── install.sh              # Installation script
└── README.md               # This file
```

## Principles

1. **Modularity**: Each file should focus on one specific aspect of configuration
2. **Machine independence**: Core configurations stay consistent across all machines
3. **Local customization**: Machine-specific settings live in the local ~/.zshrc
4. **Performance**: Heavy operations should be optimized or lazy-loaded

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles

# Run the installer
cd ~/dotfiles && ./install.sh
```

## Setting Up a New Machine

1. Install prerequisites:

   ```bash
   # macOS
   brew install mise zsh-syntax-highlighting
   ```

2. Clone and install dotfiles:

   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles && ./install.sh
   ```

3. Create a minimal ~/.zshrc that sources the modules:

   ```bash
   # ~/.zshrc
   # Machine-specific variables
   export MACHINE_TYPE="personal"  # or "work", "server", etc.

   # Source core configs from dotfiles repo
   source ~/dotfiles/zsh/aliases.zsh
   source ~/dotfiles/zsh/path.zsh
   source ~/dotfiles/zsh/plugins.zsh
   source ~/dotfiles/zsh/mise.zsh
   source ~/dotfiles/zsh/dev-tools.zsh

   # Machine-specific configurations
   if [[ "$MACHINE_TYPE" == "work" ]]; then
     # Work-specific settings
     # example: source ~/work-config.zsh
   fi
   ```

## Adding New Configuration

### For shell aliases or functions

Add to `~/dotfiles/zsh/aliases.zsh` for portability across all machines.

### For PATH or environment variables

Add to `~/dotfiles/zsh/path.zsh` for consistent environment setup.

### For machine-specific settings

Add directly to the local `~/.zshrc` after the sourcing of shared modules.

### For executable scripts

1. Add script to `~/dotfiles/bin/`
2. Make executable: `chmod +x ~/dotfiles/bin/your-script`
3. Ensure `~/dotfiles/bin` is in your PATH (managed in path.zsh)

## Version Managers

This setup uses mise to manage language runtimes:

```bash
# Install a specific version
mise install node@18.16.0

# Set default version
mise use --global node@18.16.0

# Project-specific version
cd your-project
mise use node@16.14.0
```

## Updating

```bash
cd ~/dotfiles
git pull
./install.sh  # Run the installer to apply any changes
```
