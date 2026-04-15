/*
 * PreLab5.c
 *
 * Author : luisg
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include "LibreriaTimer1PWM.h"
#include "LibreriaADC.h"

// ======================================
// VARIABLES GLOBALES
// ======================================
volatile uint8_t adc_channel_actual = 0;
static uint8_t pin_pwm_manual = PD3;

// ======================================
// PROTOTIPOS
// ======================================
void init_timer0(void);
void init_timer2_pwm_manual(void);
void timer2_set_pwm(uint8_t duty);

// ======================================
// MAIN
// ======================================
int main(void)
{
	cli();

	setup_adc();               // ADC
	init_timer0();             // Trigger ADC
	init_timer1();             // PWM hardware
	init_timer2_pwm_manual();  // PWM manual

	sei();

	while (1)
	{
		// Todo ocurre en interrupciones
	}

	return 0;
}

// ======================================
// TIMER0 ? DISPARA ADC
// ======================================
void init_timer0(void)
{
	TCCR0A = 0;
	TCCR0B = 0;

	// Prescaler 64
	TCCR0B |= (1 << CS01) | (1 << CS00);

	TCNT0 = 0;

	// Enable overflow interrupt
	TIMSK0 |= (1 << TOIE0);
}

// ======================================
// TIMER2 ? PWM MANUAL
// ======================================
void init_timer2_pwm_manual(void)
{
	TCCR2A = 0;
	TCCR2B = 0;

	// Prescaler 8
	TCCR2B |= (1 << CS21);

	// Enable interrupts
	TIMSK2 |= (1 << TOIE2) | (1 << OCIE2A);

	// PD3 output
	DDRD |= (1 << pin_pwm_manual);

	// Inicialmente apagado
	PORTD &= ~(1 << pin_pwm_manual);
}

// Duty cycle
void timer2_set_pwm(uint8_t duty)
{
	OCR2A = 255 - duty;
}

// ======================================
// ISR TIMER0
// ======================================
ISR(TIMER0_OVF_vect)
{
	TCNT0 = 0;
	ADCSRA |= (1 << ADSC); // iniciar ADC
}

// ======================================
// ISR ADC (MULTIPLEXADO)
// ======================================
ISR(ADC_vect)
{
	uint8_t lectura_adc = ADCH;

	switch (adc_channel_actual)
	{
		case 0:
		TIMER1_PWM1_set_servo_PW(lectura_adc);
		adc_channel_actual = 1;
		adc_set_channel(1);
		break;

		case 1:
		TIMER1_PWM2_set_servo_PW(lectura_adc);
		adc_channel_actual = 2;
		adc_set_channel(2);
		break;

		case 2:
		timer2_set_pwm(lectura_adc);
		adc_channel_actual = 0;
		adc_set_channel(0);
		break;
	}
}

// ======================================
// TIMER2 ? APAGAR
// ======================================
ISR(TIMER2_OVF_vect)
{
	PORTD &= ~(1 << pin_pwm_manual);
}

// ======================================
// TIMER2 ? ENCENDER
// ======================================
ISR(TIMER2_COMPA_vect)
{
	PORTD |= (1 << pin_pwm_manual);
}