;Laboratorio 1
; Luis Guerra 24007

.include "M328PDEF.inc"
.cseg
.org 0x0000

;------------------------------------------------
; CONFIGURAR PILA
;------------------------------------------------
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R16, HIGH(RAMEND)
OUT SPH, R16

;------------------------------------------------
; SETUP
;------------------------------------------------
SETUP:

; Apagar UART para que RX/TX no molesteN
LDI R16, 0x00
STS UCSR0B, R16

; PORTB = salida (resultado de suma)
LDI R16, 0xFF
OUT DDRB, R16
LDI R16, 0x00
OUT PORTB, R16

; PORTC:
// PC0..PC3 = LEDs Contador2 (salidas)
// PC4      = LED Carry (salida)
// PC5      = Botón SUMA (entrada)


LDI R16, 0b00011111 ; PC0..PC4 salidas, PC5 entrada
OUT DDRC, R16
LDI R16, 0b00100000 ; pull-up en PC5, LEDs apagados
OUT PORTC, R16

; PORTD:
; PD0..PD3 = LEDs Contador1 (salidas)
; PD4..PD7 = Botones (entradas con pull-up)
LDI R16, 0b00001111
OUT DDRD, R16
LDI R16, 0b11110000       ; pull-ups en PD4..PD7
OUT PORTD, R16

; Oscilador a 1 MHz (prescaler /16)
LDI R16, (1<<CLKPCE)
STS CLKPR, R16
LDI R16, 0x04
STS CLKPR, R16

; Inicializar contadores 
//CLR pone el registro Rx en cero :D

CLR R20                   ; Contador 1 (0..15)
CLR R22                   ; Contador 2 (0..15)
CLR R24                   ; suma temporal

;------------------------------------------------
; LOOP PRINCIPAL
;------------------------------------------------
LOOP:
CALL LEER_BOTONES_C1
CALL LEER_BOTONES_C2
CALL MOSTRAR_C1_EN_PORTD
CALL MOSTRAR_C2_EN_PORTC
CALL BOTON_SUMA_MOSTRAR_EN_CLICK
RJMP LOOP


; CONTADOR 1 (R20)
; PD4 = INC C1, PD5 = DEC C1 (pull-up: suelto=1, presionado=0)


LEER_BOTONES_C1:
IN  R18, PIND

; DEC C1 (PD5)
SBRS R18, 5 ; si PD5=1 suelto entonces salta y NO entra
RJMP C1_DEC_PRES
RJMP C1_CHECK_INC

C1_DEC_PRES:
CALL ANTIREBOTE_DELAY
IN   R18, PIND
SBRS R18, 5     ; si ya se soltó (1) entonces no  debe de contar
RJMP C1_DEC_REAL
RJMP C1_CHECK_INC

C1_DEC_REAL:
DEC  R20
ANDI R20, 0x0F

C1_WAIT_DEC_RELEASE:
IN   R18, PIND
SBRS R18, 5
RJMP C1_WAIT_DEC_RELEASE
RJMP C1_FIN

// INC C1 (PD4)
C1_CHECK_INC:
IN  R18, PIND
SBRS R18, 4
RJMP C1_INC_PRES
RJMP C1_FIN


C1_INC_PRES:
CALL ANTIREBOTE_DELAY
IN   R18, PIND
SBRS R18, 4
RJMP C1_INC_REAL
RJMP C1_FIN

C1_INC_REAL:
INC  R20
ANDI R20, 0x0F

C1_WAIT_INC_RELEASE:
IN   R18, PIND
SBRS R18, 4
RJMP C1_WAIT_INC_RELEASE

C1_FIN:
RET

; CONTADOR 2 (R22)
; PD6 = DEC C2, PD7 = INC C2 (pull-up: suelto=1, presionado=0)


LEER_BOTONES_C2:
IN  R18, PIND

; ---- DEC C2 (PD6) ----
SBRS R18, 6
RJMP C2_DEC_PRES
RJMP C2_CHECK_INC

C2_DEC_PRES:
CALL ANTIREBOTE_DELAY
IN   R18, PIND
SBRS R18, 6
RJMP C2_DEC_REAL
RJMP C2_CHECK_INC

C2_DEC_REAL:
DEC  R22
ANDI R22, 0x0F

C2_WAIT_DEC_RELEASE:
IN   R18, PIND
SBRS R18, 6
RJMP C2_WAIT_DEC_RELEASE
RJMP C2_FIN

;INC C2 (PD7)
C2_CHECK_INC:
IN  R18, PIND
SBRS R18, 7
RJMP C2_INC_PRES
RJMP C2_FIN

C2_INC_PRES:
CALL ANTIREBOTE_DELAY
IN   R18, PIND
SBRS R18, 7
RJMP C2_INC_REAL
RJMP C2_FIN

C2_INC_REAL:
INC  R22
ANDI R22, 0x0F

C2_WAIT_INC_RELEASE:
IN   R18, PIND
SBRS R18, 7
RJMP C2_WAIT_INC_RELEASE

C2_FIN:
RET


; MOSTRAR C1 en PORTD[3:0] sin tocar botones [7:4]


MOSTRAR_C1_EN_PORTD:
IN   R16, PORTD
ANDI R16, 0b11110000
MOV  R17, R20
ANDI R17, 0x0F
OR   R16, R17
OUT  PORTD, R16
RET


; MOSTRAR C2 en PORTC[3:0] sin tocar PC4 (carry) ni PC5 (pull-up)


MOSTRAR_C2_EN_PORTC:
IN   R16, PORTC
ANDI R16, 0b11110000
MOV  R17, R22
ANDI R17, 0x0F
OR   R16, R17
OUT  PORTC, R16
RET

// BOTON SUMA (A5 / PC5) - CLICK:


BOTON_SUMA_MOSTRAR_EN_CLICK:

; Si PC5 está suelto (1) -> salir sin cambiar nada
IN   R19, PINC
SBRC R19, 5
RJMP FIN_SUMA
RJMP A5_PRESIONADO

A5_PRESIONADO:
; Antirebote
CALL ANTIREBOTE_DELAY
IN   R19, PINC
SBRC R19, 5              ; si se soltó durante antirebote entonces, salir
RJMP FIN_SUMA
RJMP CALCULAR_Y_MOSTRAR

CALCULAR_Y_MOSTRAR:
; Suma (0..30)
MOV  R24, R20
ADD  R24, R22

; Mostrar suma (5 bits) en PORTB (PB0..PB4)
MOV  R21, R24
ANDI R21, 0x1E
OUT  PORTB, R21

// CARRY de 4 bits = bit 4 del resultado (suma mayo o igual a 16)
SBRS R24, 4              ; si bit4=1 NO salta  enciende carry
RJMP SIN_CARRY_4BIT

SBI  PORTC, 4  // Carry ON
RJMP ESPERAR_SOLTAR_A5

SIN_CARRY_4BIT:
CBI  PORTC, 4 // Carry OFF

ESPERAR_SOLTAR_A5:

// Esperar a soltar para que 1 click = 1 acción
IN   R19, PINC
SBRC R19, 5
RJMP FIN_SUMA
RJMP ESPERAR_SOLTAR_A5

FIN_SUMA:
RET



ANTIREBOTE_DELAY:
LDI R26, 1

DELAY:
CLR R27

DLOOP:
INC R27
CPI R27, 0
BRNE DLOOP

DEC R26
BRNE DLOOP
RET
