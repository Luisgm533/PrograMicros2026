/*
 * SERVO_PWM.c
 *
 *  Author: luisg
 */ 


#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include "SERVO_PWM.h"

static volatile uint16_t servo_pulse[4] = {1500, 1500, 1500, 1500};
static volatile uint8_t servo_actual = 0;

void SERVO_Init(void)
{
	DDRB |= (1 << PB1) | (1 << PB2) | (1 << PB3) | (1 << PB4);

	PORTB &= ~((1 << PB1) | (1 << PB2) | (1 << PB3) | (1 << PB4));

	TCCR1A = 0;
	TCCR1B = 0;

	TCCR1B |= (1 << WGM12);
	TCCR1B |= (1 << CS11);

	OCR1A = 40000;
	TIMSK1 |= (1 << OCIE1A);

	sei();
}

void SERVO_Set_us(uint8_t servo, uint16_t pulse_us)
{
	if (servo > 3) return;

	if (pulse_us < 1000) pulse_us = 1000;
	if (pulse_us > 2000) pulse_us = 2000;

	servo_pulse[servo] = pulse_us;
}

ISR(TIMER1_COMPA_vect)
{
	PORTB &= ~((1 << PB1) | (1 << PB2) | (1 << PB3) | (1 << PB4));

	if (servo_actual == 0)
	{
		PORTB |= (1 << PB1);
		OCR1A = servo_pulse[0] * 2;
	}
	else if (servo_actual == 1)
	{
		PORTB |= (1 << PB2);
		OCR1A = servo_pulse[1] * 2;
	}
	else if (servo_actual == 2)
	{
		PORTB |= (1 << PB3);
		OCR1A = servo_pulse[2] * 2;
	}
	else if (servo_actual == 3)
	{
		PORTB |= (1 << PB4);
		OCR1A = servo_pulse[3] * 2;
	}
	else
	{
		OCR1A = 24000;
	}

	servo_actual++;

	if (servo_actual > 4)
	{
		servo_actual = 0;
	}
}