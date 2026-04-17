/*
 * LibreriaTimer1PWM.c
 *
 * Created: 14/04/2026 23:03:55
 *  Author: luisg
 */ 

#include <avr/io.h>
#include <stdint.h>
#include "LibreriaTimer1PWM.h"

void init_timer1(void)
{
	// D9 = PB1 = OC1A
	DDRB |= (1 << DDB1);

	TCCR1A = 0;
	TCCR1B = 0;

	// Fast PWM con TOP en ICR1
	TCCR1A |= (1 << COM1A1);
	TCCR1A |= (1 << WGM11);
	TCCR1B |= (1 << WGM13) | (1 << WGM12);

	// Prescaler 8
	TCCR1B |= (1 << CS11);

	// 20 ms
	ICR1 = 39999;

	// Centro inicial
	OCR1A = 3000;
}

void TIMER1_PWM1_set_servo_PW(uint8_t value)
{
	// Rango extendido: 500 us a 2500 us
	uint16_t pulso_us = 500 + (((uint32_t)value * 2000UL) / 255UL);
	OCR1A = pulso_us * 2;
}