# Add deno completions to search path
if [[ ":$FPATH:" != *":/home/aj/.zsh/completions:"* ]]; then export FPATH="/home/aj/.zsh/completions:$FPATH"; fi
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit ice depth=1; zinit light jeffreytse/zsh-vi-mode
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
#zinit light MichaelAquilina/zsh-autoswitch-virtualenv

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
#zinit snippet OMZP::aws
#zinit snippet OMZP::kubectl
#zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
function zvm_after_init() {
    bindkey '^o' autosuggest-accept
    bindkey '^p' history-search-backward
    bindkey '^n' history-search-forward
    bindkey '^[w' kill-region
}
# bindkey -v
#bindkey '^p' history-search-backward
#bindkey '^n' history-search-forward
#bindkey '^[w' kill-region
# bindkey '^o' autosuggest-accept
# bindkey '^p' history-search-backward
# bindkey '^n' history-search-forward
# bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Functions
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# aliases
alias ls='lsd'
# alias vim='nvim'
alias c='clear'
alias ll='lsd -lh'
alias la='lsd -lah'
alias tree='lsd --tree'
alias S='yay -S'
alias Ss='yay -Ss'
alias gedit='gnome-text-editor'
# alias nano='nvim'
alias cat='bat'
alias py='python3'
alias pn='cat /sys/class/power_supply/BAT0/power_now'
alias sw='cat /tmp/specialworkspace'
alias ..='cd ..'
alias ~='cd ~'
alias co='curl -O'
alias update-mirrors='sudo reflector -a 48 -c JP -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist'
alias 60fps='hyprctl keyword monitor ,1920x1080@60,,1'
alias 144fps='hyprctl keyword monitor ,1920x1080@144,,1'
alias Quiet='asusctl profile -P Quiet'
alias Balanced='asusctl profile -P Balanced'
alias Performance='asusctl profile -P Performance'
alias incognito='unset HISTFILE'

alias charge='asusctl -c'
alias keyboard_color='asusctl aura static -c 803dba'

alias home-server='ssh home-server'
alias aj-server='ssh aj-server'
alias source-zsh='source ~/.zshrc'

alias mpv-hehe='/mnt/AJ/Projects/mpv-shim-hehe/main'

alias animation-off='hyprctl keyword animations:enabled 0'
alias animation-on='hyprctl keyword animations:enabled 1'

alias nvrun='switcherooctl launch -g 1'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
# eval "$(starship init zsh)"
# eval "$(warp-cli generate-completions zsh)"

#if [[ $TERM != "tmux-"* && $TERM_PROGRAM != "vscode" ]]; then
#source ~/.config/zshrc.d/dots-hyprland.zsh
#fi
if [[ $TERM == "xterm-kitty" ]]; then
    alias ssh='kitty +kitten ssh'
fi

#source ~/.config/zshrc.d/auto-Hypr.sh
# source /etc/profile

# source ~/.bash_profile

#eval $(warp-cli generate-completions zsh)

PATH="/home/aj/.local/bin/:/home/aj/.bin:/home/aj/.config/hypr/scripts:$PATH"
PATH="${PATH}:/opt/android-sdk/platform-tools"
PATH="$PATH:$(go env GOBIN):$(go env GOPATH)/bin"
PATH="/home/aj/.bun/bin:$PATH"

# pnpm
export PNPM_HOME="/home/aj/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

. "/home/aj/.deno/env"

# bun completions
[ -s "/home/aj/.bun/_bun" ] && source "/home/aj/.bun/_bun"
