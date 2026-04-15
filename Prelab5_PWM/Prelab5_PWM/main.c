/*
 * Prelab5_PWM.c
 *
 * Author : luisg
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include "LibreriaTimer1PWM.h"

// ======================================
// PROTOTIPOS
// ======================================
void setup_adc(void);

// ======================================
// MAIN
// ======================================
int main(void)
{
	cli();

	setup_adc();
	init_timer1_pwm_servo();

	sei();

	while (1)
	{
		// Todo ocurre en el loop principal:
		// leer ADC y actualizar servo
		ADCSRA |= (1 << ADSC);              // Iniciar conversión
		while (ADCSRA & (1 << ADSC));       // Esperar fin de conversión

		uint16_t adc_val = ADC;             // 10 bits: 0 a 1023
		TIMER1_PWM1_set_servo_adc(adc_val); // Mapear ADC a pulso de servo
	}
}

// ======================================
// CONFIGURACIÓN ADC
// ======================================
void setup_adc(void)
{
	// Referencia AVcc, canal ADC0
	ADMUX = (1 << REFS0);

	// Habilitar ADC, prescaler 128
	ADCSRA = (1 << ADEN)  |
	(1 << ADPS2) |
	(1 << ADPS1) |
	(1 << ADPS0);
}
