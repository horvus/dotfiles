# CEN 333 Spring 2019 Fri Feb 15 2019
# Homework 3

# Data Memory Block
.data
	array_size_string: .asciiz "\nEnter Array Size: "
	enter_num_string: .asciiz "\nEnter Number: "
	array_msg_string: .asciiz "\nPrinting Array Contents: "

# Text (Code) Segment
.text

#---------------------------
# Read Array Size From User
#---------------------------
# Print "Enter Array Size: "
li $v0, 4
la $a0, array_size_string
syscall

# Get integer from user
li $v0, 5
syscall 
move $t0, $v0  #t0 is array size

#---------------------------
#LOOP FOR ENTERING ARRAY INTO MEMORY 
#---------------------------
# for(t1=0; t1 < t0; t1++)
add $t1, $zero, $zero 
add $s0, $gp, $zero  #gp is the base memory address
Loop1:
bge $t1, $t0, exitLoop1

	# Print "Enter Number: "
	li $v0, 4
	la $a0, enter_num_string
	syscall

	# Get integer from user
	li $v0, 5
	syscall 
	move $t3, $v0  #t3 is entered number

	
	sw $t3, 0($s0)   # Store $t3 in memory
	addi $s0, $s0, 4 # Advance memory address to next word

	addi $t1, $t1, 1  #i++
	j Loop1
exitLoop1:

# -------------- YOUR CODE HERE: BUBBLE SORT  -----------------
# n is $t0, i is $t1
# all newly invoked registers in this section were sortof invoked in reverse (i.e: $t9, $t8, etc..)
# for (t1=0; t1 < t0-1; t1++)
add $t1, $zero, $zero	# reset t1
subi $t9, $t0, 1	# $t9 = t0-1
add $s0, $gp, $zero	# gp is the base memory address 
outerLoop:
bge $t1, $t9, outerLoop
	
	innerLoop:
	# for (t7=0; t7 < t9-t1; j++)
	add $t7, $zero, $zero	# $t7 is j
	sub $t8, $t9, $t1	# $t8 = (t0-1)-t1
	bge $t7, $t8, innerLoop
		
		lw $t6, 0($s0)	# load two succcessive elements into unused registers
		lw $t4, 4($s0)
		# if (t6 > t4)
		ble $t6, $t4, doNothing
		
			# swap t6 and t4 back into memory
			sw $t4, 0($s0)
			sw $t6, 4($s0)
		
		doNothing:
		addi $s0, $s0, 4	# Advance memory address to next word	
	addi $t7, $t7, 1	# j++
	j innerLoop
			
addi $t1, $t1, 1  # i++
j outerLoop

# -------------- END OF YOUR CODE: BUBBLE SORT  -----------------

# Prints "Displaying Array Contents: "
li $v0, 4
la $a0, array_msg_string
syscall

#---------------------------
#LOOP FOR PRINTING ARRAY FROM MEMORY 
#---------------------------
add $t1, $zero, $zero
add $s0, $gp, $zero #gp is the base memory address 
# for(t1=0; t1 < t0; t1++)
printLoop:
bge $t1, $t0, exitPrintLoop

	lw $t5, 0($s0)    # Get A[i] from memory
	addi $s0, $s0, 4  # Advance memory address to next word
	
	#print A[i]
	addi $v0, $zero, 1
	add $a0, $zero, $t5
	syscall
	
	add $t1, $t1, 1 #i++
	j printLoop
exitPrintLoop:
