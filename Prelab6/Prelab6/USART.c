/*
 * USART.c
 *
 *  Author: luisg
 */ 

#define F_CPU 16000000UL

#include "USART.h"

void USART_Init(unsigned long baudrate)
{
	uint16_t ubrr;

	ubrr = (uint16_t)((F_CPU / (16UL * baudrate)) - 1UL);

	UBRR0H = (uint8_t)(ubrr >> 8);
	UBRR0L = (uint8_t)ubrr;

	UCSR0A = 0x00;
	UCSR0B = (1 << RXEN0) | (1 << TXEN0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

uint8_t USART_ReadChar(char *data)
{
	if (!(UCSR0A & (1 << RXC0)))
	{
		return 0;
	}

	*data = UDR0;
	return 1;
}

uint8_t USART_SendChar(char data)
{
	if (!(UCSR0A & (1 << UDRE0)))
	{
		return 0;
	}

	UDR0 = data;
	return 1;
}