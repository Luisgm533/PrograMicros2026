; Lab3.asm
; Created: 18/02/2026 14:17:45
; Author : luisg
; Lab3.asm


.include "M328PDEF.inc"

.equ T0_PRESC     = (1<<CS02) | (1<<CS00)
.equ T0_PRELOAD   = 178
.equ OVF_PER_SEC  = 200
.equ STABLE_N     = 10

//ENABLES (activo-BAJO por ser cátodo común)
// PB4 para D1 (decenas)   PB5 para D2 (unidades)
.equ EN_TENS_BIT  = 4
.equ EN_UNITS_BIT = 5

.cseg
.org 0x0000
    RJMP RESET
.org PCI1addr
    RJMP PCINT1_ISR
.org OVF0addr
    RJMP T0_OVF_ISR

; ===========================================================
; TABLA 7SEG para CATODO COMUN (1=segmento ON)
; ===========================================================
.org 0x0100
TABLA7SEG:
    .db 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F

; ===========================================================
RESET:
    ; Stack
    LDI  R16, LOW(RAMEND)
    OUT  SPL, R16
    LDI  R16, HIGH(RAMEND)
    OUT  SPH, R16

    ; PORTB: PB0..PB3 LEDs, PB4 D1, PB5 D2
    LDI  R16, 0b00111111
    OUT  DDRB, R16
    CLR  R16
    OUT  PORTB, R16

    ; Apagar dígitos (activo-bajo - apagado=1)
    SBI  PORTB, EN_TENS_BIT
    SBI  PORTB, EN_UNITS_BIT

    ; Segmentos PD0 al PD6
    LDI  R16, 0b01111111
    OUT  DDRD, R16
    CLR  R16
    OUT  PORTD, R16

    ; Botones PC0/PC1 pull-up
    CLR  R16
    OUT  DDRC, R16
    LDI  R16, (1<<PC0) | (1<<PC1)
    OUT  PORTC, R16

    ; PCINT1 PC0/PC1
    LDI  R16, (1<<PCIE1)
    STS  PCICR, R16
    LDI  R16, (1<<PCINT8) | (1<<PCINT9)
    STS  PCMSK1, R16

    ; Timer0 overflow ~5ms
    CLR  R16
    OUT  TCCR0A, R16
    LDI  R16, T0_PRESC
    OUT  TCCR0B, R16
    LDI  R16, T0_PRELOAD
    OUT  TCNT0, R16
    LDI  R16, (1<<TOIE0)
    STS  TIMSK0, R16

    ; Registros:
    ; R20 CNT_LED (PB0 al PB3)
    ; R21 PREV_PINC
    ; R22 OVF_CNT
    ; R23 UNITS (0 al 9)
    ; R27 TENS  (0 al 5)
    ; R24/R25 debounce
    ; R26 flags botones
    ; R28 mux_state (0=unidades,1=decenas)

    CLR  R20
    IN   R21, PINC
    CLR  R22
    CLR  R23
    CLR  R27
    CLR  R24
    CLR  R25
    CLR  R26
    CLR  R28

    RCALL UPDATE_LEDS

    SEI
MAIN:
    RJMP MAIN

; LEDs sin pisar PB4/PB5
UPDATE_LEDS:
    IN   R16, PORTB
    ANDI R16, 0xF0    //conserva PB4..PB7
    MOV  R17, R20
    ANDI R17, 0x0F
    OR   R16, R17
    OUT  PORTB, R16
    RET

;Cargar 7seg de R16 (0 al 9)-
LOAD_7SEG_DIGIT:
    ; entrada: R16 = 0..9
    LDI  ZL, LOW(TABLA7SEG*2)
    LDI  ZH, HIGH(TABLA7SEG*2)
    ADD  ZL, R16
    CLR  R1
    ADC  ZH, R1
    LPM  R17, Z
    OUT  PORTD, R17
    RET

; Multiplexado
; R28=0 da unidades (D2), R28=1 da decenas (D1)


SHOW_2DIGITS:
    TST  R28
    BRNE SHOW_TENS

SHOW_UNITS:
    ; apagar ambos primero
    SBI  PORTB, EN_TENS_BIT
    SBI  PORTB, EN_UNITS_BIT

    ; cargar patrón unidades
    MOV  R16, R23
    RCALL LOAD_7SEG_DIGIT

    ; encender unidades (D2) con activo-bajo
    CBI  PORTB, EN_UNITS_BIT

    LDI  R28, 1
    RET

SHOW_TENS:
    SBI  PORTB, EN_TENS_BIT
    SBI  PORTB, EN_UNITS_BIT

    MOV  R16, R27
    RCALL LOAD_7SEG_DIGIT

    ; encender decenas (D1) => activo-bajo
    CBI  PORTB, EN_TENS_BIT

    CLR  R28
    RET

// PCINT botones
PCINT1_ISR:
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    IN   R17, PINC
    MOV  R16, R17
    EOR  R16, R21

    ; PC0 - INC
    SBRS R16, 0
    RJMP chk_dec
    SBR  R26, (1<<0)
    CLR  R24
chk_dec:
    ; PC1 - DEC
    SBRS R16, 1
    RJMP save_prev
    SBR  R26, (1<<1)
    CLR  R25
save_prev:
    MOV  R21, R17

    POP  R16
    OUT  SREG, R16
    POP  R17
    POP  R16
    RETI

// Timer0 OVF
T0_OVF_ISR:
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    ; recarga
    LDI  R16, T0_PRELOAD
    OUT  TCNT0, R16

    ; multiplex cada aprox  a los 5ms 
    RCALL SHOW_2DIGITS

    ; leer botones
    IN   R17, PINC

    ; debounce INC PC0
    SBRC R26, 0
    RJMP do_inc
    RJMP do_dec_part
do_inc:
    SBRS R17, 0
    RJMP inc_pressed
    CLR  R24
    CBR  R26, (1<<0)
    RJMP do_dec_part
inc_pressed:
    INC  R24
    CPI  R24, STABLE_N
    BRLO do_dec_part
    INC  R20
    ANDI R20, 0x0F
    RCALL UPDATE_LEDS
    CLR  R24
    CBR  R26, (1<<0)

do_dec_part:
    ; debounce DEC PC1
    SBRC R26, 1
    RJMP do_dec
    RJMP time_part
do_dec:
    SBRS R17, 1
    RJMP dec_pressed
    CLR  R25
    CBR  R26, (1<<1)
    RJMP time_part
dec_pressed:
    INC  R25
    CPI  R25, STABLE_N
    BRLO time_part
    DEC  R20
    ANDI R20, 0x0F
    RCALL UPDATE_LEDS
    CLR  R25
    CBR  R26, (1<<1)

time_part:
    ; 1 segundo
    INC  R22
    CPI  R22, OVF_PER_SEC
    BRLO t0_end
    CLR  R22

    ; POSTLAB: unidades 0..9
    INC  R23
    CPI  R23, 10
    BRLO t0_end

    CLR  R23
    INC  R27
    CPI  R27, 6
    BRLO t0_end

    ; 60s hay reset
    CLR  R27
    CLR  R23

t0_end:
    POP  R16
    OUT  SREG, R16
    POP  R17
    POP  R16
    RETI