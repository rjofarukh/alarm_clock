;##############################################################################
; LCD CODE
;------------------------------------------------------------------------------
; Loop to end the program - SVC 0
end
	B end
;------------------------------------------------------------------------------
; Routine to clear the screen
clear	PUSH 	{LR, R4}
	MOV 	R4, 	#CLEAR
	BL 	commandSequence
	POP 	{LR, R4}
	MOV 	PC, 	LR

;------------------------------------------------------------------------------

; Routine to print new line
nextLine
	PUSH 	{LR, R4}
	MOV 	R4, 	#NEXT
	BL 	commandSequence
	POP 	{LR, R4}
	MOV 	PC, 	LR

;------------------------------------------------------------------------------

; Routine to print a string at R6
printString
	PUSH 	{LR, R4}
nextChar
	LDRB 	R4, 	[R6], 	#1
	CMP 	R4, 	#0
	BEQ 	exitPrintString
	BL 	printChar
	B 	nextChar

exitPrintString
	POP 	{LR, R4}
	MOV 	PC, 	LR

;------------------------------------------------------------------------------

; Routine for printing a character
printChar
	PUSH 	{R0-R2}

	MOV 	R0, 	#PORT_B 		; set control for input
	MOV 	R1, 	#LCD_RW
	STRB 	R1, 	[R0]

wait	ORR 	R1, 	R1, 	#LCD_E 		; set enable
	STRB 	R1, 	[R0]

	MOV 	R0, 	#PORT_A 		; read status bit
	LDRB 	R2, 	[R0]

	MOV 	R0, 	#PORT_B 		; set enable bit to low
	MOV 	R1, 	#LCD_RW
	STRB 	R1, 	[R0]

	AND 	R2, 	R2, 	#STATUS
	CMP 	R2, 	#STATUS
	BEQ 	wait 				; if it is busy, back to step 2 to wait

	MOV 	R0, 	#PORT_B 		; Set to write data
	MOV 	R1, 	#LCD_RS
	STRB 	R1, 	[R0]

	MOV 	R0, 	#PORT_A 		; write character in R4
	MOV 	R1, 	R4
	STRB 	R1, 	[R0]

	MOV 	R0, 	#PORT_B 		; set enable high
	MOV 	R1, 	#LCD_E
	ORR 	R1, 	R1, 	#LCD_RS
	STRB 	R1, 	[R0]


		MOV 	R1, 	#LCD_RS 	; set enable low
	STRB 	R1, 	[R0]

	POP 	{R0-R2}
	MOV 	PC, 	LR

;------------------------------------------------------------------------------
; Command sequence

commandSequence
	PUSH 	{R0-R2}

	MOV 	R0, 	#PORT_B 		; set control for input
	MOV 	R1, 	#LCD_RW
	STRB 	R1, 	[R0]

wait_c	ORR 	R1, 	R1, 	#LCD_E 		; set enable
	STRB 	R1, 	[R0]

	MOV 	R0, 	#PORT_A 		; read status bit
	LDRB 	R2, 	[R0]

	MOV 	R0, 	#PORT_B 		; set enable bit to low
	MOV 	R1, 	#LCD_RW
	STRB 	R1, 	[R0]

	AND 	R2, 	R2, 	#STATUS
	CMP 	R2, 	#STATUS
	BEQ 	wait_c 				; if it is busy, back to step 2 to wait

	MOV	R0, 	#PORT_B 		; Set to write data
	MOV	R1, 	#0
	STRB	R1,	[R0]

	MOV	R0, 	#PORT_A 		; Clear data
	MOV	R1, 	R4
	STRB	R1, 	[R0]

	MOV	R0, 	#PORT_B 		; set enable high
	MOV	R1, 	#LCD_E
	STRB	R1, 	[R0]

	MOV	R1, 	#0			; set enable low
	STRB	R1, 	[R0]

	POP	{R0-R2}
	MOV	PC, 	LR
;##############################################################################
