# Author: Adrian Jêdrych
# Elipse drawing in BMP file

.eqv HDR_SIZE	54
.eqv BM_WIDTH 	18
.eqv BM_HEIGHT 	22
.eqv IMG_SIZE	34

.eqv CX	 	0 	# center point x
.eqv CY		4	# center point y
.eqv XRadius	8
.eqv YRadius	12

	.data
	.align 2
align:	.space 2
header: .space HDR_SIZE

input:	.space 16
fname: 	.asciz "test.bmp"
#fname: 	.space 100

askfname: .asciz "Enter file name: \n"
askCX:	  .asciz "Enter X of ellipse center: "
askCY:	  .asciz "Enter Y of ellipse center: "
askXR:	  .asciz "Enter X radius: "
askYR:	  .asciz "Enter Y radius: "
infotxt:  .asciz "Program is running\n"
errormsg: .asciz "Error opening file"


	.text
main:
#----------INPUT------------#
	la t0, input
	
#	# Read file name
#	li a7, 4
#	la a0, askfname
#	ecall
#	li a7, 8
#	la a0, fname
#	li a1, 100
#	ecall
#
#	# remove \n from string
#	la t0, fname
#	li t1, '\n'
#loop:
#	lb t3, (t0)
#	beq t3, t1, rem
#	addi t0, t0, 1
#	j loop
#rem:
#	sb zero, (t0)
	
	# Read CX
	li a7, 4
	la a0, askCX
	ecall
	li a7, 5
	ecall
	sw a0, CX(t0)
	
	# Read CY
	li a7, 4
	la a0, askCY
	ecall
	li a7, 5
	ecall
	sw a0, CY(t0)
	
	# Read XRadius
	li a7, 4
	la a0, askXR
	ecall
	li a7, 5
	ecall
	sw a0, XRadius(t0)
	
	# Read YRadius
	li a7, 4
	la a0, askYR
	ecall
	li a7, 5
	ecall
	sw a0, YRadius(t0)

	li a7, 4
	la a0, infotxt
	ecall

#----------READ-------------#
	# open file to read
	la a0, fname	# file name
	li a1, 0	# read-only flag
	li a7, 1024	# open file
	ecall
	
	bltz a0, error
	
	# store file handle
	mv t1, a0	
	
	# read file header
	li a7, 63	
	la a1, header
	li a2, HDR_SIZE
	ecall
	
	# allocate memory for image
	li a7, 9
	la t0, header
	lw a0, IMG_SIZE(t0)	# read size from header
	ecall
	
	# store heap memory address
	mv s0, a0
	
	# read image and store in heap
	li a7, 63
	mv a0, t1		# file descriptor
	mv a1, s0		# store in heap
	la t0, header
	lw a2, IMG_SIZE(t0)	# length = img_size
	ecall
	
	# close file
	li a7, 57
	mv a0, t1
	ecall
	
#---------DRAW----------#
	# store width and height
	la t0, header
	lw s2, BM_WIDTH(t0)
	lw s3, BM_HEIGHT(t0)

	# find center pixel offset
	addi t6, zero, 3
	and s4, s2, t6		# Mod width%4
	#t3 = width*h/2 + r*h/2 = h/2(w*3+r)
	srai t3, s3, 1	#h/2
	mul t4, s2, t6	#w*3
	add t4, t4, s4	#w*3+r
	mul s1, t3, t4	#offset = h/2(w*3+r)
	
	srai t3, s2, 1	# offset += (width/2)*3
	mul t3, t3, t6
	add s1, s1, t3
	
	mul t0, s2, t6
	add s4, s4, t0 	# save width*3 + margin for later
	
	la a3, input
	lw a2, CX(a3)
	lw a3, CY(a3)
	
	#Test color center
	#add t6, s0, s1
	#sb zero, (t6)
	#sb zero, 1(t6)
	#sb zero, 2(t6)

firstSetup:
	la t6, input
	
	lw t0, XRadius(t6)
	lw t1, YRadius(t6)
	
	add a0, zero, t0	# X = XRadius
	
	mv a1, zero		# Y = 0
	
	mul s5, t0, t0		# TwoASquare = XRadius*XRadius
	slli s5, s5, 1		# TwoASquare*2
	
	mul s6, t1, t1		# TwoBSquare = YRadius*YRadius
	slli s6, s6, 1		# TwoBSquare*2
	
	slli s7, t0, 1		# XChange = 2*XRadius
	sub s7, zero, s7	# -2*XRadius
	addi s7, s7, 1		# 1-2*XRadius
	mul s7, s7, t1		# YR*(1-2*XR)
	mul s7, s7, t1		# YR*YR*(1-2*XR)
	
	mul s8, t0, t0		# YChange = XR*XR
	
	mv s9, zero		# ElipseError = 0
	
	mul s10, s6, t0		# StoppingX = TwoBSquare*XRadius
	
	mv s11, zero		# StoppingY = 0
	
