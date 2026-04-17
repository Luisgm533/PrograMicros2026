/*
 * LibreriaTimer2PWM.c
 *

 *  Author: luisg
 */ 
#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include "LibreriaTimer2PWM.h"

// ======================================
// VARIABLES GLOBALES
// ======================================
// Timer2 genera una interrupción cada 20 us
// Servo: periodo 20 ms = 1000 ticks de 20 us
volatile uint16_t servo2_high_ticks = 75;   // 1500 us / 20 us = 75
volatile uint8_t led_duty = 0;

// ======================================
// INICIALIZAR TIMER2
// D11 - Servo 2
// D3  . LED
// ======================================
void init_timer2_all(void)
{
	// D11 como salida
	DDRB |= (1 << PB3);
	PORTB &= ~(1 << PB3);

	// D3 como salida
	DDRD |= (1 << PD3);
	PORTD &= ~(1 << PD3);

	TCCR2A = 0;
	TCCR2B = 0;
	TCNT2  = 0;

	// Modo CTC
	TCCR2A |= (1 << WGM21);

	// Prescaler 8
	TCCR2B |= (1 << CS21);

	// 20 us por interrupción
	OCR2A = 39;

	// Interrupción por compare match A
	TIMSK2 |= (1 << OCIE2A);
}

// ======================================
// AJUSTAR SERVO 2
// 0-255 en 500 us a 2500 us
// 500 us / 20 us = 25 ticks
// 2500 us / 20 us = 125 ticks
// ======================================
void timer2_set_servo2(uint8_t value)
{
	servo2_high_ticks = 25 + (((uint32_t)value * 100UL) / 255UL);
}

// ======================================
// AJUSTAR LED
// ======================================
void timer2_set_led(uint8_t duty)
{
	led_duty = duty;
}

// ======================================
// ISR TIMER2 COMPARE MATCH A

// ======================================
ISR(TIMER2_COMPA_vect)
{
	static uint16_t servo_tick = 0;
	static uint8_t led_phase = 0;

	// =========================
	// SERVO 2 EN D11
	// 1000 ticks * 20 us = 20 ms
	// =========================
	if (servo_tick == 0)
	{
		PORTB |= (1 << PB3);   // Iniciar pulso
	}

	if (servo_tick >= servo2_high_ticks)
	{
		PORTB &= ~(1 << PB3);  // Terminar pulso
	}

	servo_tick++;
	if (servo_tick >= 1000)
	{
		servo_tick = 0;
	}

	// =========================
	// LED EN D3
	// =========================
	led_phase++;
	if (led_phase < led_duty)
	PORTD |= (1 << PD3);
	else
	PORTD &= ~(1 << PD3);
}