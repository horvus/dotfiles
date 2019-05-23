#!/usr/bin/fish

function update --description 'apt shortcut'
	sudo apt update -y;
	sudo apt upgrade -y;
	sudo apt autoremove -y;
end
