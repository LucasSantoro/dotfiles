[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
alias current-branch='git rev-parse --abbrev-ref HEAD'
alias changed-files='git diff HEAD --name-only | grep "$(basename "$PWD")/"'
alias changed-specs='changed-files | grep "_spec.rb$"'
alias changed-ruby='changed-files | grep ".rb$"'
alias make-pr='git push -u origin $(current-branch)'
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
alias be='bundle exec'

alias veep="osascript ~/AppleScripts/autopush.applescript"

rebass () {
  CURRENT=$(current-branch)
  git checkout $1
  git pull
  git checkout $CURRENT
  git rebase $1
}

specs-with () {
  FILES=$(find . -name "*$1*spec.rb" | tr "\n" " ")
  echo $FILES
  if [ -n "$FILES" ]
  then
    bundle exec rspec -- "$FILES"
  else
    echo "No test files found containing '$1'"
  fi
}

iterm2_print_user_vars() {
  iterm2_set_user_var gitBranch $((git branch 2> /dev/null) | grep \* | cut -c3-)
}

it_just_works() {
  sudo kextunload /System/Library/Extensions/AppleHDA.kext
  sudo kextload /System/Library/Extensions/AppleHDA.kext
}
