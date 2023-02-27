

; posprintf - a condensed version of sprintf for Thumb, esp. GBA
; Written in 2003 by Dan Posluns
; http://www.danposluns.com/gbadev/posprintf/

; Ported to V810 in 2008 by Derek da Silva

; No rights reserved.
; https://creativecommons.org/publicdomain/zero/1.0/


; register map:

; MAIN LOOP:						PROCESS16:
; r6 <- dest string address			r6 <- d0
; r7 <-								r7 <- d1
; r8 <- integer to print			r8 <- d2
; r9 <-								r9 <- d3
; r10 <- current char				r10 <- d4
; r11 <- 							r11 <- work register
; r12 <- 							r12 <- work register
; r13 <- 							r13 <- dest string address
; r14 <- number of digits to print	r14 <- number of digits to print
; r15 <- leading char (' ' or '0')	r15 <- leading char (' ' or '0')
; r16 <- current parameter pointer	r16 <- current parameter ptr
; r17 <- source string address		r17 <- source string address
; r31 <-							r31 <- lp

; Function parameters:

; r6 <- destination string address
; r7 <- source string address
; r8 <- param1
; r9 <- param2


	isv810
	capsoff
	lprefix ' '
	rsvreg	0
	oncnum

text group

	even 2
	public _posprintf
_posprintf:

	st.w	r8, 8[sp]
	mov		r7, r17					; r17 <- source string address
	st.w	r9, 12[sp]
	movea	8, sp, r16				; r16 <- first parameter pointer

	add		-4, sp					; save link pointer
	st.w	r31, 0[sp]

	movea	'%', r0, r12
L_STRINGLOOP:
	ld.b	0[r17], r10				; load a char from r17
	add		1, r17					; advance pointer to next char
	cmp		r12, r10				; if char == '%' then
	be		L_FORMATENTRY			;			handle the format specifier
	add		1, r6					; advance pointer to next char
	cmp		0, r10					; if char != 0 then
	st.b	r10, -1[r6]				; store the char back to memory
	bne		L_STRINGLOOP			;			repeat for next char
	; cleanup and exit
	ld.w	0[sp], r31				; restore link pointer
	add		4, sp
	jmp		[r31]					; return from subroutine

L_FORMATENTRY:
	mov		0, r14					; assume no leading character for numbers
	movea	' ', r0, r15			; assume print spaces if we do print leads
L_FORMATSPEC:
	ld.b	0[r17], r10				; load the next char from r17
	add		1, r17					; advance pointer to next char
	xori	'd', r10, r0			; if char == 'd'
	be		L_PRINT16				;			print 16-bit number
	xori	's', r10, r0			; if char == 's'
	be		L_PRINTSTR				;			print string
	xori	'0', r10, r0			; if char == '0'
	be		L_SETLEAD				;			print with leading zeros
	xori	'%', r10, r0			; if char == '%'
	be		L_PRINTSYMBOL			;			print '%' character
	xori	'l', r10, r0			; if char == 'l'
	be		L_PRINT29				;			print 29-bit number
	xori	'X', r10, r0			; if char == 'X'
	be		L_PRINTHEXUC			;			print hexadecimal uppercase
	xori	'x', r10, r0			; if char == 'x'
	be		L_PRINTHEXLC			;			print hexadecimal lowercase
	; we now assume that we are choosing a number of leading digits to display
	movea	-'0', r10, r14			; r14 <- char - '0'
	br		L_FORMATSPEC

L_SETLEAD:
	mov		r10, r15				; print leading zeros instead of spaces
	br		L_FORMATSPEC

L_PRINTSYMBOL:
	st.b	r10, 0[r6]				; store '%' symbol to memory
	add		1, r6					; advance pointer to next char
	br		L_STRINGLOOP-4

L_PRINTSTR:
	ld.w	0[r16], r8				; r8 <- address of string to print
	add		4, r16					; increase parameter pointer
L_PRINTSTRLOOP:
	ld.b	0[r8], r10				; load a char from r8
	add		1, r8					; advance pointer to next char
	cmp		0, r10					; if char == 0
	be		L_STRINGLOOP-4			;			then we are done
	st.b	r10, 0[r6]				; store the char back to memory
	add		1, r6					; advance pointer to next char
	br		L_PRINTSTRLOOP

L_PRINT16:
	mov		r6, r13					; r13 <- dest string address
	ld.w	0[r16], r6				; r6 <- 16-bit integer to print
	add		4, r16					; increase parameter pointer
	cmp		0, r6					; if integer to print is negative
	mov		0, r9					; temp marker for L_PRINTSIGN
	blt		L_PRINTSIGN				;		print the sign and adjust
L_SIGNDONE:
	jal		L_PROCESS16				; process a 16-bit number
	br		L_STRINGLOOP-4			; return when done

L_PRINTSIGN:
	not		r6, r6
	add		1, r6					; integer is now positive
	add		-1, r14					; print one fewer character
	add		1, r13					; advance pointer to next char
	cmp		0, r9					; check to see who called us
	movea	'-', r0, r10
	st.b	r10, -1[r13]			; print '-' character
	be		L_SIGNDONE
	br		L_SIGN29DONE

L_PRINT29:
	mov		r6, r13					; r13 <- dest string address
	ld.w	0[r16], r6				; r6 <- 29-bit integer to print
	add		4, r16					; increase parameter pointer
	cmp		0, r6					; if integer to print is negative
	mov		1, r9					; temp marker for L_PRINTSIGN
	blt		L_PRINTSIGN				;		print the sign and adjust
