#!/usr/bin/env fish

# Shortcuts for quick navigation
################################
	abbr q "exit"
	abbr t "tmux"
	abbr v "$EDITOR"
	abbr e "echo"
	abbr u "update"
	abbr py "python"
	abbr i "sudo apt install"
	abbr s "sudo apt search"
	abbr ss "sudo apt show"
	abbr ar "sudo apt autoremove"
	abbr af "apt-file search"
	abbr afs "apt-file show"
	abbr ppa "sudo add-apt-repository"
	abbr d "cd /home/horvus/Downloads"
	abbr b "cd /home/horvus/Books"
	abbr p "cd /home/horvus/Pictures"
	abbr gu "cd ~/Desktop/"
	abbr sc "cd /home/horvus/src/"
	abbr sr "cd /home/horvus/.local/bin/"
	abbr cf "cd /home/horvus/.config/fish/"
	abbr cff "cd /home/horvus/.config/fish/functions/"
	abbr cr "cd ~/.config/ranger/"
	abbr ci "cd ~/.config/i3/"
	abbr cn "cd ~/.config/nvim/"
	abbr ni "nvim ~/.config/i3/config"
	abbr nb "nvim ~/.config/i3blocks/config"
	abbr nv "nvim ~/.config/nvim/init.vim"
	abbr nf "nvim ~/.config/fish/config.fish"
	abbr nt "nvim ~/.tmux.conf"


# Startup calls
########################
	# Setup color scheme
	# unneeded since moved to st
	# theme_gruvbox dark hard
	# Import colorscheme from 'wal' asynchronously
	# &   # Run the process in the background.
	# ( ) # Hide shell job control messages.
	# (cat ~/.cache/wal/sequences &)
	~/.cache/wal/colors-tty.sh


# Enable color output for pager (man, less, etc)
# Only works with man for now
#############################
	set -xU LESS_TERMCAP_md (printf "\e[01;31m")
	set -xU LESS_TERMCAP_me (printf "\e[0m")
	set -xU LESS_TERMCAP_se (printf "\e[0m")
	set -xU LESS_TERMCAP_so (printf "\e[01;44;33m")
	set -xU LESS_TERMCAP_ue (printf "\e[0m")
	set -xU LESS_TERMCAP_us (printf "\e[01;32m")
# To complement ~/.lessfilter and python-pygments
	set -xU LESS ' -R '
	set -xU LESSOPEN '| ~/.lessfilter %s'

# Fisher config
########################
if not functions -q fisher
	set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
	curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
	fish -c fisher
end

