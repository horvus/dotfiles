#!/bin/sh
tr ' ' '\012' | \
sed ' {
	y/abcdef/ABCDEF/
	N
	s/\n/ /
}'

