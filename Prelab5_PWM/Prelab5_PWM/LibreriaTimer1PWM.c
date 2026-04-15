/*
 * LibreriaTimer1PWM.c
 *
 *  Author: luisg
 */ 


#include <avr/io.h>
#include <stdint.h>
#include "LibreriaTimer1PWM.h"

// Servo típico:
// Periodo = 20 ms A 50 Hz
// Pulso = 1000 us a 2000 us aprox

void init_timer1_pwm_servo(void)
{
	// OC1A = PB1 = D9 como salida
	DDRB |= (1 << DDB1);

	// Fast PWM, TOP = ICR1
	TCCR1A = 0;
	TCCR1B = 0;

	TCCR1A |= (1 << COM1A1);               // PWM no invertido en OC1A
	TCCR1A |= (1 << WGM11);
	TCCR1B |= (1 << WGM13) | (1 << WGM12);

	// Prescaler = 8
	TCCR1B |= (1 << CS11);

	// F_CPU = 16 MHz
	// tick = 8 / 16 MHz = 0.5 us
	// 20 ms / 0.5 us = 40000 cuentas
	ICR1 = 39999;

	// Posición inicial al centro: 1500 us
	OCR1A = 3000;
}

void TIMER1_PWM1_set_servo_us(uint16_t pulse_us)
{
	// Limitar por seguridad
	if (pulse_us < 1000) pulse_us = 1000;
	if (pulse_us > 2000) pulse_us = 2000;

	// 1 cuenta = 0.5 us
	OCR1A = pulse_us * 2;
}

void TIMER1_PWM1_set_servo_adc(uint16_t adc_value)
{
	// Mapear 0-1023 a 1000-2000 us
	uint32_t pulse_us = 1000 + ((uint32_t)adc_value * 1000UL) / 1023UL;
	TIMER1_PWM1_set_servo_us((uint16_t)pulse_us);
}