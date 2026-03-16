;
; Lab3.asm
;
; Created: 18/02/2026 14:17:45
; Author : luisg
;



.include "M328PDEF.inc"

.equ T0_PRESC     = (1<<CS02) | (1<<CS00)
.equ T0_PRELOAD   = 178
.equ OVF_PER_SEC  = 200

; Debounce por estabilidad
.equ STABLE_N     = 10       // 10*5ms=50ms estable (subir a 12 si sigue rebotando)

.cseg
.org 0x0000
    RJMP RESET

.org PCI1addr    // PCINT1 (PORTC)
    RJMP PCINT1_ISR

.org OVF0addr   // Timer0 Overflow
    RJMP T0_OVF_ISR


.org 0x0100
TABLA7SEG:
    .db 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07
    .db 0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71


;===========================================================
;SETUP
;===========================================================
RESET:
    
    LDI  R16, LOW(RAMEND)
    OUT  SPL, R16
    LDI  R16, HIGH(RAMEND)
    OUT  SPH, R16

    // LEDs PB0..PB3 salida 
    LDI  R16, 0x0F
    OUT  DDRB, R16
    CLR  R16
    OUT  PORTB, R16

    // Display PD0..PD6 salida 
    LDI  R16, 0b01111111
    OUT  DDRD, R16
    CLR  R16
    OUT  PORTD, R16

    // Botones PC0/PC1 entrada + pull-up
    CLR  R16
    OUT  DDRC, R16
    LDI  R16, (1<<PC0) | (1<<PC1)
    OUT  PORTC, R16

    // PCINT1 habilitar PC0 y PC1 
    LDI  R16, (1<<PCIE1)
    STS  PCICR, R16
    LDI  R16, (1<<PCINT8) | (1<<PCINT9)
    STS  PCMSK1, R16

    // Timer0 Normal + prescaler 1024 + OVF int 
    CLR  R16
    OUT  TCCR0A, R16
    LDI  R16, T0_PRESC
    OUT  TCCR0B, R16

    LDI  R16, T0_PRELOAD
    OUT  TCNT0, R16

    LDI  R16, (1<<TOIE0)
    STS  TIMSK0, R16

	//REGISTROS
   
   
    CLR  R20 //CONTADOR DE LED
    CLR  R22 //OVF 
    CLR  R23 //contador hexa
    CLR  R24 //estabilidad de inc
    CLR  R25 //estabilidad en dec
    CLR  R26 //Flags
    IN   R21, PINC // Estado previo

    RCALL UPDATE_LEDS
    RCALL UPDATE_7SEG

    SEI

MAIN:
    RJMP MAIN


;===========================================================
; SUBRUTINA: actualizar LEDs PB0 AL PB3 con R20
;===========================================================
UPDATE_LEDS:
    MOV  R16, R20
    ANDI R16, 0x0F
    OUT  PORTB, R16
    RET


;===========================================================
; SUBRUTINA: actualizar Display 7seg con R23 (0 a F)
;===========================================================

UPDATE_7SEG:
    MOV  R16, R23
    ANDI R16, 0x0F

    LDI  ZL, LOW(TABLA7SEG*2)
    LDI  ZH, HIGH(TABLA7SEG*2)
    ADD  ZL, R16
    CLR  R1
    ADC  ZH, R1

    LPM  R17, Z
    OUT  PORTD, R17
    RET


;===========================================================
; ISR PCINT1: SOLO arma solicitudes
; R26 bit0=REQ_INC, bit1=REQ_DEC
;===========================================================


PCINT1_ISR:
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    IN   R17, PINC
    MOV  R16, R17
    EOR  R16, R21 // bits que cambiaron

    // PC0 cambió a pedir INC
    SBRS R16, 0
    RJMP chk_dec
    SBR  R26, (1<<0)
    CLR  R24

chk_dec:
    // PC1 cambió a pedir DEC
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


;===========================================================
; - Debounce por estabilidad
; - Cada 200 OVFs es 1 segundo entonces incrementa display (R23)
;===========================================================
T0_OVF_ISR:
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    // Recarga
    LDI  R16, T0_PRELOAD
    OUT  TCNT0, R16

    // Leer botones (pull-up: presionado=0)
    IN   R17, PINC

    //Debounce INC (PC0)
    SBRC R26, 0
    RJMP do_inc_check
    RJMP dec_part

do_inc_check:
    SBRS R17, 0   // PC0=0 presionado?
    RJMP inc_pressed
    CLR  R24
    CBR  R26, (1<<0)
    RJMP dec_part

inc_pressed:
    INC  R24
    CPI  R24, STABLE_N
    BRLO dec_part

    INC  R20
    ANDI R20, 0x0F
    RCALL UPDATE_LEDS
    CLR  R24
    CBR  R26, (1<<0)

    // Debounce DEC (PC1) 
dec_part:
    SBRC R26, 1
    RJMP do_dec_check
    RJMP time_part

do_dec_check:
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

    // tiempo en el diplsy (1 segundo)
time_part:
    INC  R22
    CPI  R22, OVF_PER_SEC
    BRLO t0_end

    CLR  R22
    INC  R23
    ANDI R23, 0x0F
    RCALL UPDATE_7SEG

t0_end:
    POP  R16
    OUT  SREG, R16
    POP  R17
    POP  R16
    RETI