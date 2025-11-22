[[ -f ~/.config/zsh/completions.zsh ]] && source ~/.config/zsh/completions.zsh
[[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh
[[ -f ~/.config/zsh/plugins.zsh ]] && source ~/.config/zsh/plugins.zsh

eval "$(starship init zsh)"

echo -e "\n💻 Welcome, $(whoami)! \nToday is $(date '+%A, %d %B %Y'). \nOK LETS GO!!! 🚀🔥🤘"
