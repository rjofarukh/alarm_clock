b start
PIO EQU &20000000

start
ADRL	R0,	PIO
MOV	R1,	#&8F
STRB	R1,	[R0]

end
b end
