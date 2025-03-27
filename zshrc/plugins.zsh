# Syntax highlighting
source /usr/local/share/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Spaceship ZSH prompt setup
fpath=($fpath "$HOME/.zfunctions")
autoload -U promptinit; promptinit
prompt spaceship