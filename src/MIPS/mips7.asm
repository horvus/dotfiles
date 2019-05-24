# CEN 333 Spring 2019 Tue Feb 19 2019
# Class Exercise - Practice Worksheet
# Question 1

###############################################################
.data
	enter_string:	.asciiz "\nEnter two integers: "
	return_string:	.asciiz "\nThe smallest integer is: "
.text
###############################################################
#	--- Main Function ---
main:
	# PROMPT USER
	li $v0, 4
	la $a0, enter_string
	syscall

	# READ two integers from USER
	# STORE them in $t0 and $t1
	li $v0, 5
	syscall
	move $t0, $v0	# int 1
	
	li $v0, 5
	syscall
	move $t1, $v0	# int 2

	# Place them as arguments in $a0 and $a1
	move $a0, $t0
	move $a1, $t1
	
	# Function Call
	jal Minimum
	
	# DISPLAY returned value:
	# display string
	li $v0, 4
	la $a0, return_string
	syscall
	# display number
	li $v0, 1
	move $a0, $s0
	syscall
	j programEnd
###############################################################
#	--- Minimum Function ---
Minimum:
	move $s0, $a0
	bge $a1, $a0, endIf
		move $s0, $a1
	endIf:
	jr $ra
###############################################################

programEnd:
