

; posprintf - a condensed version of sprintf for Thumb, esp. GBA
; Written in 2003 by Dan Posluns
; http://www.danposluns.com/gbadev/posprintf/

; Ported to V810 in 2008 by Derek da Silva

; No rights reserved.
; https://creativecommons.org/publicdomain/zero/1.0/


; register map:

; MAIN LOOP:						PROCESS16:
; r6 <- dest string address			r6 <- d0
; r7 <- source string address		r7 <- d1
; r8 <- integer to print			r8 <- d2
; r9 <-								r9 <- d3
; r10 <- current char				r10 <- d4
; r11 <- 							r11 <- work register
; r12 <- 							r12 <- work register
; r13 <- 							r13 <- dest string address
; r14 <- number of digits to print  r14 <- number of digits to print
; r15 <- leading char (' ' or '0')	r15 <- leading char (' ' or '0')
; r16 <- current parameter pointer	r16 <- current parameter ptr
; r17 <-							r17 <-
; r18 <-							r18 <- source string address
; r31 <-							r31 <- lp

; Function parameters:

; r6 <- destination string address
; r7 <- source string address
; r8 <- param1
; r9 <- param2


	isv810
	capsoff
	lprefix ' '
	rsvreg	1
	oncnum
	pubon

text group

_posprintf:

	st.w	r8, 8[sp]
	st.w	r9, 12[sp]
	movea	8, sp, r16				; r16 <- first parameter pointer

	addi	-36, sp, sp				; save clobbered registers
	st.w	r31, 0[sp]
	st.w	r18, 4[sp]
	st.w	r17, 8[sp]
	st.w	r16, 12[sp]
	st.w	r15, 16[sp]
	st.w	r14, 20[sp]
	st.w	r13, 24[sp]
	st.w	r12, 28[sp]
	st.w	r11, 32[sp]

L_STRINGLOOP:
	ld.b	0[r7], r10				; load a char from r7
	add		1, r7					; advance pointer to next char
	movea	'%', r0, r12
	cmp		r12, r10				; if char == '%' then
	be		L_FORMATENTRY			;			handle the format specifier
	st.b	r10, 0[r6]				; store the char back to memory
	add		1, r6					; advance pointer to next char
	cmp		0, r10					; if char != 0 then
	bne		L_STRINGLOOP			;			repeat for next char	
	; cleanup and exit
	ld.w	0[sp], r31				; restore clobbered registers
	ld.w	4[sp], r18
	ld.w	8[sp], r17
	ld.w	12[sp], r16
	ld.w	16[sp], r15
	ld.w	20[sp], r14
	ld.w	24[sp], r13
	ld.w	28[sp], r12
	ld.w	32[sp], r11
	addi	36, sp, sp
	jmp		[r31]					; return from subroutine

L_FORMATENTRY:
	mov		0, r14					; assume no leading character for numbers
	movea	' ', r0, r15			; assume print spaces if we do print leads
L_FORMATSPEC:
	ld.b	0[r7], r10				; load the next char from r7
	add		1, r7					; advance pointer to next char
	movea	'd', r0, r12
	cmp		r12, r10				; if char == 'd'
	be		L_PRINT16				;			print 16-bit number
	movea	's', r0, r12
	cmp		r12, r10				; if char == 's'
	be		L_PRINTSTR				;			print string
	movea	'0', r0, r12
	cmp		r12, r10				; if char == '0'
	be		L_SETLEAD				;			print with leading zeros
	movea	'%', r0, r12
	cmp		r12, r10				; if char == '%'
	be		L_PRINTSYMBOL			;			print '%' character
	movea	'l', r0, r12
	cmp		r12, r10				; if char == 'l'
	be		L_PRINT29				;			print 29-bit number
	movea	'X', r0, r12
	cmp		r12, r10				; if char == 'X'
	be		L_PRINTHEXUC			;			print hexadecimal uppercase
	movea	'x', r0, r12
	cmp		r12, r10				; if char == 'x'
	be		L_PRINTHEXLC			;			print hexadecimal lowercase
	; we now assume that we are choosing a number of leading digits to display
	movea	'0', r0, r12
	sub		r12, r10
	mov		r10, r14				; r14 <- char - '0'
	br		L_FORMATSPEC

