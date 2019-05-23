#!/usr/bin/fish

function l --description 'Quick listing of directory contents and their file type'
	ls --group-directories-first -aF $argv
end
