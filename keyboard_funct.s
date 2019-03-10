;###############################################################################
; Functions associated with the NUM_PAD (keyboard)
;-------------------------------------------------------------------------------
check_button
	PUSH	{R0-R4,LR}			; Don't push R5, remember from last interrupt
	MOV 	R2,	#0			; R2 is the row multiplier (CurrentRow)
check_next_row
	ADRL	R1,	NUM_PAD			; R1 holds the keyboard address
	LDRB	R0,	[R1]			; Get keyboard data

	AND	R0,	R0,	#&1F		; Make sure I change only top 3 bits

	ADRL	R3,	ROWS			; Use R3 for other purposes, so dont get address
	LDRB	R3,	[R3,R2]			; Get different row address for 3 iterations

	ORR	R0,	R0,	R3		; Set bit 7 high to check Row 3
	STRB	R0,	[R1]			; Store bit 7 high
	LDRB	R4,	[R1]			; Get current stuff from data
	ANDS	R4,	R4,	#&0F		; Get first 4 bits (data) - Signal
	BEQ	nothing_pressed

	BL	check_range			; Check if only 1 button is pressed
	CMP	R4, #0				; If 2 or more are pressed, check_range returns 0
	BLEQ	nothing_pressed			; Output nothing when 2 buttons are pressed


	MOV	R0,	#0			; Current power
compare
	CMP	R4,	#1			; Since R4 has been validated, it is a power of 2
	BEQ	return_index
	LSR	R4,	R4,	#1		; Shift it right until we reach 1
	ADD	R0,	R0,	#1		; Increment the power
	B	compare


return_index
	MOV	R3,	#4			; To get the offset correctly - 4 Bytes per row
	MLA	R0,	R3,	R2,	R0	; Digit address: UMS + 4 * CurrentRow + BitNumber

	ADRL	R3,	NUMS
	LDRB	R4,	[R3, R0]		; Load R4 from number grid

	CMP	R5,	R4			; R5 starts at 0, which R4 can never be at this point
	BEQ	button_has_been_pressed		; If old and new are the same, then it must be held down
	MOVNE	R5,	R4

	ADRL	R3,	CMD
	LDRB	R0,	[R3]			; We are interested if R5 is * or # if CMD[0] == 0
	CMP	R0,	#&0
	BNE	try_to_get_digit		; If CMD[0] != 0, we are in a mode for changing time
	CMP	R5,	#ZERO			; IF R5 < 30, it is 0, * or #, we put it in CMD[0]
	MOVLT	R0,	R5			; If R5 > 30, R0 will already be 0 from 2 instructions above
	STRB	R0,	[R3]			; and we will eventually store R0 in CMD[0]
	B	button_has_been_pressed		; Acknowledge that a button has been pressed

try_to_get_digit
	CMP 	R5,	#ZERO			; Here, we know that we are in command mode, so want a digit 0-9
	MOV	R0,	#&0
	MOVGE	R0,	R5			; If R5 is a digit for the clock, save it in R0
	STRB	R0,	[R3, #1]		; If R5 is *,# or 0, we will store original R0 (0) in CMD[0]

	MOV	R5,	R4			; R5 becomes the last printed digit
	B	button_has_been_pressed		; Acknowledge that a button has been pressed


nothing_pressed					; Branch here if during iteration to button is pressed
	ADD	R2,	R2,	#1		; Increment to read next row
	CMP	R2,	#3			; 3 Keyboard rows in total
	BLT	check_next_row

	MOV	R5, #0				; Will only reset R5 when during this interrupt no button
						; has been pressed


button_has_been_pressed				; Branch here when during one of the iteration
	POP	{R0-R4,LR}			; a button has been predded
	B	return_from_svc



;------------------------------------------------------------------------------
; If upper button is pressed, seconds and milliseconds are set to 0 (for synchronization)

reset_seconds
	PUSH	{LR,R0,R1}
	ADRL	R0,	PORT_B
	LDRB 	R1,	[R0]

	AND	R1,	R1,	#L_BTN
	CMP	R1,	#L_BTN
	BNE	seconds_not_reset
	ADRL	R1,	SECNDS
	MOV	R0,	#0
	STRB	R0,	[R1]
	STRB	R0,	[R1,#1]

seconds_not_reset
	POP	{LR,R0,R1}
	B	return_from_svc

;------------------------------------------------------------------------------
; Checks if next row (upper) button on the board has been pressed
; If the alarm is on or set off, set ALRM to 0
; else (If it is 0) set ALRM to 1
toggle_alarm
	PUSH	{LR,R0,R1}
	ADRL	R0,	PORT_B
	LDRB 	R1,	[R0]

	AND	R1,	R1,	#U_BTN
	CMP	R1,	#U_BTN
	BNE	not_toggled

	; Reach this block if the alarm has been toggled (button pressed)
	ADRL	R1,	ALRM
	LDRB	R0,	[R1,#1]
	CMP	R0,	#1		; If it is 1, toggle button is held down
	BEQ	toggle_alarm_fin	; Dont toggle the alarm


	LDRB	R0,	[R1]
	CMP	R0,	#1
	MOVGT	R0,	#1		; If alarm is going off, leave it on but disable sound
	MOVLT	R0,	#1		; If it is off, turn it on
	MOVEQ	R0,	#0		; If it is turned on, turn it off
	STRB	R0,	[R1]

	MOV	R0,	#1
	STRB	R0,	[R1,#1]		; Inform that it has just been toggled (to debounce)
	B	toggle_alarm_fin

not_toggled
	ADRL	R1,	ALRM
	MOV	R0,	#0		; On release of button, second byte is set to 0
	STRB	R0,	[R1,#1]		; If second byte is 1, it has just been toggled

toggle_alarm_fin
	POP	{LR,R0,R1}
	B	return_from_svc

;------------------------------------------------------------------------------
; Checks if only 1 of the 4 bits is set high, to avoid having a bias
; towards some of the buttons when more than 1 is pressed
; Doing this as opposed to returning the greater of the two bits when shifting
;

check_range					; Making sure that only 1 button has been pressed
	ADRL 	R0,	RANGE			; If more than 1 button has been pressed, return
	MOV	R1,	#3			; 0 in R4

check_next_bit
	LDRB	R3,	[R0,R1]
	CMP	R3,	R4
	MOVEQ	PC,	LR
	SUBS	R1,	R1,	#1
	BGE	check_next_bit
	MOV	R4,	#0 			; To indicate value isn't valid
	MOV	PC,	LR
