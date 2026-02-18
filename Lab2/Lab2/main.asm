.include "m328pdef.inc"

.cseg
.org 0x0000
    rjmp RESET

RESET:
    ; Stack
    ldi  r16, high(RAMEND)
    out  SPH, r16
    ldi  r16, low(RAMEND)
    out  SPL, r16

    clr  r1                 ; r1 = 0 (para ADC en punteros / LPM)

    ; -------- UART OFF --------
    clr  r16
    out  UCSR0B, r16         ; deshabilita RX/TX

    ; -------- LEDs del Timer (PORTB PB0..PB3) --------
    ldi  r16, 0x0F
    out  DDRB, r16
    clr  r21                 ; contador LEDs (independiente)

    ; -------- Display 7seg ánodo común en PORTD PD0..PD6 --------
    ldi  r16, 0b01111111     ; PD0..PD6 salida
    out  DDRD, r16

    ; TEST: encender TODOS los segmentos (ánodo común => ON = 0)
    ldi  r16, 0x00
    out  PORTD, r16
    rcall DELAY1S

    ; Apagar todos (OFF = 1)
    ldi  r16, 0xFF
    out  PORTD, r16

    ; -------- Botones en A0/A1 = PC0/PC1 (pull-up) --------
    sbi  PORTC, 0            ; A0 pull-up
    sbi  PORTC, 1            ; A1 pull-up

    clr  r22                 ; contador HEX 0..F
    rcall UPDATE_7SEG        ; mostrar 0

    ; -------- TIMER0 (modo normal, prescaler 1024) --------
    clr  r16
    out  TCCR0A, r16
    ldi  r16, (1<<CS02) | (1<<CS00)
    out  TCCR0B, r16

    clr  r16
    out  TCNT0, r16
    sbi  TIFR0, TOV0

MAIN_LOOP:
    ; leer botones y actualizar display hex
    rcall CHECK_BTNS

    ; tu contador por overflow (LEDs en PORTB)
    rcall WAIT_OVF
    inc  r21
    andi r21, 0x0F
    out  PORTB, r21

    rjmp MAIN_LOOP

;------------------------------------------------------------
WAIT_OVF:
W1:
    in   r16, TIFR0
    sbrs r16, TOV0
    rjmp W1
    sbi  TIFR0, TOV0
    ret

;------------------------------------------------------------
CHECK_BTNS:
    in   r18, PINC

    ; A0 (PC0) INC (activo en 0)
    sbrs r18, 0
    rcall HEX_INC

    ; A1 (PC1) DEC
    in   r18, PINC
    sbrs r18, 1
    rcall HEX_DEC
    ret

HEX_INC:
    rcall DEBOUNCE
REL0:
    in   r18, PINC
    sbrs r18, 0
    rjmp REL0
    inc  r22
    andi r22, 0x0F
    rcall UPDATE_7SEG
    ret

HEX_DEC:
    rcall DEBOUNCE
REL1:
    in   r18, PINC
    sbrs r18, 1
    rjmp REL1
    dec  r22
    andi r22, 0x0F
    rcall UPDATE_7SEG
    ret

DEBOUNCE:
    ldi  r19, 30
D1: ldi  r23, 255
D2: dec  r23
    brne D2
    dec  r19
    brne D1
    ret

;------------------------------------------------------------
; Tabla ánodo común (PD0=a ... PD6=g) 0=ON, 1=OFF
UPDATE_7SEG:
    ldi  ZH, high(SEG_TABLE<<1)
    ldi  ZL, low(SEG_TABLE<<1)
    add  ZL, r22
    adc  ZH, r1
    lpm  r16, Z
    ori  r16, 0x80          ; PD7 = 1
    out  PORTD, r16
    ret

SEG_TABLE:
    .db 0x40,0x79,0x24,0x30,0x19,0x12,0x02,0x78
    .db 0x00,0x10,0x08,0x03,0x46,0x21,0x06,0x0E

;------------------------------------------------------------
; Delay ~1s (crudo)
DELAY1S:
    ldi  r24, 25
L1: ldi  r25, 255
L2: ldi  r26, 255
L3: dec  r26
    brne L3
    dec  r25
    brne L2
    dec  r24
    brne L1
    ret