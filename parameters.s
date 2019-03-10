;------------------------------------------------------------------------------
; PARAMETERS

LCD_E	 EQU &1
LCD_RS	 EQU &2
LCD_RW	 EQU &4
STATUS	 EQU &80



L_BTN	 EQU &80				; Lower Button
U_BTN	 EQU &40				; Upper Button

ZERO	 EQU &30				; '0' for printing
ONE	 EQU &31				; '1' for printing
TWO	 EQU &32				; '2' for printing
THREE	 EQU &33				; '3' for printing
FOUR	 EQU &34				; '4' for printing
FIVE	 EQU &35				; '5' for printing
SIX	 EQU &36				; '6' for printing
SEVEN	 EQU &37				; '7' for printing
EIGHT	 EQU &38				; '8' for printing
NINE	 EQU &39				; '9' for printing
OVERFLOW EQU &3A				; Digit overflow
COLON	 EQU &3A
STAR	 EQU &2A

NEXT	 EQU &A8				; Next line command
CLEAR	 EQU &1					; Clear screen command

PORT_A	 EQU &10000000				; Used as BASE for offsetting
PORT_B	 EQU &10000004
TIMER	 EQU &10000008				; Timer location
SPEED	 EQU 100				; Timer speed (milliseconds)
NUM_PAD	 EQU &20000002				; Base address of keyboard
BUZZER	 EQU &20000000				; Address to put the buzzer tone in

NUMS	DEFB	&31, &34, &37, &2A		; Mapping of each button to
	DEFB	&32, &35, &38, &30		; its value for printing, with address:
	DEFB	&33, &36, &39, &23		; NUMS + 4 * CurrentRow + BitNumber

ROWS	DEFB	&80, &40, &20, &20		; Bits to set high when chedking rows


RANGE	DEFB	&1, &2,	&4, &8			; Possible values in data (for single button presses)

;-----------------------------------------------------------------------------
; CLOCK SPECIFIC DEFINITIONS
TIME	DEFB	&30, &39, &34, &30
SECNDS	DEFB	&0, &0, &0, &0			; Byte 0 is seconds
						; Byte 1 is tens of milliseconds

ALRM	DEFB	&0, &0, &0, &0
ALARM	DEFB	&31, &32, &30, &30
CMD	DEFB	&0, &0, &0, &3A			; Bytes used for modifying the current time/ALARM
						; Byte 0 is the last command
						; 	If * or #, then modify time / alarm
						;	If 0 - don't modify anything
						; Byte 1 is the last pressed keypad
						; Byte 2 is the current modified digit
						; 	If 0, haven't modified anything yet
						;	else, modify the digit at that position
						; Byte 3 will store whether to print ':' or not
						;	If value is 3A, print :,
						;	else, if it is 20, print space
STR_T	DEFB "TIME       \0"
STR_A	DEFB "ALARM(ON)  \0"
A_OFF	DEFB "ALARM(OFF) \0"
WAKE	DEFB "WAKE UP!!! \0"
SET_T	DEFB "SET TIME   \0"
SET_A	DEFB "SET ALARM  \0"
ALIGN
;------------------------------------------------------------------------------

	DEFS 100				; SVC stack
s_stack
	DEFS 100				; User stack
_stack
	DEFS 100				; Interrupt stack
_stack_irq
