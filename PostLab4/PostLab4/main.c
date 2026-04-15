/*
 * PostLab4.c
 *
 * Author : luisg
 */ 


// LIBRERIAS
#include <avr/io.h>
#include <avr/interrupt.h>

// VARIABLES GLOBALES
volatile unsigned char contador = 0;
volatile unsigned char adc_val = 0;
volatile unsigned char estado_prev_b = 0xFF;


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

	// conservar PD7 porque ahora es un LED del contador
	PORTD = (PORTD & (1 << PD7)) | tabla[num & 0x0F];
}

// ======================================
// NIBBLE ALTO Y BAJO
// ======================================
unsigned char high_nibble(unsigned char num)
{
	return (num >> 4) & 0x0F;
}

unsigned char low_nibble(unsigned char num)
{
	return num & 0x0F;
}

// ======================================
// ANTIRREBOTE SIMPLE
// ======================================
void antirrebote_corto(void)
{
	for (volatile unsigned int i = 0; i < 12000; i++);
}

// ======================================
// ACTUALIZAR LEDs DEL CONTADOR
// bits 0..3 - PB2..PB5
// bits 4..6 - PC0, PC4, PC5
// bit 7     - PD7
// ======================================
void update_counter_leds(unsigned char valor)
{
	// limpiar PB2..PB5
	PORTB &= ~((1 << PB2) | (1 << PB3) | (1 << PB4) | (1 << PB5));

	// limpiar PC0, PC4, PC5
	PORTC &= ~((1 << PC0) | (1 << PC4) | (1 << PC5));

	// limpiar PD7
	PORTD &= ~(1 << PD7);

	// bits 0..3
	if (valor & (1 << 0)) PORTB |= (1 << PB2);
	if (valor & (1 << 1)) PORTB |= (1 << PB3);
	if (valor & (1 << 2)) PORTB |= (1 << PB4);
	if (valor & (1 << 3)) PORTB |= (1 << PB5);

	// bits 4..6
	if (valor & (1 << 4)) PORTC |= (1 << PC0);
	if (valor & (1 << 5)) PORTC |= (1 << PC4);
	if (valor & (1 << 6)) PORTC |= (1 << PC5);

	// bit 7
	if (valor & (1 << 7)) PORTD |= (1 << PD7);
}

// ======================================
// ACTUALIZAR ALARMA
// PC3 = LED alarma
// ======================================
void update_alarm(void)
{
	if (adc_val > contador)
	{
		PORTC |= (1 << PC3);
	}
	else
	{
		PORTC &= ~(1 << PC3);
	}
}

// ======================================
// TIMER0 PARA MULTIPLEXADO
// ======================================
void setup_timer0(void)
{
	TCCR0A = 0x00;
	TCCR0B = (1 << CS01) | (1 << CS00); // prescaler 64
	TCNT0 = 6;
	TIMSK0 = (1 << TOIE0);
}

// ======================================
// ADC EN ADC6 / A6
// ======================================
void setup_adc(void)
{
	ADMUX = (1 << REFS0) | (1 << ADLAR) | (1 << MUX2) | (1 << MUX1);
	// AVCC, ajuste izquierda, ADC6

	ADCSRA = (1 << ADEN)  |
	         (1 << ADIE)  |
	         (1 << ADPS2) |
	         (1 << ADPS1) |
	         (1 << ADPS0);

	ADCSRA |= (1 << ADSC);
}

// ======================================
// MAIN
// ======================================
int main(void)
{
	// PORTB
	// PB0, PB1 = botones
	// PB2..PB5 = LEDs contador
	DDRB = (1 << PB2) | (1 << PB3) | (1 << PB4) | (1 << PB5);
	PORTB = (1 << PB0) | (1 << PB1);

	// PORTC
	// PC0, PC4, PC5 = LEDs contador
	// PC1, PC2 = displays
	// PC3 = alarma
	DDRC = (1 << PC0) | (1 << PC1) | (1 << PC2) | (1 << PC3) | (1 << PC4) | (1 << PC5);
	PORTC = 0x00;

	// PORTD
	// PD0..PD6 = segmentos
	// PD7 = bit 7 del contador
	DDRD = 0xFF;
	PORTD = 0x00;

	estado_prev_b = PINB;

	update_counter_leds(contador);
	update_alarm();

	setup_timer0();
	setup_adc();

	PCMSK0 = (1 << PCINT0) | (1 << PCINT1);
	PCICR  = (1 << PCIE0);

	sei();

	while (1)
	{
	}
}

// ======================================
// ISR BOTONES
// ======================================
ISR(PCINT0_vect)
{
	unsigned char estado_actual;
	unsigned char cambios;

	antirrebote_corto();

	estado_actual = PINB;
	cambios = estado_prev_b ^ estado_actual;

	if ((cambios & (1 << PB1)) && !(estado_actual & (1 << PB1)))
	{
		contador++;
		update_counter_leds(contador);
		update_alarm();
	}

	if ((cambios & (1 << PB0)) && !(estado_actual & (1 << PB0)))
	{
		contador--;
		update_counter_leds(contador);
		update_alarm();
	}

	estado_prev_b = estado_actual;
}

// ======================================
// ISR TIMER0
// DISPLAY 1 = nibble alto ADC
// DISPLAY 2 = nibble bajo ADC
// ======================================
ISR(TIMER0_OVF_vect)
{
	static unsigned char mux = 0;

	TCNT0 = 6;

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
// ======================================
ISR(ADC_vect)
{
	unsigned char valor = ADCH;

	if (valor < 5)
	{
		valor = 0;
	}

	if (valor > 250)
	{
		valor = 255;
	}

	adc_val = valor;
	update_alarm();

	ADCSRA |= (1 << ADSC);
}