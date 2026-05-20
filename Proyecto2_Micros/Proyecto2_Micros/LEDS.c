/*
 * LEDS.c
 *
 *  Author: luisg
 */ 

#include <avr/io.h>
#include "LEDS.h"

void LEDS_Init(void)
{
	DDRC |= (1 << PC4) | (1 << PC5);
	DDRD |= (1 << PD7);

	LEDS_AllOff();
}

void LEDS_AllOff(void)
{
	PORTC &= ~((1 << PC4) | (1 << PC5));
	PORTD &= ~(1 << PD7);
}

void LEDS_SetMode(led_mode_t mode)
{
	LEDS_AllOff();

	if (mode == LED_MODE_MANUAL)
	{
		PORTC |= (1 << PC4);
	}
	else if (mode == LED_MODE_EEPROM)
	{
		PORTC |= (1 << PC5);
	}
	else if (mode == LED_MODE_UART)
	{
		PORTD |= (1 << PD7);
	}
}
