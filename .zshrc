# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export VISUAL=vim
export EDITOR="$VISUAL"

export NPM_TOKEN='40BZN2CoWxb7N4i5+K1ddidXtXMfedYlwKCT1dINmCg='
export GITHUB_NPM_TOKEN='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'
export AUTH="-e --canonical-username qi0kk80jaxzgp75280d08738y --userid 64126292a8654a91960b368acbf901e7"

# Path to your oh-my-zsh installation.
export ZSH=/Users/lucass/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  bundler
  dotenv
  osx
  rake
  rbenv
  ruby
  tmux 
  tmuxinator
  zsh-nvm 
  terraform
)

source $ZSH/oh-my-zsh.sh

# User configuration

source ~/.bin/tmuxinator.zsh

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# --files: List files that would be searched but do not search
# --no-ignore: Do not respect .gitignore, etc...
# --hidden: Search hidden files and folders
# --follow: Follow symlinks
# --glob: Additional conditions for search (in this case ignore everything in the .git/ folder)
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias current-branch='git rev-parse --abbrev-ref HEAD'
alias changed-files='git diff HEAD --name-only | grep "$(basename "$PWD")/"'
alias make-pr='git push -u origin $(current-branch)'
alias tunnelDb='ssh -fN santoro@bastion.anchor.fm -L 3307:anchor-test.cchuwmjycz8t.us-east-1.rds.amazonaws.com:3306 -L 3308:anchor-test-replica.cchuwmjycz8t.us-east-1.rds.amazonaws.com:3306 -L 3309:anchor-test-replica-episodeplay.cchuwmjycz8t.us-east-1.rds.amazonaws.com:3306  -L 3310:anchor-qa.cchuwmjycz8t.us-east-1.rds.amazonaws.com:3306 -L 3311:rollup-production.cchuwmjycz8t.us-east-1.rds.amazonaws.com:3306 -L 3314:anchor-development.cchuwmjycz8t.us-east-1.rds.amazonaws.com:3306'
alias web1='npm run dev:client'
alias web2='npm run dev:ssr'
alias web3='npm run dev:server:local'
alias web3development='MYSQL_SECRET_NAME=local npm run dev:server:development'
alias tf=terraform
alias k=kubectl
alias kgp="k get pods"

duration-of() {
  if [ -n "$1" ]
  then
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1"
  else
    echo 'Gimme a file ya dingus'
  fi
}

pretty-duration-of() {
  if [ -n "$1" ]
  then
    convertsecs $(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1")
  else
    echo 'Gimme a file ya dingus'
  fi
}

cylog() {
  if [ $# -eq 1 ]
  then
    kubectl logs -n fission-function $1 cypress
  else
    echo 'Need a pod name and context, example: poolmgr-cypress-default-** cypress'
  fi
}

cyshell() {
  if [ $# -eq 1 ]
  then
    kubectl exec -it -n fission-function $1 --container cypress -- sh
  else
    echo 'Need a pod name and context, example: poolmgr-cypress-default-** cypress'
  fi
}

cycaps() {
  if [ $# -eq 1 ]
  then
    kubectl cp $1:/userfunc/deployarchive/cypress/screenshots/ ~/CypressRunner/screenshots
  else
    echo 'Need a pod name and context, example: poolmgr-cypress-default-** cypress'
  fi
}

convertsecs() {
  h=$(bc <<< "${1}/3600")
  m=$(bc <<< "(${1}%3600)/60")
  s=$(bc <<< "${1}%60")
  printf "%02d:%02d:%05.2f\n" $h $m $s
}

freshLocalDbOld() {
  docker stop mysql
  docker rm mysql
  $(aws ecr get-login --no-include-email --region us-east-1)
  docker pull 523887678637.dkr.ecr.us-east-1.amazonaws.com/mysql-anchortest:latest
  docker run -d -p 3306:3306 --name mysql --network anchor 523887678637.dkr.ecr.us-east-1.amazonaws.com/mysql-anchortest:latest
}

freshLocalDb() {
  pushd ~/src/dev
  docker-compose stop mysql
  docker-compose rm -f mysql
  docker-compose stop redis
  docker-compose rm -f redis
  docker-compose pull mysql
  docker-compose pull redis 
  docker-compose up -d
  popd
}

function tf_prompt_info_custom() {
    # dont show 'default' workspace in home dir
    [[ "$PWD" == ~ ]] && return
    # check if in terraform dir
    if [ -d .terraform ]; then
      workspace=$(terraform workspace show 2> /dev/null) || return
      echo "%{$fg_bold[green]%}tf:(%{$fg[yellow]%}${workspace}%{$fg[green]%})%{$reset_color%}"
    fi
}




[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(rbenv init -)"
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
eval "$(nodenv init -)"

# Created by `userpath` on 2021-07-12 14:18:16
export PATH="$PATH:/Users/lucass/.local/bin"
