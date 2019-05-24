# Spring 2019 CEN333 Lab 2 Wed Feb 6 2019
# Additional challenge

# Generate random number from 0 to 100 ($a1)
# Store it in $s0 
addi $v0, $zero, 42	# 42 is system call for random integer
addi $a1, $zero, 100
syscall
add $s0, $a0, $zero

repeat:
# Read $t0 from user
addi $v0, $zero, 5
syscall
add $t0, $v0, $zero

beq $t0, $s0, end	# if $t0 != $s0

ble $t0, $s0, else	# if $t0 > $s0
# Print "H" for too high
addi $a0, $zero, 72
addi $v0, $zero, 11
syscall
j repeat

else:
# Print "L" for too low
addi $a0, $zero, 76
addi $v0, $zero, 11
syscall
j repeat

end:
# Print "C" for correct
addi $a0, $zero, 67	# 67 is ASCII character for "C"
addi $v0, $zero, 11	# 11 is system call for character conversion
syscall
