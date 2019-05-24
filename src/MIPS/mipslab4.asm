# CEN 333 Spring 2019 Wed Feb 20 2019
# Lab 4

###############################################################
.data
	array_siz: .asciiz "Enter Array Size: "
	enter_num: .asciiz "Enter Num: "
.text
###############################################################
main:
	# Display "Enter Array Size: "
	li $v0, 4
	la $a0, array_siz
	syscall
	
	# Get Array Size and Store in $s0
	li $v0, 5
	syscall
	move $s0, $v0	# Array Size 
	
	move $t0, $gp	#$t0 is base address
	li $t1, 0	# i = 0
	start: bge $t1, $s0, end
		
		# Display "Enter Num: "
		li $v0, 4
		la $a0, enter_num
		syscall
		
		# Get Num and Store in Memory
		li $v0, 5
		syscall							
		sw $v0, 0($t0)
		
		addi $t0, $t0, 4  # Advance Address to Next Word
		addi $t1, $t1, 1  # i++
		j start
	end:
	
	move $a0, $gp	# 1st Parameter is the base address
	move $a1, $s0	# 2nd Parameter is array size
	
	jal avg
	# Print Average
	move $a0, $v0
	li $v0, 1
	syscall
	
	jal stddev	# Uncomment for Challenge problem 
	# Print Standard Deviation
	move $a0, $v0
	li $v0, 1
	syscall
	
j exit
###############################################################
avg: 	
	li $t0, 0	# i = 0
	lw $t1, 0($a0)	# load first element before loop to avoid doubles
	li $t2, 0
	beginLoop: bge $t0, $a1, endLoop
		
		lw $t2, 4($a0)		# only increment address of second element of addition
		add $t1, $t1, $t2	
		
		addi $t0, $t0, 1	# i++
		addi $a0, $a0, 4	# advance address to next word
		j beginLoop
	endLoop:
	
	# $v0 is the average
	div $v0, $t1, $a1
	jr $ra

# Square Root Function: sqrt(n), calculates the square root of n
# NEEDED FOR THE EXTRA CHALLENGE PROBLEM.  IGNORE THIS UNTIL
# YOU ARE DONE WITH THE CORE PROBLEM
sqrt:
	move $t0, $a0 # x = n
	srl $t2, $a0, 1 # t2 = n / 2
	
	li $t1, 0  # i = 0
	startLoop: bge $t1, $t2, exitLoop
		
		div $t4, $a0, $t0  # (n / x)
		add $t4, $t0, $t4  # x + (n / x)
		srl $t0, $t4, 1    # x = (x + (n / x) ) / 2
	
		addi $t1, $t1, 1  # i++
		j startLoop
	exitLoop:
	
	move $v0, $t0
	jr $ra
	
# Standard Deviation Function
stddev:
	move $t0, $a0
	move $t1, $a1
	addi $t3, $t1, -1	# $t3 = n-1
	
	li $t2, 0		# i = 0
	lw $t4, 0($t0)		# $t4 = x
	s: bge $t2, $t1, e
		
		jal avg		
		move $t5, $v0		# $t5 = X
		sub $t6, $t4, $t5	# $t6 = x - X
		
		
		addi $t0, $t0, 4
		addi $t2, $t2, 1
		j s
	e:
	
	jr $ra
###############################################################
exit:
