# Git related aliases
gitfetch() {
  git fetch --all
  git checkout $1
  git rebase
}
alias main="gitfetch main"
alias master="gitfetch master"

# System utility aliases
alias macspoof="openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//' | xargs sudo ifconfig en0 ether"
alias lostmybranch="git for-each-ref --count=10 --sort=-committerdate refs/heads/ --format='%(refname:short) %(committerdate:relative)'"

