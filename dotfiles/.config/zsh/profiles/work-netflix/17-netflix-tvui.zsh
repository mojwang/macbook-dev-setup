# Netflix TVUI Development (work-netflix profile)
# Deployed by: ./setup.sh --profile work-netflix

# Newt PATH setup
if [[ -x /usr/local/bin/newt ]]; then
  # Homebrew install — already on PATH
  :
elif [[ -d "$HOME/.newt/bin" ]]; then
  export PATH="$HOME/.newt/bin:$PATH"
fi

# Large monorepo needs bigger git http buffer for pushes
git config --global http.postBuffer 536870912  # 512MB

# Quick cd into tvui repo
alias tvui='cd ~/repos/netflix/consumer/t2-tvui'

# ./tvui CLI aliases (run from repo root)
alias tvb='./tvui client --watch'
alias tvt='./tvui test'
alias tvtf='./tvui test --file'
alias tvl='./tvui lint --only-changed'
alias tvf='./tvui format --only-changed'
alias tvtc='./tvui typecheck'
alias tvgql='./tvui graphql compile'
alias tvc='./tvui clean'
alias tvv='./tvui verify development-environment'
