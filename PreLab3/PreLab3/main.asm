;
; PreLab3.asm
;
; Created: 18/02/2026 13:23:07
; Author : luisg
;

; PreLab3_v2.asm
; Variante del original + debounce más fuerte en A1 (PC1)

.include "M328PDEF.inc"

.equ LED_MASK   = 0x0F
.equ BTN_INC    = 0           ; PC0
.equ BTN_DEC    = 1           ; PC1

.dseg
.org SRAM_START
; (sin variables en SRAM)

.cseg
.org 0x0000
    rjmp INIT

.org PCI1addr
    rjmp PCINT1_ISR

;=========================================================
; INIT / SETUP
;=========================================================
INIT:
    ; Stack
    ldi   r16, low(RAMEND)
    out   SPL, r16
    ldi   r16, high(RAMEND)
    out   SPH, r16

    ; Reloj a 1 MHz (16MHz / 16)
    ldi   r16, (1<<CLKPCE)
    sts   CLKPR, r16
    ldi   r16, 0b00000100
    sts   CLKPR, r16

    ; LEDs: PB0..PB3 salida
    ldi   r16, LED_MASK
    out   DDRB, r16
    clr   r16
    out   PORTB, r16

    ; Botones: PC0 y PC1 entrada con pull-up
    clr   r16
    out   DDRC, r16
    ldi   r16, 0b00000011
    out   PORTC, r16

    ; PCINT1: habilitar grupo y máscara para PCINT8 (PC0) y PCINT9 (PC1)
    ldi   r16, (1<<PCIE1)
    sts   PCICR, r16
    ldi   r16, (1<<PCINT8)|(1<<PCINT9)
    sts   PCMSK1, r16

    ; Contador y estado previo
    clr   r20                 ; contador 0..15
    in    r21, PINC           ; estado previo de botones

    sei

MAIN:
    rjmp MAIN

;=========================================================
; PCINT1 ISR
;=========================================================
PCINT1_ISR:
    push  r16
    push  r17
    push  r18
    push  r19
    in    r16, SREG
    push  r16

    in    r17, PINC           ; r17 = estado actual
    mov   r16, r17
    eor   r16, r21            ; r16 = bits que cambiaron (1 = cambió)


    sbrs  r16, BTN_INC        ; si NO cambió PC0 - saltar inc_check
    rjmp  inc_check_done
    sbrs  r17, BTN_INC        ; pull-up: si está en 1 - no está presionado
    inc   r20
inc_check_done:

    
    sbrs  r16, BTN_DEC        ; si NO cambió PC1 - saltar dec_check
    rjmp  dec_check_done
    sbrs  r17, BTN_DEC        ; si está en 1 => no presionado
    rcall debounce_pc1_press  ; confirma que sigue presionado tras delay


dec_check_done:

    ; Mostrar nibble en LEDs
    andi  r20, LED_MASK
    out   PORTB, r20

    ; actualizar estado previo
    mov   r21, r17

    pop   r16
    out   SREG, r16
    pop   r19
    pop   r18
    pop   r17
    pop   r16
    reti




debounce_pc1_press:
    
    rcall delay_ms_like

    
    in    r18, PINC
    sbrc  r18, BTN_DEC       
    ret                       
    dec   r20
    ret


delay_ms_like:
    
    ldi   r18, 90
dly1:
    ldi   r19, 255
dly2:
    dec   r19
    brne  dly2
    dec   r18
    brne  dly1
    ret