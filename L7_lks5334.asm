#Larry Schultheis
#Lab 7 - Simon


.data
	stackBeg: 
		.word 0
		
	stackEnd:
	
	cmpSeq: .word 0:5
	max: .word 0
	randNum: .word 0
	dispBaseAddr: .word 0x10040000


	colorNum: .word 1
	

	
	colorTable: 
		.word 0x000000		#black
		
		.word 0xffff00		#yellow
		.word 0x0000ff		#blue
		.word 0x00ff00		#green
		.word 0xff0000		#red
		
		.word 0x00ffff		#cyan
		.word 0xff00ff		#magenta
		
		.word 0xffffff		#white
		
	boxSimp:
		.byte 1, 1, 1
		.byte 17, 1, 2
		.byte 1, 17, 3
		.byte 17, 17, 4
	
	welcome: .asciiz "Welcome to Simon\n"
	winMsg: .asciiz "\nYou win!\n"
	loseMsg: .asciiz "\nYou lose!\n"
	space: .asciiz " "
	newline: .asciiz "\n"
	erase: .asciiz "\n\n\n\n\n\n\n\n\n\n\n"


.text
main:
	#display welcome message
	li $v0, 4
	la $a0, welcome
	syscall	
	

	
	#call init procedure
	#	$a0 = max
	#	$a1 = sequence generated by computer
	#	$a2 = number of elements in sequence array
	la $a0, max
	la $a1, cmpSeq
	li $a2, 5
	jal Init
	
	la $sp, stackEnd

	jal clearDisplay
	
	li $a0, 15
	li $a1, 0
	li $a2, 7
	li $a3, 32
	jal drawVertLine
	
	li $a0, 0
	li $a1, 15
	li $a2, 7
	li $a3, 32
	jal drawHorizLine
	
	#call initRand to setup random number generator
	#no arguments or returns -- default generator ID = 0
	jal initRand

seqLoop:
	#call getRand procedure -- generates one random number
	#	$a0 = generator ID -- defualt 0
	#	$a1 = upper bound of number generation
	#	$a2 = address of variable that holds the generated number
	li $a0, 0
	li $a1, 3
	la $a2, randNum
	jal getRand
	
	#call addToSequence procedure to add generated number to the running sequence
	#	$a0 = address of sequence array
	#	$a1 = address of max variable
	#	$a2 = address of generated random number
	la $a0, cmpSeq
	la $a1, max
	la $a2, randNum
	jal addToSequence
	
	#call increment max procedure 
	#	$a0 = address of max variable
	la $a0, max
	jal incrementMax
	
displayAndCheck:
	#call displaySequence procedure 
	#	$a1 = address of sequence array
	#	$a2 = address of max
	la $a1, cmpSeq
	la $a2, max
	jal displaySequence
	
	
	#call checkInput procedure
	#	$a0 = address of sequence array
	#	$a1 = address of max
	la $a0, cmpSeq
	la $a1, max
	jal checkInput
	
	la $a0, erase
	li $v0, 4
	syscall
	
	#check if max has been reached (default number of rounds: 5
	la $a0, max
	lw $t0, ($a0)
	bltu $t0, 5, seqLoop
	
	#if the max number of rounds has been reached and the player
	#has passed the entire sequence, branch to display win message
	b displayWin
	
displayWin:
	li $v0, 4
	la $a0, winMsg
	syscall			#congrats, you beat a bunch of transistors
	
	#jump to exit
	j exit
	
exit:
	#exit the program
	li $v0, 10
	syscall
	


################################################
#						#
#	Start of Simon procedures		#
#						#
################################################

#Procedure init: initialize game (reset sequence, disolay, 
#and maximum elements in sequence
#Args:  
#	$a0 = address of max variable
#	$a1 = address of sequence array
#	$a2 = number of elements in sequence array 
Init:
	li $t0, 0		#load 0 into $t0
	sw $t0, ($a0)		#dereference $a0 -- max
	
iloop:
	sw $zero, ($a1)		#store 0 into $a1 -- sequence array
	addu $a1, $a1, 4	#increment address location
	subu $a2, $a2, 1	#decrement loop counter 
	bnez $a2, iloop		#loop until all elements are set to 0
	
	#restore registers

	jr $ra
	
#Procedure initRand: set up a random number generator 
#args:
#none

#returns:
#none
#ID of generator default is 0
initRand:
	li $v0, 30		
	syscall			#get system time for seed
	
	move $a1, $a0		#move system time to $a1
	li $a0, 0		#set generator ID to 0
	li $v0, 40
	syscall			#initialize random number generator
#					$a0 = ID = 0
#					$a1 = seed = system time
	li $v0, 0
	li $a0, 0
	li $a1, 0

	jr $ra	
	
	
