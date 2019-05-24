# Spring 2019 CEN333 Lab 2 Wed Feb 6 2019
# Core problem 2

# read $t0 from user
addi $v0, $zero, 5
syscall
add $t0, $zero, $v0

# read $t1 from user
addi $v0, $zero, 5
syscall
add $t1, $zero, $v0

ble $t0, $t1, else	# if $t0 > $t1
# print $t0
addi $v0, $zero, 1
add $a0, $t0, $zero
syscall
j end

else:
# print $t1
addi $v0, $zero, 1
add $a0, $t1, $zero
syscall
end:
