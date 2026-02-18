;
; Laboratorio2.asm
;
; Created: 11/02/2026 16:04:44
; Author : luisg


.include "m328pdef.inc"

.org 0x0000
    RJMP RESET

; RESET / INIT

RESET:

    ; Stack
    LDI  r16, high(RAMEND)
    OUT  SPH, r16
    LDI  r16, low(RAMEND)
    OUT  SPL, r16

    CLR  r1             

    ; UART OFF (UCSR0B es extendido  STS)
    CLR  r16
    STS  UCSR0B, r16

    ; PORTB PB0..PB3 como salida (LEDs)
    LDI  r16, 0x0F
    OUT  DDRB, r16

    ; Inicializar contador LEDs en R21
    CLR  r21

    ;Display 7seg en PORTD
    LDI  r16, 0b01111111     ; PD0..PD6 salida
    OUT  DDRD, r16
    LDI  r16, 0xFF           ; ánodo común: 1=apagado
    OUT  PORTD, r16

    ;Botones A0/A1 = PC0/PC1 
    ; Pull-up interno (botón a GND)
    SBI  PORTC, 0            ; A0 pull-up
    SBI  PORTC, 1            ; A1 pull-up

    CLR  r22                 ; contador HEX (0..F) para el display
    RCALL DISPLAY_7SEG       ; mostrar 0 al inicio

    ; Timer0 modo NORMAL
    CLR  r16
    OUT  TCCR0A, r16

    ; Prescaler = 1024
    LDI  r16, (1<<CS02) | (1<<CS00)
    OUT  TCCR0B, r16

    ; Preload = 0
    CLR  r16
    OUT  TCNT0, r16

    ; Limpiar bandera TOV0
    SBI  TIFR0, TOV0

    RJMP MAIN_LOOP

;-----------------------------
; MAIN LOOP
;-----------------------------
MAIN_LOOP:

    ; Botones para contador HEX (display)
    RCALL CHECK_BTNS

    ; Espera overflow Timer0 (para LEDs)
    RCALL WAIT_OVF

    ; Contador LEDs (R21) en PORTB
    INC     R21
    ANDI    R21, 0x0F
    OUT     PORTB, R21

    RJMP    MAIN_LOOP

;-----------------------------
; WAIT OVF Timer0 (sin interrupciones)
;-----------------------------
WAIT_OVF:
WAIT:
    IN     R16, TIFR0
    SBRS   R16, TOV0
    RJMP   WAIT
    SBI    TIFR0, TOV0
    RET

;-----------------------------
; Botones HEX (bloqueante por "wait release")
; A0 (PC0) -> INC
; A1 (PC1) -> DEC
;-----------------------------
CHECK_BTNS:
    IN   r18, PINC

    ; A0 presionado? (activo en 0)
    SBRS r18, 0
    RCALL HEX_INC

    ; A1 presionado? (activo en 0)
    IN   r18, PINC
    SBRS r18, 1
    RCALL HEX_DEC

    RET

HEX_INC:
REL0:
    IN   r18, PINC
    SBRS r18, 0
    RJMP REL0              ; esperar soltar A0

    INC  r22
    ANDI r22, 0x0F
    RCALL DISPLAY_7SEG
    RET

HEX_DEC:
REL1:
    IN   r18, PINC
    SBRS r18, 1
    RJMP REL1              ; esperar soltar A1

    DEC  r22
    ANDI r22, 0x0F
    RCALL DISPLAY_7SEG
    RET

;-----------------------------
; DISPLAY 7SEG (ánodo común)
; PD0=a ... PD6=g, 0=ON
; Usa r22 como índice 0..15
;-----------------------------
DISPLAY_7SEG:
    LDI  ZH, HIGH(TABLE7SEG<<1)
    LDI  ZL, LOW(TABLE7SEG<<1)

    ADD  ZL, r22
    ADC  ZH, r1

    LPM  r16, Z
    ORI  r16, 0x80        ; PD7=1 por si acaso
    OUT  PORTD, r16
    RET

;-----------------------------
; TABLA HEX 0..F (ánodo común)
; bits: PD0=a ... PD6=g (0=ON)
;-----------------------------
TABLE7SEG:
    .db 0x40,0x79,0x24,0x30,0x19,0x12,0x02,0x78  ; 0..7
    .db 0x00,0x10,0x08,0x03,0x46,0x21,0x06,0x0E  ; 8..F

