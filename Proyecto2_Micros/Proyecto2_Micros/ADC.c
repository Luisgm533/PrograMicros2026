#define F_CPU 16000000UL

#include <avr/io.h>
#include <stdint.h>
#include <util/delay.h>
#include "ADC.h"

void ADC_Init(void)
{
	ADMUX = (1 << REFS0);

	ADCSRA = (1 << ADEN)
	| (1 << ADPS2)
	| (1 << ADPS1)
	| (1 << ADPS0);

	DIDR0 = (1 << ADC0D)
	| (1 << ADC1D)
	| (1 << ADC2D)
	| (1 << ADC3D);
}

uint16_t ADC_Read(uint8_t channel)
{
	channel &= 0x07;

	ADMUX = (ADMUX & 0xF0) | channel;

	_delay_us(20);

	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));

	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));

	return ADC;
}