/*
 * LibreriaTimer1PWM.c
 *
 * Created: 14/04/2026 23:03:55
 *  Author: luisg
 */ 


#include <avr/io.h>
#include "LibreriaTimer1PWM.h"

void init_timer1(void)
{
	// PB1 = OC1A, PB2 = OC1B como salida
	DDRB |= (1 << DDB1) | (1 << DDB2);

	// Fast PWM 8 bits
	TCCR1A = (1 << WGM10) |
	(1 << COM1A1) |
	(1 << COM1B1);

	TCCR1B = (1 << WGM12) |
	(1 << CS11); // prescaler 8

	OCR1A = 0;
	OCR1B = 0;
}

void TIMER1_PWM1_set_servo_PW(uint8_t value)
{
	OCR1A = value;
}

void TIMER1_PWM2_set_servo_PW(uint8_t value)
{
	OCR1B = value;
}