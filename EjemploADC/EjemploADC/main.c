/*
 * EjemploADC.c
 *
 * Created: 19/03/2026 15:44:31
 * Author : luisg
 */ 


// Encabezado (Libraries)

#include <avr/io.h>
#include <avr/interrupt.h>

/****************************************/
// Function prototypes

/****************************************/
// Function prototypes

/****************************************/
// Main Function

int main(void)
{
	
	cli();
	setup();
	
	initADC();


	ADCSRA |= (1<<ADSC) | (1<<ADIE); // AQUI INICIA EL ADC	
	

	sei();
	while (1)
	{
	}
}

/****************************************/
// NON-Interrupt subroutines

void setup();
{
	// 1MHz de reloj
	CLKPR = (1<<CLKPCE);
	CLKPR = (1<<CLKPS2);
	
	// Configurar Salidas (DDRD)
	
	DDRD = 0xFF; // PORTD COMO SALIDA
	PORTD = 0X00; // TODO EL PORTD APAGADO
	UCSR0B = 0x00; // APAGAR TODO
	
}
void initADC(); 

{
		ADMUX = 0; // todos los bits en 0
		
		// Vref = AVcc, justificacion a la izquierda y usanmos el ADC 6
		
		ADMUX |=  (1<<REFS0) | (1<<ADLAR) | (1<<MUX2) | (1<<MUX1);
		
		ADCSRA = 0;
		ADCSRA |=  (1<<ADEN) | (1<<ADPS1) | (1<<ADPS0);	
	
}
/****************************************/
// Interrupt routines

ISR(ADC_vect);
{
	
	PORTD = ADCH;
	ADCSRA |= (1<<ADSC);
	
	
	
}