L_SETLEAD:
	movea	'0', r0, r15			; print leading zeros instead of spaces
	br		L_FORMATSPEC

L_PRINTSYMBOL:
	st.b	r10, 0[r6]				; store '%' symbol to memory
	add		1, r6					; advance pointer to next char
	br		L_STRINGLOOP

L_PRINTSTR:
	ld.w	0[r16], r8				; r8 <- address of string to print
	add		4, r16					; increase parameter pointer				
L_PRINTSTRLOOP:
	ld.b	0[r8], r10				; load a char from r8
	add		1, r8					; advance pointer to next char
	cmp		0, r10					; if char == 0
	be		L_STRINGLOOP			;			then we are done
	st.b	r10, 0[r6]				; store the char back to memory
	add		1, r6					; advance pointer to next char
	br		L_PRINTSTRLOOP

L_PRINT16:
	mov		r6, r13					; r13 <- dest string address
	ld.w	0[r16], r6				; r6 <- 16-bit integer to print
	add		4, r16					; increase parameter pointer
	mov		0, r9					; temp marker for L_PRINTSIGN
	cmp		0, r6					; if integer to print is negative
	blt		L_PRINTSIGN				;		print the sign and adjust
L_SIGNDONE:
	jal		L_PROCESS16				; process a 16-bit number	
	br		L_STRINGLOOP			; return when done

L_PRINTSIGN:
	movea	'-', r0, r10
	st.b	r10, 0[r13]				; print '-' character
	add		1, r13					; advance pointer to next char
	not		r6, r6
	add		1, r6					; integer is now positive
	add		-1, r14					; print one fewer character
	cmp		0, r9					; check to see who called us
	be		L_SIGNDONE
	br		L_SIGN29DONE

L_PRINT29:
	mov		r6, r13					; r13 <- dest string address
	ld.w	0[r16], r6				; r6 <- 29-bit integer to print
	add		4, r16					; increase parameter pointer				
	mov		1, r9					; temp marker for L_PRINTSIGN
	cmp		0, r6					; if integer to print is negative
	blt		L_PRINTSIGN				;		print the sign and adjust
L_SIGN29DONE:
	mov		r7, r18
	movea	0x2710, r0, r7			; r7 <- 0x2710 == 10000
	divu	r7, r6					; split number by dividing by 10000
	mov		r30, r7
	add		-4, r14					; subtract 4 from digits to display
	cmp		0, r6					; if the first chunk is empty
	be		L_P29SKIP				;		then skip it
	add		-4, sp
	st.w	r7, 0[sp]				; save the second number to display
	mov		r18, r7
	jal		L_PROCESS16			    ; process a 16-bit number
	mov		r7, r18
	ld.w	0[sp], r7				; load in the second number
	add		4, sp
	mov		0, r14					; print leading symbols now!
	movea	'0', r0, r15			; make sure they are zeros!
L_P29SKIP:
	mov		r7, r6					; get ready to print second number
	add		4, r14					; add 4 back on to digits
	mov		r18, r7
	jal		L_PROCESS16		    	; process a 16-bit number
	jr		L_STRINGLOOP

L_PRINTHEXLC:
	movea	39, r0, r18				; lowercase offset			
	br		L_PRINTHEX
L_PRINTHEXUC:
	mov		7, r18					; uppercase offset
L_PRINTHEX:
	ld.w	0[r16], r8				; r8 <- integer to print
	add		4, r16					; increase parameter pointer			
	movea	28, r0, r10				; r10 <- 8 digits to cycle through
	mov		0xF, r12				; r12 <- nibble mask
	mov		0, r13					; r13 <- print flag
