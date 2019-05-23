#!/usr/bin/fish

function r --description 'Launch ranger'
	ranger --choosedir="/tmp/.rangerdir"; cd (cat /tmp/.rangerdir); rm /tmp/.rangerdir;
end
