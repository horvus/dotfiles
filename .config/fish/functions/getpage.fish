#!/usr/bin/env fish

function getpage --description "Download a local copy of a webpage domain from the internet"
	wget -xrpk $argv
end
