/*
 * Prelab6.c
 *
 * Author : luisg
 */ 

#define F_CPU 16000000UL

#include <avr/io.h>
#include "USART.h"

int main(void)
{
	char dato;

	// Configurar PORTB como salida (LEDs)
	DDRB = 0xFF;
	PORTB = 0x00;

	// Inicializar USART
	USART_Init(9600);

	while (1)
	{
		// ?? PARTE 1: enviar caracter a la PC
		USART_SendChar('A');

		// ?? PARTE 2: recibir caracter y mostrarlo en PORTB
		if (USART_ReadChar(&dato))
		{
			PORTB = dato;
		}
	}
}

