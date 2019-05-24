add $t1, $zero, $zero	# initializes register $t1 by setting $t1 = 0 + 0
add $t1, $t1, 1		# Adds 1 to $t1 by setting $t1 = $t1 + 1
add $t2, $zero, $zero
add $t2, $t2, 1
# START LOOP
Loop1:
add $t3, $t1, $t2
add $t1, $t1, $t2
add $t2, $t2, $t3
ble $t3, 20, Loop1
#END LOOP
