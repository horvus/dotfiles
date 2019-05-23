#!/usr/bin/fish

function dotfiles --description 'Backup configuration files (dotfiles) using this alias for git'
	/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv

end

