/*
 * USART.c
*/

#define F_CPU 16000000UL

#include "USART.h"
#include <avr/interrupt.h>

static volatile char rxQueue[USART_RX_BUFFER_SIZE];
static volatile uint8_t rxWrite = 0;
static volatile uint8_t rxRead = 0;

static volatile char txQueue[USART_TX_BUFFER_SIZE];
static volatile uint8_t txWrite = 0;
static volatile uint8_t txRead = 0;

void USART_Init(unsigned long baud)
{
	uint16_t baud_reg;

	baud_reg = (uint16_t)((F_CPU / (16UL * baud)) - 1UL);

	UBRR0H = (uint8_t)(baud_reg >> 8);
	UBRR0L = (uint8_t)(baud_reg);

	UCSR0A = 0x00;
	UCSR0B = (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

uint8_t USART_DataReady(void)
{
	if (rxWrite == rxRead)
	{
		return 0;
	}
	return 1;
}

uint8_t USART_GetChar(char *dato)
{
	if (rxWrite == rxRead)
	{
		return 0;
	}

	*dato = rxQueue[rxRead];
	rxRead = (uint8_t)((rxRead + 1U) % USART_RX_BUFFER_SIZE);

	return 1;
}

uint8_t USART_PutChar(char dato)
{
	uint8_t siguiente;

	siguiente = (uint8_t)((txWrite + 1U) % USART_TX_BUFFER_SIZE);

	if (siguiente == txRead)
	{
		return 0;
	}

	txQueue[txWrite] = dato;
	txWrite = siguiente;

	UCSR0B |= (1 << UDRIE0);

	return 1;
}

uint8_t USART_PutString(const char *cadena)
{
	while (*cadena)
	{
		if (USART_PutChar(*cadena) == 0)
		{
			return 0;
		}
		cadena++;
	}
	return 1;
}

uint8_t USART_SendNumber16(uint16_t numero)
{
	char buffer[5];
	uint8_t i = 0;

	if (numero == 0U)
	{
		return USART_PutChar('0');
	}

	while ((numero > 0U) && (i < sizeof(buffer)))
	{
		buffer[i++] = (char)('0' + (numero % 10U));
		numero /= 10U;
	}

	while (i > 0U)
	{
		i--;
		if (USART_PutChar(buffer[i]) == 0)
		{
			return 0;
		}
	}

	return 1;
}

ISR(USART_RX_vect)
{
	uint8_t siguiente;
	char dato_rx;

	dato_rx = (char)UDR0;
	siguiente = (uint8_t)((rxWrite + 1U) % USART_RX_BUFFER_SIZE);

	if (siguiente != rxRead)
	{
		rxQueue[rxWrite] = dato_rx;
		rxWrite = siguiente;
	}
}

ISR(USART_UDRE_vect)
{
	if (txWrite == txRead)
	{
		UCSR0B &= ~(1 << UDRIE0);
	}
	else
	{
		UDR0 = txQueue[txRead];
		txRead = (uint8_t)((txRead + 1U) % USART_TX_BUFFER_SIZE);
	}
}