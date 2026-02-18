.include "M328PDEF.inc"

/**************/
.cseg
.org 0x0000

/**************/
/* CONFIGURACIÓN DE LA PILA */

RESET:
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16

//STACKPOINTER

TABLE7SEG:
    .db     0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71  // 0 - F

/**************/
/* SETUP */

    LDI     R16, 0b00011111    // Definimos entradas y salidas en PORTB
    OUT     DDRB, R16

    LDI     R16, 0b00000000    // Definimos entradas y salidas en PORTC
    OUT     DDRC, R16

	LDI     R16, 0b11111111    // Definimos entradas y salidas en PORTD
	OUT     DDRD, R16

	LDI     R16, 0b00011111    // Activamos las salida de las LEDs
	OUT     PORTB, R16 

    SBI     PORTC, PC0         // ACTIVAMOS PULL UP BOTON 1
    SBI     PORTC, PC1         // ACTIVAMOS PULL UP BOTON 2 

	LDI     R16, 0b11111111    // Activamos las salidas de las LEDs para display 
	OUT     PORTD, R16 

    CLR     R21                // CONTADOR  A UTILIZAR PARA DISPLAY
	CLR     R22                // CONTADOR DE OVERFLOW
	CLR     R23                // CONTADOR LEDs SECUENCIA 1s

	LDI     R16, 0x00          // APAGAMOS LA COMUNICACION SERIAL DE PINEB
	STS     UCSR0B, R16 

	LDI		R16, (1<<CLKPCE)   // MODIFICAMOS EL PRESCALER A 1MHZ
    STS		CLKPR, R16
    LDI		R16, 0b00000100
    STS		CLKPR, R16

	LDI     R16, (1<<CS02)    // TIMER 0 (256 PRESCALER)
    OUT     TCCR0B, R16

	LDI     ZH,  HIGH (TABLE7SEG<<1)
	LDI     ZL,  LOW  (TABLE7SEG<<1)

	LDI     R16, 0x00
	OUT     PORTD, R16

/**************/
/* LOOP PRINCIPAL */

MAIN_LOOP:

    RCALL   WAIT_OVF
	
	INC     R22
	CPI     R22, 15    
    BRNE    SEGUNDO 

	CLR     R22
	INC     R23
	ANDI    R23, 0x0F

SEGUNDO:
    RCALL   CONTINUAR 
	IN      R20, PINC

    SBRS    R20, 0
    RCALL   SUMAR

    SBRS    R20, 1
    RCALL   RESTAR

    RCALL   DISPLAY

	RCALL   VERIFICACION 

    RJMP    MAIN_LOOP


CONTINUAR:
    IN      R16, PORTB        ; Leer estado actual
    ANDI    R16, 0x10          ; Conservar PB4
    OR      R16, R23          ; Combinar con LEDs contador
    OUT     PORTB, R16
	RET

WAIT_OVF:
WAIT:
    IN      R16, TIFR0
    SBRS    R16, TOV0
    RJMP    WAIT
    SBI     TIFR0, TOV0
	RET

VERIFICACION:
    CP      R23, R21
	BREQ    COMPARACION 
	RET
	  

// SUBRUTINAS 

SUMAR:             
    INC     R21                  // INCREMENTAMOS REGISTRO 
    ANDI    R21, 0x0F            // LIMITAMOS EL CONTADOR CON LOS 4 ULTIMOS BITS
    RCALL   DELAY           
ESPERA_PC0:
    IN      R20, PINC            // LEEMOS NUEVAMENTE PINC 
    SBRS    R20, 0               //  PC0 ESTA EN 0 
    RJMP    ESPERA_PC0       
    RET

RESTAR:
    DEC     R21
    ANDI    R21, 0x0F
    RCALL   DELAY
ESPERA_PC1:
    IN      R20, PINC
    SBRS    R20, 1
    RJMP    ESPERA_PC1
    RET


DISPLAY:
    LDI     ZH, HIGH(TABLE7SEG<<1)
    LDI     ZL, LOW(TABLE7SEG<<1)

    ADD     ZL, R21
    CLR     R1
    ADC     ZH, R1

    LPM     R20, Z
    OUT     PORTD, R20
    RET

COMPARACION:

    IN      R16, PORTB
    LDI     R17, (1<<PB4)
    EOR     R16, R17
    OUT     PORTB, R16
    CLR     R23
    RET
	
DELAY:
    LDI     R18, 255
D1:
    LDI     R19, 255
D2:
    DEC     R19
    BRNE    D2
    DEC     R18
    BRNE    D1
    RET