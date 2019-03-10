;##############################################################################
; EXERCISE 7 - KEYBOARDS
; COMP22712
;
; Richard-Johnson Farukh
; StudentID: 9706660
;
; DATE: 18.03.2017
;
;------------------------------------------------------------------------------
; READ ME
;
; Compile and run this file !
; The user is redirected to the user code section in the beginning - B start
;
; In this program, a keyboard is polled every 10 milliseconds from an interrupt
; which is caused by the timer incrementing
;
; The program offers a clock and an alarm facility, the clock being on the top
; row of the LCD and the alarm being displayed on the bottom
; The colon on the clock blinks every second to notify the user that it is ticking
; and the clock can be seen while setting the alarm and vice versa
;
; The screen refreshes every 10 ms to record the pressing of * or #
; When pressing *, the user can set the time, and when pressing #, they can set
; the alarm to the correct time, both of which are located in memory.
;
; Pressing the lower button resets the seconds and milliseconds to 0 (for synchronizing)
;
; REGISTERS
; R4 is used in the printChar function, but only during check button SVC call
; R5 is a global register, which holds the last printed character (for debouncing)
;
; FUNCTIONS
; SVC 0 - End program
; SVC 1 - check if the button on keyboard is pressed
; SVC 2 - check if the lower button on the board is pressed - clear seconds
; SVC 3 - check if the upper button on the board is pressed - toggle alarm on and off
;
; EXTRA BUTTONS
; Lower button - clears seconds
; Upper button - toggle alarm
;
;------------------------------------------------------------------------------
	B	initialize
	B	end
	B	svc_start
	B	end
	B	end
	B	end
	B	interrupt

;------------------------------------------------------------------------------
initialize
	MOV	R7,	#0			; R8 stores timer for clock
	ADRL 	SP, 	s_stack			; Allocating SVC stack
	MOV	R0,	#1			; Timer interrupts are at bit 0
	MOV	R3,	#PORT_A
	STRB	R0,	[R3,	#&1C]		; Allow timer interrupts
	MOV	R0,	#&0F			; Define the control for the keyboard; Used to be 1F
	ADRL	R1,	NUM_PAD
	STRB	R0,	[R1,	#1]		; Set keyboard controll

	BL	clear				; Start with cleared screen

	MSR	CPSR_c, #&52			; Switch to IRQ mode
	ADRL	SP,	_stack_irq		; Initialize IRQ stack

	MSR	CPSR_c,	#&50			; Switch to user mode with interrupt enabled
	ADRL	SP,	_stack			; Initialize user stack
	B 	start				; Jump to the start of the code

;------------------------------------------------------------------------------
svc_start
	PUSH	{R10, R11}			; Start of SVC call
	LDR	R11,	[LR,#-4]		; Getting correct SVC instruction
	BIC	R11,	R11,	#&FF000000

	CMP	R11,	#8			; If value out of range
	BGT	return_from_svc			; retun from svc

	ADR	R10,	SVC_Jump_Table		; Load jump table address
	ADD	PC,	R10,	R11,	LSL #2  ; Offset with theset in memory. svc parameter and  Go to jump table address

return_from_svc
	POP	{R10, R11}
	MOVS	PC,	LR			; Go back to previous mode

;------------------------------------------------------------------------------
interrupt
	SVC	5				; Check the button on keyboard
	SVC	6				; Check lower button on board to clear
	SVC	7				; Check upper button on board for next line
	SVC	8				; Go to check/set the time
	LDRB	R1,	[R3, #&C]		; Get current value in comparison address
	ADD	R1,	R1,	#10		; Increment value in comparison, to have an interrupt after 10ms
						; As it is a byte register, on overflow goes to 0
	STRB	R1,	[R3, #&C]		; Store value in comparison mem location
	MOV	R2,	#0			; Value to Acknowledge interrupt
	STRB	R2,	[R3, #&18]		; Acknowledge interrupt (R3 is 10000000)
	SUBS	PC,	LR, 	#4		; Go back to previous mode

;------------------------------------------------------------------------------
SVC_Jump_Table
	B	end				; SVC 0
	B	wait_start			; SVC 1
	B	timer				; SVC 2
	B	add_one				; SVC 3
	B	dedicatedPrint			; SVC 4
	B	check_button			; SVC 5
	B	reset_seconds			; SVC 6
	B	toggle_alarm			; SVC 7
	B	increment_millis		; SVC 8

;##############################################################################
;##############################################################################
; USER CODE




start
	B start
; END OF USER CODE
;##############################################################################
;##############################################################################
include keyboard_funct.s
include lcd_funct.s
include usr_funct.s
include timer_funct.s
include clock.s
include parameters.s
