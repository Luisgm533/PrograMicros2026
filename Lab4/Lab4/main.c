/*
 * Lab4.c
 *
 * Created: 8/04/2026 15:59:58
 * Author : luisg
 */ 



// LIBRERIAS
#include <avr/io.h>
#include <avr/interrupt.h>

// VARIABLES GLOBALES
volatile unsigned char adc_val = 0;

// ======================================
// TABLA 7 SEGMENTOS HEXADECIMAL
// ======================================

void show_number(unsigned char num)
{
	unsigned char tabla[16] =
	{
		0x3F, // 0
		0x06, // 1
		0x5B, // 2
		0x4F, // 3
		0x66, // 4
		0x6D, // 5
		0x7D, // 6
		0x07, // 7
		0x7F, // 8
		0x6F, // 9
		0x77, // A
		0x7C, // b
		0x39, // C
		0x5E, // d
		0x79, // E
		0x71  // F
	};

	PORTD = tabla[num & 0x0F];
}

// ======================================
// NIBBLE ALTO Y BAJO
// ======================================
unsigned char high_nibble(unsigned char num)
{
	return (num >> 4) & 0x0F; // tomo el numero que este en num, lo corro 4 espacios y hago el and con 0X0F para limpiar los bits de cualquier residuo
}

unsigned char low_nibble(unsigned char num)
{
	return num & 0x0F;
}

// ======================================
// CONFIGURACION TIMER0
// MULTIPLEXADO
// ======================================


void setup_timer0(void)
{
	TCCR0A = 0x00; // Modo normal
	TCCR0B = (1 << CS01) | (1 << CS00); // Prescaler 64
	TCNT0 = 6; // Precarga
	TIMSK0 = (1 << TOIE0);  // Interrupcion overflow
}

// ======================================
// CONFIGURACION ADC
// ======================================

void setup_adc(void)
{
	ADMUX = (1 << REFS0) | (1 << ADLAR); // REFS0 nos da el voltaje de ref que es 5v 
	// REFS0 = referencia AVCC
	// ADLAR = ajuste a la izquierda
	// MUX = 0000 -> ADC0 (PC0)

	ADCSRA = (1 << ADEN)  | // Habilitar ADC
	         (1 << ADIE)  | // Interrupcion ADC
	         (1 << ADPS2) | // Prescaler 128
	         (1 << ADPS1) |
	         (1 << ADPS0);

	ADCSRA |= (1 << ADSC);  // Iniciar conversion
}

// ======================================
// MAIN
// ======================================


int main(void)
{
	// PORTC
	// PC0 = entrada ADC
	// PC1 = display 1
	// PC2 = display 2
	
	DDRC = (1 << PC1) | (1 << PC2);
	PORTC = 0x00;

	// PORTD = segmentos
	DDRD = 0xFF;
	PORTD = 0x00;

	setup_timer0();
	setup_adc();

	sei();

	while (1)
	{
	}
}

// ======================================
// ISR TIMER0
// DISPLAY 1 = NIBBLE ALTO
// DISPLAY 2 = NIBBLE BAJO
// ======================================


ISR(TIMER0_OVF_vect)
{
	static unsigned char mux = 0;

	TCNT0 = 6;

	// Apagar ambos displays
	PORTC &= ~((1 << PC1) | (1 << PC2));

	switch (mux)
	{
		case 0:
			show_number(high_nibble(adc_val));
			PORTC |= (1 << PC1);
			break;

		case 1:
			show_number(low_nibble(adc_val));
			PORTC |= (1 << PC2);
			break;
	}

	mux++;
	if (mux > 1)
	{
		mux = 0;
	}
}

// ======================================
// ISR ADC
// GUARDAR VALOR DE 8 BITS
// ======================================

ISR(ADC_vect)
{
	adc_val = ADCH;
	ADCSRA |= (1 << ADSC);   // Nueva conversion
}


