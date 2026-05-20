/*
 * USART.c
 *
 *  Author: luisg
 */ 


#define F_CPU 16000000UL

#include <avr/io.h>
#include <stdint.h>
#include <stdlib.h>
#include "USART.h"

void USART_Init(uint32_t baud)
{
	uint16_t ubrr = (F_CPU / 16 / baud) - 1;

	UBRR0H = (uint8_t)(ubrr >> 8);
	UBRR0L = (uint8_t)ubrr;

	UCSR0B = (1 << RXEN0) | (1 << TXEN0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

uint8_t USART_ReadChar(char *data)
{
	if (UCSR0A & (1 << RXC0))
	{
		*data = UDR0;
		return 1;
	}

	return 0;
}

void USART_SendChar(char data)
{
	while (!(UCSR0A & (1 << UDRE0)));

	UDR0 = data;
}

void USART_SendString(const char *str)
{
	while (*str)
	{
		USART_SendChar(*str++);
	}
}

uint8_t USART_ReadLine(char *buffer, uint8_t max_len)
{
	static uint8_t index = 0;
	char c;

	if (USART_ReadChar(&c))
	{
		if (c == '\n' || c == '\r')
		{
			buffer[index] = '\0';
			index = 0;
			return 1;
		}
		else
		{
			if (index < max_len - 1)
			{
				buffer[index++] = c;
			}
		}
	}

	return 0;
}

uint8_t USART_Parse4Values(char *buffer, uint16_t *a, uint16_t *b, uint16_t *c, uint16_t *d)
{
	char *ptr;

	*a = atoi(buffer);

	ptr = buffer;
	while (*ptr && *ptr != ',') ptr++;
	if (*ptr == '\0') return 0;
	*b = atoi(ptr + 1);

	ptr++;
	while (*ptr && *ptr != ',') ptr++;
	if (*ptr == '\0') return 0;
	*c = atoi(ptr + 1);

	ptr++;
	while (*ptr && *ptr != ',') ptr++;
	if (*ptr == '\0') return 0;
	*d = atoi(ptr + 1);

	return 1;
}