;##############################################################################
; FUNCTION TO INCREMENT THE CURRENT TIME
increment_millis
	PUSH	{LR,R3-R6}

	ADRL	R5,	CMD
	LDRB	R5,	[R5]
	CMP	R5,	#STAR		; Check if control button is pressed (*)
	BNE	cont_to_increment	; If it's not, continue
	BL	clear
	BL	change_t_or_a		; else, we go to the change function
	BL	start_print		; print the change time dialogue

	BL	print_full_alarm

cont_to_increment
;	Actual clock operatios  -----------------------------------------------

	ADRL	R5,	SECNDS
	LDRB	R3,	[R5,#1]		; Getting the number of 10s of milliseconds
	ADD	R3,	R3,	#1	; Incrementing them by 1 at each interrupt
	CMP	R3,	#100		; When it is 100 * 10 ms, 1 second has passed
	MOVEQ	R3,	#0
	STRB	R3,	[R5,#1]		; Store the change

	BLT	increment_millis_fin

	ADRL	R4,	CMD		; To get ':' to blink for time
	LDRB	R3,	[R4,#3]		; load last byte
	CMP	R3,	#COLON
	MOVEQ	R3,	#&20		; Load space character
	MOVNE	R3,	#COLON
	STRB	R3,	[R4,#3]


;	If milliseconds overflow (passed one second) and the alarm is off (ALRM > 1)#################################################################
;	Decrement ALRM until it is equal to 1, and when it is, turn off buzzer
;	If the alarm is <= 1, don't do anything
	ADRL	R3,	ALRM
	LDRB	R4,	[R3]
	CMP	R4,	#1
	BLE	disable_buzz		; If the alarm is not going off, subtract the number of seconds it is on
	SUB	R4,	R4,	#1
	STRB	R4,	[R3]

	ADRL	R3,	CMD
	LDRB	R4,	[R3,#3]
	CMP	R4,	#COLON
	MOVEQ	R4,	#&8F
	MOVNE	R4,	#0

	ADRL	R3,	BUZZER
	STRB	R4,	[R3]
	B	proceed_to_seconds

disable_buzz
	ADRL	R3,	BUZZER
	MOV	R4,	#&0
	STRB	R4,	[R3]
proceed_to_seconds
	LDRB	R3,	[R5]		; Here it is time to increment the seconds
	ADD	R3,	R3,	#1
	CMP	R3,	#60
	MOVEQ	R3,	#0		; If seconds overflow, we will print the new digits
	STRB	R3,	[R5]

	BLT	increment_millis_fin

; -----------------------------------------------------------------------------

	ADRL	R5,	TIME


	LDRB	R4,	[R5, #3]	; Last digit
	ADD	R4,	R4,	#1
	CMP	R4,	#OVERFLOW	; Check if minutes overflows (At 10)
	MOVEQ	R4,	#ZERO		; If overflows, go back to 0
	STRB	R4,	[R5, #3]

	BNE	check_alarm		; If hasn't overflown from comparison

	LDRB	R4,	[R5, #2]	; Second to last digit
	ADDEQ	R4,	R4,	#1	; Add only if previous overflows (At 6)
	CMP	R4,	#SIX		; Check if minutes overflows
	MOVEQ	R4,	#ZERO		; If overflows, go back to 0
	STRB	R4,	[R5, #2]

	BNE	check_alarm

	LDRB	R3,	[R5]		; Get most significant digit


	CMP	R3,	#TWO
	MOVEQ	R3,	#FOUR
	MOVNE	R3,	#OVERFLOW


	LDRB	R4,	[R5, #1]	; Load 2nd digit
	ADD	R4,	R4,	#1	; Increment it if overflows
	CMP	R4,	R3		; Check if overflows
	BEQ	does_overflow		; If it reaches the overflow value

	STRB	R4,	[R5, #1]	; If it doesnt overflow, dont change
	B	check_alarm

does_overflow
	CMP	R3,	#OVERFLOW	; Check why it overflows
	MOVEQ	R4,	#ZERO		; If it has overflown to &3A, it was 9:59, so set digit 2 to 0
	MOVNE	R4,	#ZERO		; Else, it was 12:59 so it overflows to 01:00

	STRB	R4,	[R5, #1]	; Save second digit overflown value

	LDRB	R4,	[R5]		; Get first digit
	ADD	R4,	R4,	#1	; Increment it if overflows

	CMP	R4,	#THREE

	MOVEQ	R4,	#ZERO
	STRB	R4,	[R5]


;	After the time has been changed (once per minute) check if the alarm is on (ALRM = 1)	#################################################################
;	if it is (ALRM = 1) and the time is equal to the alarm time, then set off alarm (ALRM = 11) and turn on buzzer
;	else if it is off (ALRM = 0) don't do anything
	B	check_alarm

increment_millis_fin
	; Time is modified, so time to check if * or # have been pressed
	BL	clear
	ADRL	R6,	STR_T		; Printing time as usual (TIME: TI:ME)
	BL	printString
	BL	start_print

	ADRL	R5,	CMD
	LDRB	R5,	[R5]
	CMP	R5,	#&23		; If it is '#', then change the alarm
	BNE	dont_change_time
	BL	change_t_or_a
	BL	start_print_alarm	; print the change time dialogue
	B	increment_millis_pop

dont_change_time
	BL	print_full_alarm
increment_millis_pop
	POP	{LR,R3-R6}
	B	return_from_svc

;##############################################################################
; FUNCTION TO PRINT THE CURRENT TIME
start_print
	PUSH	{LR,R3-R5}
	ADRL	R5,	TIME
	MOV	R3,	#0		; Starting to print

get_next_time
	LDRB	R4,	[R5,R3]
	BL	printChar
	CMP	R3,	#1
	BNE	not_colon_yet

	ADRL	R4,	CMD
	LDRB	R4,	[R4,#3]		; Load byte containing colon
	BL	printChar

not_colon_yet
	ADD	R3,	R3,	#1	; Substract 1 and cmp to 0
	CMP	R3,	#3
	BLE	get_next_time

	BL	nextLine
	POP	{LR,R3-R5}
	MOV	PC,	LR

;##############################################################################
; FUNCTION TO PRINT THE ALARM TIME
; Different to printing the current time, colon doesnt blink and the
; string is different
start_print_alarm
	PUSH	{LR,R3-R5}

	ADRL	R5,	ALARM		; If alarm is on, print alarm, else print alarm (off)
	MOV	R3,	#0		; Starting to print

get_next_alarm
	LDRB	R4,	[R5,R3]
	BL	printChar
	CMP	R3,	#1
	MOVEQ	R4,	#COLON 		; Print colon
	BLEQ	printChar

	ADD	R3,	R3,	#1	; Substract 1 and cmp to 0
	CMP	R3,	#3
	BLE	get_next_alarm

	POP	{LR,R3-R5}
	MOV	PC,	LR

;##############################################################################
; Print full alarm
print_full_alarm
	PUSH 	{LR,R5,R6}
	ADRL	R5,	ALRM
	LDRB	R5,	[R5]
	CMP	R5,	#1
	BGT	alarm_goes_off
	BLT	alarm_is_off

alarm_is_on
	ADRL	R6,	STR_A		; Print ALARM
	BL	printString
	BL	start_print_alarm	; Print the alarm on next row
	B	print_full_alarm_fin

alarm_is_off
	ADRL	R6,	A_OFF		; Print ALARM
	BL	printString
	BL	start_print_alarm	; Print the alarm on next row
	B	print_full_alarm_fin

alarm_goes_off
	ADRL	R6,	WAKE		; Print ALARM
	BL	printString
	BL	start_print_alarm	; Print the alarm on next row

print_full_alarm_fin
	POP 	{LR,R5,R6}
	MOV 	PC,	LR
;##############################################################################
; TESTING
check_alarm
	PUSH	{R3-R7}
	ADRL	R6,	ALRM
	LDRB	R6,	[R6]
	CMP	R6,	#1		; Check if alarm is on
	BNE	check_alarm_fin 	; If it isn't on, return
	ADRL	R6,	ALARM
	ADRL	R7,	TIME

	MOV	R3,	#3
check_next_number

	LDRB	R4,	[R6,R3]
	LDRB	R5,	[R7,R3]
	CMP	R4,	R5
	BNE	check_alarm_fin

	SUBS	R3,	R3,	#1
	BGE	check_next_number

;	REACH THIS WHEN ALL THE DIGITS ARE THE SAME - set off alarm
	ADRL	R6,	ALRM		; Store 21 (num seconds left on alarm is 10)
	MOV	R5,	#21
	STRB	R5,	[R6]

check_alarm_fin
	POP	{R3-R7}
	B	increment_millis_fin



;##############################################################################
; FUNCTION TO CHANGE THE TIME OR THE ALARM
; Reach it only if CMD[0] != 0, so no need to check
; R5 - CMD address
; R6 - the address of the alarm or the time

change_t_or_a
	PUSH	{LR,R3-R6}
	ADRL	R5,	CMD		; Loading command
	LDRB	R3,	[R5]
	CMP	R3,	#STAR		; If it is * (2A), then change time
	BNE	not_time

	ADRL	R6,	SET_T		; If we're modifying the time
	BL	printString		; Pring SET TIME:
	ADRL	R6,	TIME

	B	check_digits

not_time
	ADRL	R6,	SET_A		; If we're modifying the alarm
	BL	printString		; Print SET ALARM:
	ADRL	R6,	ALARM

check_digits
	LDRB	R3,	[R5,#2]
	ADRL	R4,	digit_table
	ADD	PC,	R4,	R3,	LSL #2

digit_table
	B	first_time_setting	; If CMD[2] == 0, set all to "_" and return
	B	set_digit_1		; Else, try to set next digit to current key press
	B	set_digit_2
	B	set_digit_3
	B	set_digit_4


first_time_setting
	MOV	R3,	#0
	MOV	R4,	#&5F		; Move '_' to all digit places

change_underscore_loop
	STRB	R4,	[R6,R3]
	ADD	R3,	R3,	#1
	CMP	R3,	#3
	BLE	change_underscore_loop

	MOV	R3,	#1
	STRB	R3,	[R5,#2]		; Store #1 it CMD[2] - next time change digit 1
	B	change_t_or_a_fin

set_digit_1
	LDRB	R3,	[R5, #1]	; R3 stores last pressed digit on KB
	CMP	R3,	#ZERO		; If less than 0, print and exit
	BLT	change_t_or_a_fin
	CMP	R3,	#THREE		; If >= 2, print and exit
	BGE	change_t_or_a_fin

	MOV	R4,	#0		; We know it's in range, so change the digit
	STRB	R4,	[R5, #1]	; Clear last pressed digit
	STRB	R3,	[R6]

	MOV	R4,	#2		; Else, change next digit
	STRB	R4,	[R5,#2]		; Store #2 it CMD[2] - next time change digit 2

	B	change_t_or_a_fin

set_digit_2
	;First need to check if the first digit is the maximum, if it is, limit is different
	LDRB	R3,	[R6]
	CMP	R3,	#TWO		; R4 will store the LIMIT
	MOVEQ	R4,	#THREE		; Limit is two if first digit is ONE
	MOVNE	R4,	#NINE		; Will never be greater than 9 otherwise, but good to have

	LDRB	R3,	[R5, #1]	; R3 stores last pressed digit on KB
	CMP	R3,	#ZERO		; If less than 0, print and exit
	BLT	change_t_or_a_fin
	CMP	R3,	R4		; If > LIMIT, print and exit
	BGT	change_t_or_a_fin

	MOV	R4,	#0		; We know it's in range, so change the digit
	STRB	R4,	[R5, #1]	; Clear last pressed digit
	STRB	R3,	[R6, #1]

	MOV	R4,	#3
	STRB	R4,	[R5,#2]		; Store #3 it CMD[2] - next time change digit 3

	B	change_t_or_a_fin

set_digit_3
	LDRB	R3,	[R5, #1]	; R3 stores last pressed digit on KB
	CMP	R3,	#ZERO		; If less than 0, print and exit
	BLT	change_t_or_a_fin
	CMP	R3,	#SIX		; If >= 6, print and exit
	BGE	change_t_or_a_fin

	MOV	R4,	#0		; We know it's in range, so change the digit
	STRB	R4,	[R5, #1]	; Clear last pressed digit
	STRB	R3,	[R6,#2]

	MOV	R4,	#4		; Else, change next digit
	STRB	R4,	[R5,#2]		; Store #4 it CMD[2] - next time change digit 4

	B	change_t_or_a_fin

set_digit_4
	LDRB	R3,	[R5, #1]	; R3 stores last pressed digit on KB
	CMP	R3,	#ZERO		; If less than 0, print and exit
	BLT	change_t_or_a_fin

	MOV	R4,	#0		; We know it's in range, so change the digit
	STRB	R4,	[R5, #1]	; Clear last pressed digit
	STRB	R3,	[R6, #3]

	MOV	R4,	#0		; Else, change next digit
	STRB	R4,	[R5,#2]		; Store #0 it CMD[2] - we are done changing
	STRB	R4,	[R5]

change_t_or_a_fin

	POP	{LR,R3-R6}
	MOV	PC,	LR