#Procedure getRand: get a new random number 
#args:
#	$a0 = generator ID
#	$a1 = upper bound of generator
#	$a2 = address of variable to store generated number
getRand:
	li $v0, 42
	syscall			#generate random number
#					$a0 = ID = 0
#					$a1 = upper bound of random number
	addiu $a0, $a0, 1
	sw $a0, ($a2)		#store random number into variable location
	
	#restore registers
	
	jr $ra
	

#Procedure addToSequence: adds the generated number to the sequence
#args:
#	$a0 = address of sequence array
#	$a1 = address of max variable (array counter)
#	$a2 = address of random number to add to sequence
addToSequence:
	lw $a1, ($a1)		#dereference max
	lw $a2, ($a2)		#dereference random number
	
	mulu $a1, $a1, 4	#$a1 holds offset for array location
	addu $a0, $a0, $a1	#increment address location by offset
	
	sw $a2, ($a0)		#store random number in sequence array
	
	#restore registers
	jr $ra


#Procedure incrementMax: increments the max numbers in the sequence
#args:
#	$a0 = address of max variable 

#returns:
#	updated max is stored back into variable

incrementMax:
	lw $t0, ($a0)		#dereference max
	addu $t0, $t0, 1	#increment max
	sw $t0, ($a0)		#store updated max back into max
	
	#restore registers
	li $a0, 0
	li $t0, 0
	jr $ra
	
	
#Procedure convToAddr: converts x, y coordinates to bitmap addresses
#args: 
#	$a0 = x coordinate (0-31)
#	$a1 = y coordinate (0-31)

#returns:
#	memory address --> $v0
convToAddr:
	
	la $v0, dispBaseAddr	#load base address of bitmap
	lw $v0, ($v0)
		
	sll $a0, $a0, 2		#$a0 = Xcoord x 4		
	
	sll $a1, $a1, 8		#$a1 = Ycoord x 4 x 32
	sll $a1, $a1, 2
	
	addu $v0, $v0, $a0	#memory address ($v0) = $a0 + $a1
	addu $v0, $v0, $a1
	
	jr $ra
	
#Procedure getColor: converts a color number to the actual hex number of the color
#args:
#	$a2 = color number (0-7)

#returns:
#	$v1 = hex representation of the color
getColor:
	la $t0, colorTable	#load base address of color table
	sll $a2, $a2, 2		#get offset
	addu $t0, $t0, $a2	#address = base + offset
	
	lw $v1, 0($t0)		#load color into $v1
	
	jr $ra
	
#Procedure drawDot: draws a dot on the display given x, y coordinates and color number
#args: 
#	$a0 = x coord (0-31)
#	$a1 = y coord (0-31)
#	$a2 = color number (0-7)

#returns:
#	none
drawDot:
	addiu $sp, $sp, -8	#make room on stack for 2 words
	sw $ra, 0($sp)		#store return address
	sw $a2, 4($sp)		#store color number
	jal convToAddr		#$v0 holds pixel address
	
	lw $a2 4($sp)		#restore $a2
	sw $v0, 4($sp)		#save $v0
	jal getColor		#$v1 has color
	
	lw $v0, 4($sp)		#restore $v0
	sw $v1, 0($v0)		#draw dot
	lw $ra, 0($sp)		#load original return address
	
	addiu $sp, $sp, 8	#adjust $sp
	
	jr $ra
	
#Procedure drawHorizLine: draws a horizontal line on the bitmap display
#args:
#	$a0 = x coord
#	$a1 = y coord
#	$a2 = color number
#	$a3 = length of line

#returns:
#	none
drawHorizLine:
	addiu $sp, $sp, -20	#allocate stack space
	sw $ra, 0($sp)
	
	
HorizLoop:
	sw $a0, 4($sp)		#save registers
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $a3, 16($sp)
	jal drawDot
	
	lw $a0, 4($sp)		#restore registers
	lw $a1, 8($sp)
	lw $a2, 12($sp)
	lw $a3, 16($sp)
	
	addiu $a0, $a0, 1	#increment x coord
	addiu $a3, $a3, -1	#decrement length
	
	bnez $a3, HorizLoop
	lw $ra, 0($sp)
	addiu $sp, $sp, 20
	
	jr $ra

	
#Procdure drawVertLine: draws a vertical line on the bitmap display
#args:
#	$a0 = x coord
#	$a1 = y coord
#	$a2 = color number
#	$a3 = length of line
drawVertLine:
	addiu $sp, $sp, -20
	sw $ra, 0($sp)
	
	
