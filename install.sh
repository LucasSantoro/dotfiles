#!/usr/bin/env bash
#
# install.sh — set up these dotfiles on a new machine.
#
#   ./install.sh          symlink the dotfiles into $HOME (default)
#   ./install.sh --deps    install external dependencies too, then link
#                          (apt on Linux/WSL, Homebrew on macOS)
#   ./install.sh --help
#
# Linking backs up anything it would overwrite into a timestamped dir and is
# idempotent. The --deps step is also idempotent (skips what's already there).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Platform: macos | wsl | linux
case "$OSTYPE" in
  darwin*) OS=macos ;;
  *) if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then OS=wsl; else OS=linux; fi ;;
esac

usage() {
  echo "Usage: ./install.sh [--deps] [--help]"
  echo "  (no args)  symlink dotfiles into \$HOME"
  echo "  --deps     install external dependencies first (apt / Homebrew), then link"
}

# --------------------------------------------------------------------------
# linking
# --------------------------------------------------------------------------

# link_file <src> <dest> [label]
link_file() {
  local src="$1" dest="$2" label="${3:-$(basename "$2")}"
  if [ ! -e "$src" ]; then
    echo "skip:   $label (missing in repo)"; return
  fi
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok:     $label already linked"; return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$backup_dir"; mv "$dest" "$backup_dir/"
    echo "backup: $label -> $backup_dir/"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "link:   $label -> $src"
}

link_dotfiles() {
  echo "==> Linking dotfiles into \$HOME"
  local f
  for f in .bashrc .profile .tmux.conf .vimrc .zshrc .gitconfig .tool-versions; do
    link_file "$DOTFILES_DIR/$f" "$HOME/$f" "$f"
  done
  link_file "$DOTFILES_DIR/shell/common.sh"   "$HOME/.shellrc"          ".shellrc"
  link_file "$DOTFILES_DIR/shell/employer.sh" "$HOME/.shellrc.employer" ".shellrc.employer"
  if [ -d "$DOTFILES_DIR/bin" ]; then
    local src
    for src in "$DOTFILES_DIR"/bin/*; do
      [ -e "$src" ] || continue
      link_file "$src" "$HOME/bin/$(basename "$src")" "bin/$(basename "$src")"
    done
  fi
}

# --------------------------------------------------------------------------
# dependencies
# --------------------------------------------------------------------------

_apt_updated=
# pkg_install <pkg>...  — install via the platform package manager
pkg_install() {
  if [ "$OS" = macos ]; then
    brew install "$@"
  else
    if [ -z "$_apt_updated" ]; then sudo apt-get update; _apt_updated=1; fi
    sudo apt-get install -y "$@"
  fi
}

ensure_brew() {
  command -v brew >/dev/null 2>&1 && return
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if   [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew   ]; then eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_deps() {
  echo "==> Installing dependencies ($OS)"
  [ "$OS" = macos ] && ensure_brew

  # Tools the package manager ships directly
  pkg_install git curl zsh tmux vim ripgrep
  [ "$OS" = macos ] && pkg_install asdf

  # oh-my-zsh (not packaged); KEEP_ZSHRC so it leaves our linked .zshrc alone
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "==> oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "ok:     oh-my-zsh already installed"
  fi

  # dracula theme (ZSH_THEME in .zshrc) — clone + symlink the theme file
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [ ! -e "$zsh_custom/themes/dracula.zsh-theme" ]; then
    echo "==> dracula theme"
    git clone --depth 1 https://github.com/dracula/zsh.git "$zsh_custom/themes/dracula"
    ln -sf "$zsh_custom/themes/dracula/dracula.zsh-theme" "$zsh_custom/themes/dracula.zsh-theme"
  else
    echo "ok:     dracula theme already installed"
  fi

  # fzf via its own installer so it writes ~/.fzf.zsh / ~/.fzf.bash (our rc sources these).
  # --no-update-rc: don't let it edit the rc files; we already source them.
  if [ ! -d "$HOME/.fzf" ]; then
    echo "==> fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-update-rc
  else
    echo "ok:     fzf already installed"
  fi

  # vim-plug (.vimrc also self-bootstraps this on first launch)
  if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    echo "==> vim-plug"
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    echo "ok:     vim-plug already installed"
  fi

  # asdf — brew on macOS, git clone on Linux/WSL (not in apt)
  if [ "$OS" != macos ] && [ ! -d "$HOME/.asdf" ]; then
    echo "==> asdf"
    git clone --depth 1 --branch v0.14.0 https://github.com/asdf-vm/asdf.git "$HOME/.asdf"
  fi

  echo
  echo "Dependencies done. A few steps are still manual:"
  echo "  - Make zsh your login shell:   chsh -s \"\$(command -v zsh)\""
  echo "  - Install language runtimes:   asdf plugin add ruby && asdf plugin add nodejs && asdf install"
  echo "                                 (uses versions from .tool-versions; needs build tools)"
  echo "  - Open vim once so vim-plug installs the plugins."
}

# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

do_deps=
case "${1:-}" in
  --deps)    do_deps=1 ;;
  --help|-h) usage; exit 0 ;;
  "")        ;;
  *)         echo "unknown option: $1" >&2; usage; exit 1 ;;
esac

link_dotfiles
[ -n "$do_deps" ] && install_deps

echo
echo "Done."
[ -z "$do_deps" ] && echo "First time on this machine? run './install.sh --deps' to install external tools too."
echo "Per-machine secrets/paths go in ~/.shellrc.local (not committed)."
