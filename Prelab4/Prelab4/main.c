
/*
 * Prelab4.c
 *
 * Author : luisg
 */ 

/*
 * Prelab4.c
 *
 * Author : luisg
 */

// LIBRERIAS
#include <avr/io.h>
#include <avr/interrupt.h>

volatile unsigned char contador = 0;
volatile unsigned char estado_prev_b;

// antirrebote corto
void antirrebote_corto(void)
{
	for (volatile unsigned int i = 0; i < 12000; i++);
}

int main(void)
{
	// =========================
	// CONFIGURACIÓN DE PUERTOS
	// =========================
	DDRB = 0x00;                         // PORTB como entradas
	PORTB = (1 << PB0) | (1 << PB1);     // Pull-up en PB0 y PB1

	DDRC |= (1 << PC1);                  // PC1 como salida
	PORTC |= (1 << PC1);                 // Encender PC1

	DDRD = 0xFF;                         // PORTD como salidas
	PORTD = contador;                    // mostrar contador inicial

	// guardar estado inicial de PORTB
	estado_prev_b = PINB;

	// =========================
	// INTERRUPCIONES PIN CHANGE
	// =========================
	PCMSK0 = (1 << PCINT0) | (1 << PCINT1); // PB0 y PB1
	PCICR  = (1 << PCIE0);                  // grupo PORTB

	sei();

	while (1)
	{
	}
}

ISR(PCINT0_vect)
{
	unsigned char estado_actual;
	unsigned char cambios;

	// pequeño debounce
	antirrebote_corto();

	// leer estado ya estabilizado
	estado_actual = PINB;

	// ver qué bits cambiaron respecto al último estado
	cambios = estado_prev_b ^ estado_actual;

	// si PB1 cambió y quedó en 0 -> botón PB1 presionado
	if ((cambios & (1 << PB1)) && !(estado_actual & (1 << PB1)))
	{
		contador++;
		PORTD = contador;
	}

	// si PB0 cambió y quedó en 0 -> botón PB0 presionado
	if ((cambios & (1 << PB0)) && !(estado_actual & (1 << PB0)))
	{
		contador--;
		PORTD = contador;
	}

	// actualizar referencia
	estado_prev_b = estado_actual;
}



