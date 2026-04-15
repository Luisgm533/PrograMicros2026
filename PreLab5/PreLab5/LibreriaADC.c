/*
 * LibreriaADC.c
 *
 *  Author: luisg
 */ 


#include <avr/io.h>
#include "LibreriaADC.h"

void setup_adc(void)
{
	// Referencia AVcc, ADLAR = 1 (usar ADCH)
	ADMUX = (1 << REFS0) | (1 << ADLAR);

	// Prescaler 128 a 125 kHz (ideal)
	ADCSRA = (1 << ADEN)  |  // Enable ADC
	(1 << ADIE)  |  // Enable interrupt
	(1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

void adc_set_channel(uint8_t ch)
{
	ch &= 0x07;               // Solo 0–7
	ADMUX = (ADMUX & 0xF8) | ch;
}