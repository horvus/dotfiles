# Spring 2019 CEN333 Thu Feb 7 2019
# Bonus question

###############################################################
# Data segment
	.data
prompt: .asciiz "Enter number of rows: "
# Text segment (instructions begin)
	.text 
###############################################################

# Prompt user to enter the number of rows
li $v0, 4	# 4 is system call to print string
la $a0, prompt
syscall

# Take input from user, store in $s0
li $v0, 5
syscall
add $s0, $zero, $v0

# Initialize $t0
addi $t0, $zero, 1
# for($t0 = 1; $t0 <= $s0; $t1++) 
Loop1:	bgt $t0, $s0, ExitLoop1
	# Initialize $t1
	addi $t1, $zero, 1
	# for($t2 = 1, $t2 <= $t1, $t2++)
	Loop2:	bgt $t1, $t0, ExitLoop2
		# Print "*"
		li $v0, 11
		la $a0, 42
		syscall
		# Increment $t1
		addi $t1, $t1, 1
		j Loop2
	ExitLoop2:
	# Print newline
	addi $a0, $zero, 10
	addi $v0, $zero, 11
	syscall
	# Increment $t0
	addi $t0, $t0, 1
	j Loop1
ExitLoop1:
