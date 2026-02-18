
/**************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "m328pdef.inc"
.dseg
.org    SRAM_START

//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)
.cseg
.org 0x0000


 /**************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/**************/

	//TABLA
Tabla:
    .db 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E

/**************/
// Configuración MCU

SETUP:
    ldi ZH, high(Tabla<<1)
    ldi ZL, low(Tabla<<1)

	LDI r16, 0x00							; Habilito los pines 0 y 1 del puerto D.
	STS UCSR0B, r16

; PORTD como salida (display) 
    ldi R16, 0xFF
    out DDRD, R16

; Apagar display 
    ldi R16, 0xFF
    out PORTD, R16

; Botones PC0 y PC1 como entrada 
    cbi DDRC, PC0
    cbi DDRC, PC1

; Activar pull-ups
    sbi PORTC, PC0
    sbi PORTC, PC1

; Iniciar contador
    clr r18
    call DISPLAY

/**************/
;LOOP PRINCIPAL
MAIN:
    call suma
    call resta
    rjmp MAIN

/**************/
; BOTÓN INCREMENTAR (PC0)

suma:
    sbic PINC, PC0      ; si no está presionado, retornar 
    ret

    ldi r26, 1        ;antirebote
    call DELAY

    sbic PINC, PC0      ; confirmar que este presionado
    ret

    inc r18
    andi r18, 0x0F
    call DISPLAY

esperar_INC:				;para esperar a que se suelte el botón
    sbis PINC, PC0
	rjmp esperar_INC   
	ret
       

/**************/
; BOTÓN DECREMENTAR (PC1)
; lo mismo para suma pero cambiar inc por dec, y usar los registros que corresponden

resta:
    sbic PINC, PC1
    ret

    ldi r26, 1
    call DELAY

    sbic PINC, PC1
    ret

    dec r18
    andi r18, 0x0F
    call DISPLAY

esperar_DEC:
    sbis PINC, PC1
	rjmp esperar_DEC
	ret
    
/**************/
; ACTUALIZAR DISPLAY

DISPLAY:

    ; Cargar dirección tabla
    ldi ZH, high(Tabla<<1)
    ldi ZL, low(Tabla<<1)

	add ZL, r18

	lpm r20, Z     ;cargar el valor dentro de Z a r20 y sacarto por portD
	out PORTD, r20
	ret


/**************/
; DELAY PARA ANTIRREBOTE

DELAY:
    CLR R27                             ; Reset contador interno
DELAY_LOOP:
    INC R27                             ; Incrementa hasta overflow a 0
    CPI R27, 0                          ; Compara con 0 (se cumple al overflow)
    BRNE DELAY_LOOP                     ; Mientras no haya overflow, seguir
    DEC R26                             ; Reducir contador externo
    BRNE DELAY_LOOP                     ; Si aún no llega a 0, seguir
    RET