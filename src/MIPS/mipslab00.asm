# CEN 333 Spring 2019 Wed Feb 13 2019
# Lab
# Additional Challenge

###############################################################
.data
	enter_string:	.asciiz "\nEnter array elements: "
	read_string:	.asciiz "\nNumber is: "
	average_string: .asciiz "\nAverage number is: "
.text
###############################################################
#	---Part 1: Create array---

# INITIALIZE $t0 as the address and SET $t1 as the loop counter
add $s0, $zero, $sp	# Original address is saved in $s0
add $t0, $zero, $s0
addi $t1, $zero, 1

# 	CREATE ARRAY
loop1:
bgt $t1, 3, exit1
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
addi $t1, $zero, 1
add $t0, $zero, $s0
###############################################################
#	---Part 2: Print the average---

loop2:
bgt $t1, 3, exit2
# LOAD WORD FROM MEMORY and CONVERT to floating point number
# switch statement
bne $t0, $s0, elseif
	l.s $f1, ($t0)
elseif:
addi $s1, $s0, 4
bne $t0, $s1, elseif2
	l.s $f2, ($t0)
	j continue
elseif2:
addi $s1, $s0, 8
bne $t0, $s1, elseif3
	l.s $f3, ($t0)
	j continue
elseif3:
addi $s1, $s0, 12
bne $t0, $s1, elseif4
	l.s $f4, ($t0)
	j continue
elseif4:
addi $s1, $s0, 16
bne $t0, $s1, elseif5
	l.s $f5, ($t0)
	j continue
elseif5:
addi $s1, $s0, 20
bne $t0, $s1, elseif6
	l.s $f6, ($t0)
	j continue
elseif6:
addi $s1, $s0, 24
bne $t0, $s1, elseif7
	l.s $f7, ($t0)
	j continue
elseif7:
addi $s1, $s0, 28
bne $t0, $s1, elseif8
	l.s $f8, ($t0)
	j continue
elseif8:
addi $s1, $s0, 32
bne $t0, $s1, else
	l.s $f9, ($t0)
	j continue
else:
addi $s1, $s0, 36
bne $t0, $s1, fail
	l.s $f10, ($t0)
continue:
# INCREMENT $t0 and REPEAT
addi $t0, $t0, 4
addi $t1, $t1, 1
j loop2
exit2:
# ADD, DIVIDE and PRINT OUT AVERAGE
add.s  $f1, $f1, $f2	# f1 + f2
add.s $f2, $f3, $f4	# f3 + f4
add.s $f3, $f5, $f6	# f5 + f6
add.s $f4, $f7, $f8	# f7 + f8
add.s $f5, $f9, $f10	# f9 + f10

add.s $f1, $f1, $f2	# f1+f2 + f3+f4
add.s $f2, $f3, $f4	# f5+f6 + f7+f8
add.s $f3, $f2, $f5	# f5+f6+f7+f8 + f9+f10

add.s $f0, $f1, $f3	# f1+f2+f3+f4 + f5+f6+f7+f8+f9+f10 = all f*

# convert number of array elements into floating point value
sw $t1, ($s2)
l.s $f12, ($s2)

div.s  $f0, $f0, $f12	# divide sum by number of array elements
li $v0, 4
la $a0, average_string
syscall
li $v0, 2
add.s $f12, $f0, $f31	# print out result
syscall

# Error
fail:
