/*
 * LibreriaADC.c
 *
 *  Author: luisg
 */ 


#include <avr/io.h>
#include <stdint.h>
#include "LibreriaADC.h"

void setup_adc(void)
{
	// AVcc, left adjust, canal 0
	ADMUX = (1 << REFS0) | (1 << ADLAR);

	// Enable ADC + interrupt + prescaler 128
	ADCSRA = (1 << ADEN) |
	(1 << ADIE) |
	(1 << ADPS2) |
	(1 << ADPS1) |
	(1 << ADPS0);
}

void adc_set_channel(uint8_t channel)
{
	channel &= 0x07;
	ADMUX = (ADMUX & 0xF8) | channel;
	}
