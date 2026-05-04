/*
 * ADC.c
 *
 */ 

#define F_CPU 16000000UL

#include "ADC.h"

void ADC_Init(void)
{
	ADMUX = (1 << REFS0);

	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);

	DIDR0 = (1 << ADC2D);
}

uint16_t ADC_Read(uint8_t channel)
{
	channel &= 0x07;

	ADMUX = (ADMUX & 0xF0) | channel | (1 << REFS0);

	ADCSRA |= (1 << ADSC);

	while (ADCSRA & (1 << ADSC))
	{
	}

	return ADC;
}

