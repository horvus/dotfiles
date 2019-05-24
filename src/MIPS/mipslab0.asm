# CEN 333 Spring 2019 Wed Feb 13 2019
# Lab
# Core Problem

###############################################################
.data
	enter_string:	.asciiz "\nEnter array elements: "
	read_string:	.asciiz "\nNumber is: "
.text
###############################################################
#	---Create and display array in reverse---

# INITIALIZE $t0 as the address and SET $t1 as the loop counter
add $s0, $zero, $sp	# Original address is saved in $s0
add $t0, $zero, $s0
addi $t1, $zero, 1

# 	CREATE ARRAY
loop1:
bgt $t1, 10, exit1
# PROMPT the user
li $v0, 4
la $a0, enter_string
syscall
# READ INT FROM USER and STORE IN MEMORY
li $v0, 5
syscall
sw  $v0, ($t0)
# INCREMENT $t0 and REPEAT
addi $t0, $t0, 4
addi $t1, $t1, 1
j loop1
exit1:

#	RESET COUNTERS
subi $t0, $t0, 4	# Decrements address by four one more time to avoid index error
addi $t1, $zero, 1

#	DISPLAY ARRAY IN REVERSE
loop2:
bgt $t1, 10, exit2
# PRESENT result
li $v0, 4
la $a0, read_string
syscall
# LOAD WORD FROM MEMORY and DISPLAY IT
lw $a0, ($t0)
li $v0, 1
syscall
# INCREMENT $t0 and REPEAT
subi $t0, $t0, 4
addi $t1, $t1, 1
j loop2
exit2:
