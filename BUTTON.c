/*
 * BUTTON.c
 *
 *  Author: luisg
 */ 



#include <avr/io.h>
#include <util/delay.h>
#include <stdint.h>
#include "BUTTON.h"

void BUTTON_Init(void)
{
	DDRD &= ~(1 << PD2);
	PORTD |= (1 << PD2);
}

uint8_t BUTTON_SavePressed(void)
{
	if (!(PIND & (1 << PD2)))
	{
		_delay_ms(30);

		if (!(PIND & (1 << PD2)))
		{
			while (!(PIND & (1 << PD2)));
			return 1;
		}
	}

	return 0;
}