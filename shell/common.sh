# shell/common.sh — config shared by bash and zsh.
# Deployed to ~/.shellrc by install.sh and sourced from .zshrc and .bashrc.
# Keep this POSIX-ish: it's read by both shells, so no bash- or zsh-only syntax.

# Default editor
export VISUAL=vim
export EDITOR="$VISUAL"

# Detect platform so config can branch where it must: macos | wsl | linux
case "$OSTYPE" in
  darwin*) export OS=macos ;;
  *) if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then export OS=wsl; else export OS=linux; fi ;;
esac

# PATH (guard the bits that only exist on some machines)
export PATH="$HOME/bin:$PATH"
[ -d "${ASDF_DATA_DIR:-$HOME/.asdf}/shims" ] && export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export PATH="$HOME/.local/bin:$PATH"
[ -d /snap/bin ] && export PATH="$PATH:/snap/bin"

# Git helpers
alias current-branch='git rev-parse --abbrev-ref HEAD'
alias changed-files='git diff HEAD --name-only | grep "$(basename "$PWD")/"'
alias make-pr='git push -u origin $(current-branch)'

# Cross-platform clipboard, backed by bin/clip (pbcopy / clip.exe / xclip / wl-copy)
alias pbcopy='clip'
alias pbpaste='clip-paste'

# ssh-agent + key
alias sag='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519'

# Employer-specific config (HEROKU app, work tooling) — see shell/employer.sh
[ -f ~/.shellrc.employer ] && . ~/.shellrc.employer

# Machine-specific / secret config (per-host paths, tokens) — not committed.
[ -f ~/.shellrc.local ] && . ~/.shellrc.local