L_PRINTHEXLOOP:
	mov		r8, r9
	shr		r10, r9
	and		r12, r9					; r9 <- (n >> (cycle * 4)) & 0xF
	or		r9, r13					; if we have not encountered a digit
	be		L_PH_LEADZERO			;			then it is a leading zero
	addi	'0', r9, r9
	mov		r18, r11				; get ready to print a letter
	movea	'9', r0, r17
	cmp		r17, r9					; if the digit is in the alpha range
	bgt		L_PH_ALPHA				;			then print a letter
	mov		0, r11					; else do nothing
L_PH_ALPHA:
	add		r11, r9					; add offset to correct letter
	st.b	r9, 0[r6]				; store the char in memory
	add		1, r6					; advance pointer to next char
	add		-4, r10					; advance to next digit
	bge		L_PRINTHEXLOOP			; loop until done
	jr		L_STRINGLOOP

L_PH_LEADZERO:
	mov		r10, r11
	shr		2, r11					; r11 <- which digit we are on
	add		-4, r10					; if this is our last digit
	blt		L_PH_FINAL				;		then print a zero for sure
	cmp		r11, r14				; if r14 < current digit
	ble		L_PRINTHEXLOOP			;		then keep looping
	st.b	r15, 0[r6]				; print a leading character
	add		1, r6					; advance pointer to next char
	br		L_PRINTHEXLOOP
L_PH_FINAL:
	movea	'0', r0, r9				; if n == 0, print at least one 0
	st.b	r9, 0[r6]
	add		1, r6
	jr		L_STRINGLOOP

L_PROCESS16:
	mov		r7, r18					; free up r7
	mov		0xF, r11
	mov		r6, r7
	shr		4, r7
	mov		r7, r8
	shr		4, r8
	mov		r8, r9
	shr		4, r9
	and		r11, r6					; r6 <- n & 0xF
	and		r11, r7					; r7 <- (n >> 4) & 0xF
	and		r11, r8					; r8 <- (n >> 8) & 0xF
	and		r11, r9					; r9 <- (n >> 12) & 0xF
	mov		r9, r12
	add		r8,	r12
	add		r7, r12
	mov		r12, r11
	shl		2, r11
	shl		1, r12
	add		r12, r6
	add		r11, r6					; r6 <- 6 * (d3 + d2 + d1) + d0
	; divide by ten: multiply by 0x19A shifted right by 12
	mov		r6, r11
	shr		2, r11					
	add		r6, r11
	shr		1, r11					; r11 <- ((d0 >> 2) + i) >> 1
	add		r6, r11
	shr		3, r11					; r11 = (r11 + d0) >> 3
	add		r6, r11
	shr		1, r11					; r11 = (r11 + d0) >> 1
	add		r6, r11
	shr		4, r11					; r11 <- d0 / 10
	; calculate remainder as d0
	mov		r11, r12
	shl		2, r12
	add		r11, r12
	shl		1, r12					; r12 <- q * 10
	sub		r12, r6					; r6 <- d0 - (q * 10)
	; finished with d0, now calculate d1
	mov		r9, r12
	shl		3, r12
	add		r12, r11
	add		r9, r11					; r11 <- q + 9 * d3	
	mov		r8, r12
	shl		2, r12
	add		r12, r11
	add		r8, r11					; r11 <- q + 9 * d3 + 5 * d2
	add		r11, r7					; r7 <- d1 + r11
	be		L_LEAD_D1
	; divide d1 by ten: multiply by 0x19A shifted right by 12
	mov		r7, r11
	shr		2, r11					
	add		r7, r11
	shr		1, r11
	add		r7, r11
	shr		3, r11
	add		r7, r11
	shr		1, r11
	add		r7, r11
	shr		4, r11					; r11 <- d1 / 10
	; calculate remainder as d1
	mov		r11, r12
	shl		2, r12
	add		r11, r12
	shl		1, r12
	sub		r12, r7					; r7 <- d1 - (q * 10)
	; finished with d1, now calculate d2
	shl		1, r8
	add		r11, r8					; r8 <- 2 * d2 + q
	mov		r8, r11
	or		r9, r11					; if (!d2) && (!d3)
	be		L_LEAD_D2				;			then skip
	; divide d2 by ten: multiply by 0x1A >> 8 is sufficient
	mov		r8, r11
	shr		2, r11
	add		r8, r11
	shr		1, r11
	add		r8, r11
	shr		4, r11					; r11 <- d2 / 10
	; calculate remainder as d2
	mov		r11, r12
	shl		2, r12
	add		r11, r12
	shl		1, r12
	sub		r12, r8					; r8 <- d2 - (q * 10)
	; finished with d2, now calculate d3
	shl		2, r9
	add		r11, r9
	be		L_LEAD_D3
	; divide d3 by ten: multiply by 0x1A >> 8 is sufficient
	mov		r9, r11
	shr		2, r11
	add		r9, r11
	shr		1, r11
	add		r9, r11
	shr		4, r11					; r11 <- d3 / 10
	; calculate remainder as d3
	mov		r11, r12
	shl		2, r12
	add		r11, r12
	shl		1, r12
	sub		r12, r9					; r9 <- d3 - (q * 10)
	; finished with d3, d4 will automatically be quotient
	mov		r11, r10
	cmp		0, r10
	be		L_LEAD_D4
	; now print any leading digits if we are using all five
	add		-4, r14					; aleady printed five digits
