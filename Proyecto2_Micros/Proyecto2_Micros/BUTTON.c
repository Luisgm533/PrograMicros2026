/*
 * BUTTON.c
 *
 *  Author: luisg
 */ 


/*
 * BUTTON.c
 *
 *  Author: luisg
 */

#include <avr/io.h>       // Librería para manejar registros del ATmega328P
#include <util/delay.h>   // Librería para usar delays
#include <stdint.h>       // Librería para tipos de datos estándar
#include "BUTTON.h"       // Librería propia del botón

void BUTTON_Init(void)
{
	DDRD &= ~(1 << PD2); // Configura PD2 como entrada

	PORTD |= (1 << PD2); // Activa la resistencia pull-up interna en PD2
}

uint8_t BUTTON_SavePressed(void)
{
	// Verifica si el botón fue presionado
	// Como tiene pull-up, presionado = LOW

	if (!(PIND & (1 << PD2)))
	{
		_delay_ms(30); // Delay para eliminar rebote del botón

		// Verifica nuevamente después del debounce
		if (!(PIND & (1 << PD2)))
		{
			// Espera hasta que el botón sea soltado
			while (!(PIND & (1 << PD2)));

			return 1; // Retorna 1 si el botón fue presionado correctamente
		}
	}

	return 0; // Retorna 0 si no hubo presión válida
}