L_SIGN29DONE:
	movea	0x2710, r0, r7			; r7 <- 0x2710 == 10000
	add		-4, r14					; subtract 4 from digits to display
	divu	r7, r6					; split number by dividing by 10000
	be		L_P29SKIP				; if the first chunk is empty then skip it
	jal		L_PROCESS16			    ; process a 16-bit number
	mov		0, r14					; print leading symbols now!
	movea	'0', r0, r15			; make sure they are zeros!
L_P29SKIP:
	mov		r30, r6					; get ready to print second number
	add		4, r14					; add 4 back on to digits
	jal		L_PROCESS16		    	; process a 16-bit number
	br		L_STRINGLOOP-4

L_PRINTHEXLC:
	movea	39, r0, r7				; lowercase offset
	br		L_PRINTHEX
L_PRINTHEXUC:
	mov		7, r7					; uppercase offset
L_PRINTHEX:
	ld.w	0[r16], r8				; r8 <- integer to print
	add		4, r16					; increase parameter pointer
	movea	28, r0, r10				; r10 <- 8 digits to cycle through
	mov		0, r12					; r12 <- print flag
L_PRINTHEXLOOP:
	mov		r8, r9
	shr		r10, r9
	andi	0xF, r9, r9				; r9 <- (n >> (cycle * 4)) & 0xF
	or		r9, r12					; if we have not encountered a digit
	movea	'9', r0, r11
	be		L_PH_LEADZERO			;			then it is a leading zero
	addi	'0', r9, r9
	cmp		r11, r9					; if the digit is in the alpha range
	mov		r7, r11					; get ready to print a letter
	bgt		L_PH_ALPHA				;			then print a letter
	mov		0, r11					; else do nothing
L_PH_ALPHA:
	add		r11, r9					; add offset to correct letter
	add		1, r6					; advance pointer to next char
	add		-4, r10					; advance to next digit
	st.b	r9, -1[r6]				; store the char in memory
	bge		L_PRINTHEXLOOP			; loop until done
	jr		L_STRINGLOOP-4

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
	jr		L_STRINGLOOP-4

L_PROCESS16:
	andi	0xF000, r6, r9
	andi	0x0F00, r6, r8
	andi	0x00F0, r6, r7
	andi	0x000F, r6, r6			; r6 <- n & 0xF
	shr		4, r7					; r7 <- (n >> 4) & 0xF
	shr		8, r8					; r8 <- (n >> 8) & 0xF
	shr		12, r9					; r9 <- (n >> 12) & 0xF
	mov		r9, r12
	add		r8,	r12
	add		r7, r12
	shl		1, r12
	add		r12, r6
	add		r12, r6
	add		r12, r6					; r6 <- 6 * (d3 + d2 + d1) + d0
	; divide by ten: multiply by 0x19A shifted right by 12
	movea	0x19A, r0, r11
	mpyhw	r6, r11
	shr		12, r11					; r11 <- d0 / 10
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
	movea	0x19A, r0, r11
	be		L_LEAD_D1
	; divide d1 by ten: multiply by 0x19A shifted right by 12
	mpyhw	r7, r11
	shr		12, r11					; r11 <- d1 / 10
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
	mov		r8, r11
	be		L_LEAD_D2				;			then skip
	; divide d2 by ten: multiply by 0x1A >> 8 is sufficient
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
	mov		r9, r11
	be		L_LEAD_D3
	; divide d3 by ten: multiply by 0x1A >> 8 is sufficient
	shr		2, r11
	add		r9, r11
	shr		1, r11
	add		r9, r11
	shr		4, r11					; r11 <- d3 / 10
	; calculate remainder as d3
	mov		r11, r12
	be		L_LEAD_D4
	shl		2, r12
	add		r11, r12
	shl		1, r12
	sub		r12, r9					; r9 <- d3 - (q * 10)
	; finished with d3, d4 will automatically be quotient
	; now print any leading digits if we are using all five
	add		-5, r14					; aleady printed five digits
	movea	'0', r11, r10			; r10 <- d4 + '0'
	ble		L_DONE_EXTRA_LEAD
L_EXTRA_LEAD_LOOP:
	add		1, r13
	add		-1, r14
	st.b	r15, -1[r13]			; print a leading character
	bgt		L_EXTRA_LEAD_LOOP
L_DONE_EXTRA_LEAD:
	; now print the fifth digit (d4)
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
	jmp		[r31]					; return from subroutine

L_LEAD_D4:
	add		-4, r14
	ble		L_DONE_D4
L_IN_D4:
	add		1, r13					; advance string pointer
	add		-1, r14					; if chars to print > 0
	st.b	r15, -1[r13]			; print a leading character
	bgt		L_IN_D4			    	;			then loop
	br		L_DONE_D4

L_LEAD_D3:
	add		-3, r14
	ble		L_DONE_D3
L_IN_D3:
	add		1, r13					; advance string pointer
	add		-1, r14					; if chars to print > 0
	st.b	r15, -1[r13]			; print a leading character
	bgt		L_IN_D3			    	;			then loop
	br		L_DONE_D3

L_LEAD_D2:
	add		-2, r14
	ble		L_DONE_D2
L_IN_D2:
	add		1, r13					; advance string pointer
	add		-1, r14					; if chars to print > 0
	st.b	r15, -1[r13]			; print a leading character
	bgt		L_IN_D2			    	;			then loop
	br		L_DONE_D2

L_LEAD_D1:
	add		-1, r14
	ble		L_DONE_D1
L_IN_D1:
	add		1, r13					; advance string pointer
	add		-1, r14					; if chars to print > 0
	st.b	r15, -1[r13]			; print a leading character
	bgt		L_IN_D1					;			then loop
	br		L_DONE_D1
