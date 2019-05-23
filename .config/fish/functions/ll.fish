#!/usr/bin/fish

function ll --description 'Quick listing of directory contents and their file type'
	ls --group-directories-first -lahGF $argv
end
