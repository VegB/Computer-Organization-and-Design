.data
# Uppercase
uA: .asciiz "Alpha"
uB: .asciiz "Bravo "
uC: .asciiz "Charlie "
uD: .asciiz "Delta "
uE: .asciiz "Echo "
uF: .asciiz "Foxtrot "
uG: .asciiz "Golf "
uH: .asciiz "Hotel "
uI: .asciiz "India "
uJ: .asciiz "Juliet "
uK: .asciiz "Kilo "
uL: .asciiz "Lima "
uM: .asciiz "Mike "
uN: .asciiz "November "
uO: .asciiz "Oscar "
uP: .asciiz "Papa "
uQ: .asciiz "Quebec "
uR: .asciiz "Romeo "
uS: .asciiz "Sierra "
uT: .asciiz "Tango "
uU: .asciiz "Uniform "
uV: .asciiz "Victor "
uW: .asciiz "Whisky "
uX: .asciiz "X-ray "
uY: .asciiz "Yankee "
uZ: .asciiz "Zulu "
# Lowercase
a: .asciiz "alpha"
b_: .asciiz "bravo "
c: .asciiz "charlie "
d: .asciiz "delta "
e: .asciiz "echo "
f: .asciiz "foxtrot "
g: .asciiz "golf "
h: .asciiz "hotel "
i: .asciiz "india "
j_: .asciiz "juliet "
k: .asciiz "kilo "
l: .asciiz "lima "
m: .asciiz "mike "
n: .asciiz "november "
o: .asciiz "oscar "
p: .asciiz "papa "
q: .asciiz "quebec "
r: .asciiz "romeo "
s: .asciiz "sierra "
t: .asciiz "tango "
u: .asciiz "uniform "
v: .asciiz "victor "
w: .asciiz "whisky "
x: .asciiz "x-ray "
y: .asciiz "yankee "
z: .asciiz "zulu "
# Numbers
zero:   .asciiz "zero "
one:    .asciiz "one "
two:    .asciiz "two "
three:  .asciiz "three "
four:   .asciiz "four "
five:   .asciiz "five "
six:    .asciiz "six "
seven:  .asciiz "seven "
eight:  .asciiz "eight "
nine:   .asciiz "nine "
star:   .asciiz "* "

alphaUpper: .word uA, uB, uC, uD, uE, uF, uG, uH, uI, uJ, uK, uL, uM, uN, uO, uP, uQ, uR, uS, uT, uU, uV, uW, uX, uY, uZ
alphaLower: .word a, b_, c, d, e, f, g, h, i, j_, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
num:     .word zero, one, two, three, four, five, six, seven, eight, nine

.text
.globl main

main:
	li $t0, 'a'
	li $t1, 'z'
	li $t2, 'A'
	li $t3, 'Z'
	li $t4, '0'
	li $t5, '9'
	li $t6, '?'

input:
	li $v0, 12 # Read Char, $a0 = character read
	syscall
	move $a0, $v0
	
compare:
	beq $a0, $t6, inputend # inputed '?'

number: # numbers?
	sle $t7, $a0, $t5 # inputed char <='9'?
	beq $t7, $zero, upper
	sge $t7, $a0, $t4 # inputed char >='0'?
	bne $t7, $zero, displayNum

upper: # uppercases?
	sle $t7, $a0, $t3 # inputed char <='Z'?
	beq $t7, $zero, lower
	sge $t7, $a0, $t2 # inputed char <='A'?
	bne $t7, $zero, displayUpper

lower: # lowercases?
	sle $t7, $a0, $t1  # inputed char <='z'?
	beq $t7, $zero, others
	sge $t7, $a0, $t0 # inputed char >= 'a'?
	bne $t7, $zero, displayLower

others: # other char -> display star
	la $a0, star
	li $v0, 4
	syscall
	j input
	
displayNum:
	move $v0, $a0
	sub $v0, $v0, $t4 # v0 -= '0'
	sll $v0, $v0, 2 # v0 *= 4
	la $a1, num
	j display
	
displayUpper:
	move $v0, $a0
	sub $v0, $v0, $t2 # v0 -= 'A'
	sll $v0, $v0, 2 # v0 *= 4
	la $a1, alphaUpper
	j display
		
displayLower:
	move $v0, $a0
	sub $v0, $v0, $t0 # v0 -= 'a'
	sll $v0, $v0, 2 # v0 *= 4
	la $a1, alphaLower
	j display
	
display:
	add $a1, $a1, $v0
	lw $a0, ($a1) # (if it's a lowercase char) alphaLower[inputed char - 'a'], also a 'tag'
	li $v0, 4 # Print String, $a0 = address of null-terminated string
	syscall
	j input

inputend:
	li $v0, 10 # Exit Program
	syscall