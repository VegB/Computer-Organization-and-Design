.data
buffer:        .space 256
msgFound:      .asciiz "\r\nSuccess! Location: "
msgFailed:      .asciiz "\r\nFail!\r\n"
enter:      .asciiz "\r\n"
msgInput:    .asciiz "\r\nPlease input a sentence without a question mark.\r\n"

.text
.globl main
main:
	li $t5, '\r'
	li $t6, '\n'
	li $t7, '?'
	li $v0, 4 # Print String
	la $a0, msgInput
	syscall	

inputString:
	li $v0, 8 # Read String
	la $a0, buffer # where to store the string
	li $a1, 250 # max length
	syscall
	
check: # make sure the inputed string does not contain '?'
	la $t0, buffer
tmploop:
	lb $a0, ($t0) # load a char
	beq $a0, $t7, main # found a '?', then input again
	bne $a0, $t6, tmpcontinue
	j inputChar # has reach the end(\n)
tmpcontinue:
	addi $t0, $t0, 1
	j tmploop
		
inputChar:
	li $v0, 12 # Read Char
	syscall
	beq $v0, $t7, inputend # inputed '?'
	li $a1, 1 # tmp pos, start from 1
	la $t0, buffer
	
findLoop:
	lb $a0, ($t0) # load a char
	beq $a0, $v0, found
	bne $a0, $t6, continue
	j failed # has reach the end(\n)
continue:
	addi $t0, $t0, 1
	addi $a1, $a1, 1
	j findLoop
	
found:
	li $v0, 4 # Print String
	la $a0, msgFound
	syscall
	li $v0, 1 # Print Int
	move $a0, $a1
	syscall
	li $v0, 4 # Print String
	la $a0, enter
	syscall
	j inputChar
	
failed:	
	li $v0, 4 # Print String
	la $a0, msgFailed
	syscall
	j inputChar
	
inputend:
	li $v0, 10 # Exit Program
	syscall
	