VertLoop:
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $a2, 12($sp)
	sw $a3, 16($sp)
	jal drawDot
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $a2, 12($sp)
	lw $a3, 16($sp)
	
	addiu $a1, $a1, 1
	addiu $a3, $a3, -1
	
	bnez $a3, VertLoop
	lw $ra, 0($sp)
	addiu $sp, $sp, 20
	
	jr $ra
	
#Procedure drawBox: draws a box on the bitmap display
#args:
#	$a0 = x coord
#	$a1 = y coord
#	$a2 = color number 
#	$a3 = size of box (1-32)
drawBox:
	addiu $sp, $sp, -24
	sw $ra, 0($sp)
	addu $t0, $zero, $a3
	
	

boxLoop:
	sw $t0, 4($sp)
	sw $a0, 8($sp)
	sw $a1, 12($sp)
	sw $a2, 16($sp)
	sw $a3, 20($sp)		#save registers
	jal drawHorizLine
	
	lw $t0, 4($sp)		#restore registers
	lw $a0, 8($sp)
	lw $a1, 12($sp)
	lw $a2, 16($sp)
	lw $a3, 20($sp)	
	
	addiu $a1, $a1, 1	#increment y coord
	addiu $t0, $t0, -1	#decrement size
	
	bnez $t0, boxLoop
	
	lw $ra, 0($sp)
	
	addiu $sp, $sp, 24
	jr $ra
	
		
#Procedure clearDisplay: draws a black box over the entire display
#args:
#	none

#returns:
#	none
clearDisplay:
	addiu $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 32
	
	jal drawBox
	
	lw $ra, 0($sp)
	addiu $sp, $sp, 4
	
	jr $ra

#Procedure displaySequence: displays the sequence generated by the computer
#args:
#	$a1 = address of sequence
#	$a2 = address of max
displaySequence:
	la $t7, cmpSeq
	lw $a2, ($a2)		#dereference max
	addiu $sp, $sp, -12
	sw $ra, 0($sp)

dispLoop:
	lw $a0, ($t7)		#dereference current element in sequence array
	sw $a0, 4($sp)		#save registers
	sw $a2, 8($sp)
	
	
	
	beq $a0, 1, yellow
	beq $a0, 2, blue
	beq $a0, 3, green
	beq $a0, 4, red
	
yellow:
	li $a0, 3
	li $a1, 3
	li $a2, 1
	j draw

blue:
	li $a0, 17
	li $a1, 3
	li $a2, 2
	j draw

green:
	li $a0, 3
	li $a1, 17
	li $a2, 3
	j draw

red:
	li $a0, 17
	li $a1, 17
	li $a2, 4
	j draw
	
draw:
	addiu $sp, $sp, -8
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	
	li $a3, 8
	jal drawBox

	jal pause
	
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	li $a2, 0
	li $a3, 8
	
	addiu $sp, $sp, 8
	
	jal drawBox
	
	jal pause

	lw $a1, 4($sp)		#restore registers
	lw $a2, 8($sp)


	
	
	addu $t7, $t7, 4	#increment address counter
	subu $a2, $a2, 1	#decrement max

	
	
	bnez $a2, dispLoop
	lw $ra, 0($sp)
	addiu $sp, $sp, 12
	jr $ra
	
pause:
	li $a0, 1000		#load wait time 
	move $t0, $a0		#copy wait time to $t0
	li $v0, 30		
	syscall			#get system time
	move $t1, $a0		#copy system time to $t1

	
ploop:
	syscall			#get system time
	subu $t2, $a0, $t1	#time elapsed = current time - initial time
	bltu $t2, $t0, ploop	#if current time is less than designated wait time, stay in loop
	
	
	jr $ra



#Procedure checkInput: checks if the user enters the correct sequence 
#args:
#	$a0 = address of sequence 
#	$a1 = address of max
checkInput:
	lw $a1, ($a1)		#dereference max
	
chkLoop:
	li $v0, 12
	syscall			#read in character
	addu $v0, $v0, -48	#convert to decimal (binary)
	
	lw $t0, ($a0)			#dreference array element 
	bne $t0, $v0, checkFail		#if input character is not equal to the corresponding sequence you lose
	addu $a0, $a0, 4		#increment array counter
	
	subu $a1, $a1, 1		#decrement max
	bnez $a1, chkLoop		#if max is not equal to 0, keep checking
	b chkDone			#congrats you haven't lost (yet)
	
checkFail:
	la $a0, loseMsg			
	li $v0, 4
	syscall				#loser
	j exit
	
	
chkDone:
	la $a0, newline			
	li $v0, 4
	syscall				#keep the console clean
	
	#restore registers
	li $a0, 0
	li $a1, 0
	li $t0, 0
	li $v0, 0
	jr $ra