firstSet:
	blt s10, s11, secondSetup	# do while StoppingX >= StoppingY
	jal plot4Points
	addi a1, a1, 1		# inc Y
	add s11, s11, s5	# inc StoppingY, TwoASquare
	add s9, s9, s8		# inc ElipseError, YChange
	add s8, s8, s5		# inc YChange, TwoASquare
	
	slli t0, s9, 1		# 2*ElipseError
	add t0, t0, s7		# + XChange
	blez t0, firstSet	# if t2 > 0 
	addi a0, a0, -1		# dec X
	sub s10, s10, s6	# dec StoppingX, TwoBSquare
	add s9, s9, s7		# inc EllipseError, XChange
	add s7, s7, s6		# inc XChange, TwoBSquare
	
	j firstSet

secondSetup:
	la t6, input
	
	lw t0, XRadius(t6)
	lw t1, YRadius(t6)

	mv a0, zero		# X = 0
	mv a1, t1		# Y = YR
	mul s7, t1, t1		# XChange = YR*YR
	
	slli s8, t1, 1		# YChange = 2*YR
	sub s8, zero, s8	# -2*YR
	addi s8, s8, 1		# 1-2*YR
	mul s8, s8, t0
	mul s8, s8, t0		# XR*XR*(1-2*YR)
	
	mv s9, zero		# ElipseError = 0
	mv s10, zero		# StoppingX = 0
	mul s11, s5, t1		# StoppingY = TwoASquare*YR

secondSet:
	bgt s10, s11, write	# while StoppingX <= StoppingY do
	jal plot4Points
	addi a0, a0, 1		# inc X
	add s10, s10, s6		# inc StopX, TwoBSquare
	add s9, s9, s7		# inc ElipseError, Xchange
	add s7, s7, s6		# inc XChange, TwoBSquare
	
	slli t0, s9, 1
	add t0, t0, s8
	blez t0, secondSet	# if (2*ElipseError + YChange <= 0) dont decrease
	addi a1, a1, -1		# dec Y
	sub s11, s11, s5		# dec StoppingY, TwoASquare
	add s9, s9, s8		# inc ElipseError, YChange
	add s8, s8, s5		# inc YChange, TwoASquare
	
	j secondSet
	
plot4Points:
	addi sp, sp, -4	#push ra
	sw ra, 4(sp)
	
	# a0 = X
	# a1 = Y
	# a2 = CX
	# a3 = CY
	# s0 = heap memory address
	# s1 = center offset
	# s2 = width
	# s3 = height
	# s4 = margin + width*3
	
	srai t3, s2, 1	# widht/2
	srai t5, s3, 1	# height/2
	
	# 1 point CX+X, CY+Y
	add t0, a0, a2
	add t1, a1, a3
	jal putPixel
	
	# 2 point CX-X, CY+Y
	sub t0, a2, a0
	# Y same as before
	jal putPixel
	
	# 3 point CX-X, CY-Y
	# X same as before
	sub t1, a3, a1
	jal putPixel
	
	# 4 point CX+X, CY-Y
	add t0, a0, a2
	# Y same as before
	jal putPixel
	
jump_back:
	lw ra, 4(sp)		#restore (pop) ra
	addi sp, sp, 4
	jr ra
	
putPixel:
	#skip if X out if image
	add t2, t0, t3
	bltz t2, putPixelRet
	bgt t2, s2, putPixelRet
	
	#skip if Y out of image
	add t4, t1, t5
	bltz t4, putPixelRet
	bgt t4, s3, putPixelRet
	
	addi t6, zero, 3
	mul t6, t6, t0		# X*3
	
	mul t2, t1, s4		# Y*(margin+width*3) aka how many lines to skip to get appropriate Y
	add t4, t6, t2		# sum up heapAddr+centerOffset+X+Y
	add t4, t4, s1
	add t4, t4, s0
	sb zero, (t4)
	sb zero, 1(t4)
	sb zero, 2(t4)
putPixelRet:
	jr ra

#---------WRITE---------#
write:
	# write to file
	li a7, 1024
	la a0, fname	# file name
	li a1, 1	# write-only
	ecall
	
	bltz a0, error
	
	# store file handle
	mv t1, a0
	
	la t0, header
	
	# write header (a0 is already set after ecall)
	li a7, 64
	mv a1, t0		# header address
	addi a2, zero, HDR_SIZE	# length to write
	ecall
	
	# write image
	li a7, 64
	mv a0, t1		# img address
	mv a1, s0		# heap address
	lw a2, IMG_SIZE(t0)	# length to write
	ecall
	
	# close file
	li a7, 57
	mv a0, t1
	ecall
	
	j end
	
error:
	li a7, 4
	la a0, errormsg
	ecall
	
end:
	li a7, 10
	ecall
