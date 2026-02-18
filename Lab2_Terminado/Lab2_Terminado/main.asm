;
; Lab2_Terminado.asm
;
; Author : luisg
;


// Luis Guerra
// Laboratorio 2 de Progra de Micros 2026

.include "M328PDEF.inc"

.cseg
.org 0x0000
    rjmp RESET

RESET:
    ldi     R16, low(RAMEND) // stack low
    out     SPL, R16
    ldi     R16, high(RAMEND) // stack high
    out     SPH, R16
    rjmp    SETUP // saltar setup

TABLA7SEG:
    .db 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07
    .db 0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

SETUP:
    ldi     R16,0b00011111 // PB0..PB4 salidas
    out     DDRB,R16

    ldi     R16,0x00 // botones entrada
    out     DDRC,R16

    ldi     R16,0xFF // display salida
    out     DDRD,R16

    sbi     PORTC,PC0 // pullup PC0
    sbi     PORTC,PC1 // pullup PC1

    ldi     R16,0x00  // limpiar display
    out     PORTD,R16

    clr     R21  // valor display
    clr     R22 // overflows
    clr     R23 // contador leds


	// off UART

    ldi     R16,0x00             
    sts     UCSR0B,R16


	// prescaler clk

    ldi     R16,(1<<CLKPCE)      
    sts     CLKPR,R16
    ldi     R16,0b00000100
    sts     CLKPR,R16

	// timer0 /256

    ldi     R16,(1<<CS02)        
    out     TCCR0B,R16

	// PB0..PB4 ON

    ldi     R16,0b00011111       
    out     PORTB,R16

MAIN_LOOP:
    rcall   EsperarOverflow

    inc     R22    // sumar overflow
    cpi     R22,15
    brne    LeerEntradas

    clr     R22     // reset ovf
    inc     R23  // sumar "seg"
    andi    R23,0x0F

LeerEntradas:
    rcall   ActualizarLEDs   // PB0..PB3=R23

    in      R20,PINC  // leer botones

    sbrs    R20,0   // PC0 pres?
    rcall   Subir

    sbrs    R20,1 // PC1 pres?
    rcall   Bajar

    rcall   Mostrar  // display

    rcall   CompararYToggle    // LED si iguales

    rjmp    MAIN_LOOP

EsperarOverflow:
EO_1:
    in      R16,TIFR0
    sbrs    R16,TOV0
    rjmp    EO_1
    sbi     TIFR0,TOV0
    ret

ActualizarLEDs:
    in      R16,PORTB
    andi    R16,0x10  // conservar PB4
    mov     R17,R23
    andi    R17,0x0F
    or      R16,R17
    out     PORTB,R16
    ret

Subir:
    inc     R21
    andi    R21,0x0F
    rcall   Retardo

SUELTA0:
    in      R20,PINC
    sbrs    R20,0
    rjmp    SUELTA0
    ret

Bajar:
    dec     R21
    andi    R21,0x0F
    rcall   Retardo

SUELTA1:
    in      R20,PINC
    sbrs    R20,1
    rjmp    SUELTA1
    ret

Mostrar:
    ldi     ZH,high(TABLA7SEG<<1)
    ldi     ZL,low(TABLA7SEG<<1)
    add     ZL,R21
    clr     R1
    adc     ZH,R1
    lpm     R20,Z
    out     PORTD,R20
    ret

CompararYToggle:
    cp      R23,R21
    brne    CYT_fin
    in      R16,PORTB
    ldi     R17,(1<<PB4)
    eor     R16,R17
    out     PORTB,R16
    clr     R23
CYT_fin:
    ret

Retardo:
    ldi     R18,255
R1_:
    ldi     R19,255
R2_:
    dec     R19
    brne    R2_
    dec     R18
    brne    R1_
    ret
