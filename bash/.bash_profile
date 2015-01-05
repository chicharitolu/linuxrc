#term
PS1='\u@\h \w$'

#env
ENV_LOCAL=$HOME/chicharitolu/local
PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
export GOROOT=$ENV_LOCAL/go1.4
export PATH=$GOROOT/bin:$ENV_LOCAL/bin:$PATH
export CLICOLOR=1 
export COPYFILE_DISABLE=1

##alias
alias ls='/bin/ls -G'
alias ll='/bin/ls -alhG'
alias grep='/usr/bin/grep --color'
alias em='emacs'
