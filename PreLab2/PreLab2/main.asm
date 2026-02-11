


.include "M328PDEF.inc"
.cseg
.org 0x0000
rjmp RESET

RESET:

LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R16, HIGH(RAMEND)
OUT SPH, R16

// LEDs de PD2 al PD5 salida
LDI R16, 0b00111100
OUT DDRD, R16

//Timer0 en modo normal, prescaler 1024
LDI R16, 0x00
OUT TCCR0A, R16
LDI R16, 0x05
OUT TCCR0B, R16

// limpiar bandera overflow
LDI R16, (1<<TOV0)
OUT TIFR0, R16

CLR R20  // contador 0..15
CLR R21  // cuenta overflows

LOOP:


// esperar overflow Timer0
WAIT_OVF:
IN  R17, TIFR0
SBRS R17, TOV0
RJMP WAIT_OVF

// limpiar overflow
LDI R17, (1<<TOV0)
OUT TIFR0, R17

// contar overflows hasta 100ms 

INC R21
CPI R21, 6  // 6*16.384ms ? 98ms (con 16MHz, /1024)
BRNE LOOP

CLR R21
INC R20
ANDI R20, 0x0F

// mostrar en PD2 al PD5

IN   R16, PORTD
ANDI R16, 0b11000011   // limpia PD2..PD5
MOV  R19, R20
LSL  R19
LSL  R19                 ; (R20 << 2)  PD2..PD5
ANDI R19, 0b00111100
OR   R16, R19
OUT  PORTD, R16

RJMP LOOP