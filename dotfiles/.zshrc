

if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

  autoload -Uz compinit
  compinit
fi

if command -v eza >/dev/null; then
    alias ls="~/.scripts/exa-wrapper.sh"
else
    alias ls="/bin/ls $LS_OPTIONS"
fi

alias ll="ls -aghl"
alias cat="bat"
alias ip="ipconfig getifaddr en0"
alias home="cd ~"
alias reload="source ~/.zshrc"
alias copy="rsync -ahr --progress"
alias trash="mv --force -t ~/.local/share/Trash "

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

if command -v pyenv 1>/dev/null 2>&1; then eval "$(pyenv init -)"; fi

eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
# Claude CLI OAuth token will be set up during installation
# Run: claude setup-token