L_EXTRA_LEAD_LOOP:
	add		-1, r14
	ble		L_DONE_EXTRA_LEAD
	st.b	r15, 0[r13]				; print a leading character
	add		1, r13
	br		L_EXTRA_LEAD_LOOP
L_DONE_EXTRA_LEAD:
	; now print the fifth digit (d4)
	addi	'0', r10, r10			; r10 <- d4 + '0'
	st.b	r10, 0[r13]				; store a character
	add		1, r13					; advance string pointer
L_DONE_D4:
	addi	'0', r9, r9
	st.b	r9, 0[r13]
	add		1, r13
L_DONE_D3:
	addi	'0', r8, r8
	st.b	r8, 0[r13]
	add		1, r13
L_DONE_D2:
	addi	'0', r7, r7
	st.b	r7, 0[r13]
	add		1, r13
L_DONE_D1:
	addi	'0', r6, r6
	st.b	r6, 0[r13]
	add		1, r13
	; Done at last! Clean up and return to calling routine
	mov		r13, r6					; restore r6 <- dest string address
	mov		r18, r7					; restore r7 <- source string address
	jmp		[r31]					; return from subroutine

L_LEAD_D4:
	add		-4, r14
	ble		L_DONE_D4
L_IN_D4:
	st.b	r15, 0[r13]				; print a leading character
	add		1, r13					; advance string pointer
	add		-1, r14					; if chars to print > 0
	bgt		L_IN_D4			    	;			then loop
	br		L_DONE_D4

L_LEAD_D3:
	add		-3, r14
	ble		L_DONE_D3
L_IN_D3:
	st.b	r15, 0[r13]				; print a leading character
	add		1, r13					; advance string pointer
	add		-1, r14					; if chars to print > 0
	bgt		L_IN_D3			    	;			then loop
	br		L_DONE_D3

L_LEAD_D2:
	add		-2, r14
	ble		L_DONE_D2
L_IN_D2:
	st.b	r15, 0[r13]				; print a leading character
	add		1, r13					; advance string pointer
	add		-1, r14					; if chars to print > 0
	bgt		L_IN_D2			    	;			then loop
	br		L_DONE_D2

L_LEAD_D1:
	add		-1, r14
	ble		L_DONE_D1
L_IN_D1:
	st.b	r15, 0[r13]				; print a leading character
	add		1, r13					; advance string pointer
	add		-1, r14					; if chars to print > 0
	bgt		L_IN_D1					;			then loop
	br		L_DONE_D1
