#!/usr/bin/fish

function fritzing --description 'Launch Fritzing'
	nohup ~/Downloads/fritzing-0.9.3b.linux.AMD64/Fritzing &
	disown
end
