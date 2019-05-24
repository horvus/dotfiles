add $t0, $t0, $t1	# t0 = t0 + t1
add $t0, $t0, $t2	# t0 = t0 + t2 == (t0+t1) + t2
sub $t2, $t2, $t3	# t2 = t2 - t3
sub $t0, $t0, $t2	# t0 = t0 - t2 == (t0+t1+t2) - (t2-t3)
sll $s0, $t0, 1 	# multiplies by 2
