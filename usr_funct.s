;##############################################################################
; USER DEFINED FUNCTIONS (Don't directly use peripherals)

;	Increment overall value
;	Doesn't use peripherals or print digits, so it is safe for the
;	user. Activity is independent from the timer.
add_one
	PUSH	{LR}
	ADD	R6,	R6,	#1
	CMP	R6,	#NINE
	BLE	printDigits
	MOV	R6,	#ZERO
	ADD	R7,	R7,	#1
	CMP	R7,	#NINE
	BLE	printDigits
	MOV	R7,	#ZERO
	ADD	R8,	R8,	#1
	CMP	R8,	#NINE
	BLE	printDigits
	MOV	R8,	#ZERO
	ADD	R9,	R9,	#1
	CMP	R9,	#NINE
	BLE	printDigits
	MOV	R9,	#ZERO
printDigits
	POP	{LR}
	MOV	PC,	LR

;##############################################################################
