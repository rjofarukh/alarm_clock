;##############################################################################
; TIMER CODE
;------------------------------------------------------------------------------
;	Used when timer is stopped, all digits set to 0
clearDigits
	MOV	R6,	#ZERO
	MOV	R7,	#ZERO
	MOV	R8,	#ZERO
	MOV	R9,	#ZERO
	MOV	PC,	LR

;------------------------------------------------------------------------------
; 	Wait for the start button to be pressed
wait_start
	PUSH	{LR,R0-R1}
not_pushed
	BL	check_stop			; Check if pause is pressed to stop
	BNE	not_reset			; Uses flag from check_stop
	SVC	4				; Print digits
not_reset
	ADRL	R0,	PORT_B
	LDRB 	R1,	[R0]

	AND	R1,	R1,	#L_BTN
	CMP	R1,	#L_BTN
	BNE	not_pushed			; Wait while start not pressed
	POP	{LR,R0-R1}
	B	return_from_svc

;------------------------------------------------------------------------------
;	Check if pause button is pressed
check_pause
	PUSH	{LR,R0-R1}
	ADRL	R0,	PORT_B
	LDRB 	R1,	[R0]

	AND	R1,	R1,	#U_BTN
	CMP	R1,	#U_BTN 			; check if the button is pressed
	BNE	not_pressed			; if it isn't, go back
	BL	check_stop			; if it is, check for stop
	SVC	4				; print digits (in case of reset)
	SVC	1
not_pressed
	POP	{LR,R0-R1}
	MOV	PC,	LR

;------------------------------------------------------------------------------
;	Loop until desired time has passed
timer
	PUSH	{LR,R0-R3}
	MOV	R1,	#SPEED			; Adjust for different speeds
count	ADRL	R0,	TIMER
	LDRB	R2,	[R0]			; R2 stores old value
read	LDRB	R3,	[R0]			; R3 stores new value
	CMP	R2,	R3
	BEQ	read
	SUB	R2,	R3,	R2  		; subtract old from new, to form difference
	ANDGT	R2,	R2,	#&0F 		; If old value is greater than new value

	SUB	R1,	R1,	R2  		; subtract difference from R1

	BL	check_pause			; Check if pause button is pressed

	CMP	R1,	#0			; If R1 hasn't reached 0
	BNE	count
	POP	{LR,R0-R3}
	B	return_from_svc

;------------------------------------------------------------------------------
;	Check if pause button is pressed for stopping
check_stop
	PUSH	{LR,R0-R3}
	MOV	R1,	#1000
count1	ADRL	R0,	TIMER
	LDRB	R2,	[R0]			;R2 stores old value
read1	LDRB	R3,	[R0]			;R3 stores new value
	CMP	R2,	R3
	BEQ	read1
	SUB	R2,	R3,	R2  		; subtract old from new, to form difference
	ANDGT	R2,	R2,	#&0F 		; If old value is greater than new value

	SUB	R1,	R1,	R2  		; subtract difference from R1

;	Check if the pause button is still pressed
;	If it is, loop until R1 is 0
;	If it is not, branch back to check_pause
	ADRL	R0,	PORT_B
	LDRB 	R3,	[R0]

	AND	R3,	R3,	#U_BTN
	CMP	R3,	#U_BTN			; check if pause button is still pressed
	BNE	skip

	CMP	R1,	#0			; Check if counter reached 0
	BNE	count1
	BL	clearDigits


skip	POP	{LR,R0-R3}
	MOV	PC,	LR

;------------------------------------------------------------------------------

;	For printing the digits when they are zeroed in pause
dedicatedPrint
	PUSH	{LR}
	BL	clear
	MOV	R4,	R9
	BL	printChar
	MOV	R4,	R8
	BL	printChar
	MOV	R4,	R7
	BL	printChar
	MOV	R4,	R6
	BL	printChar
	POP	{LR}
	B	return_from_svc

; END OF TIMER CODE
;##############################################################################
