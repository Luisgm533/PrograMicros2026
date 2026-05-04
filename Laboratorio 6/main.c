/*
 * Laboratorio 6
 *
 * Luis Guerra 24007
 */

#define F_CPU 16000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

#include "Librerias/ADC.h"
#include "Librerias/USART.h"

typedef enum
{
	STATE_MENU = 0,
	STATE_CHARACTER
} program_mode_t;

static void InitOutputs(void)
{
	DDRB = 0b00111111;
	PORTB = 0x00;

	DDRC = (DDRC | (1 << PC0) | (1 << PC1)) & ~(1 << PC2);
	PORTC &= ~((1 << PC0) | (1 << PC1));
}

static void PrintAsciiToLeds(uint8_t ascii_data)
{
	uint8_t lower_bits;
	uint8_t upper_bits;

	lower_bits = ascii_data & 0x3F;
	upper_bits = (ascii_data >> 6) & 0x03;

	PORTB = lower_bits;
	PORTC = (PORTC & 0xFC) | upper_bits;
}

static void WriteString(const char *message)
{
	uint8_t index = 0;

	while (message[index] != '\0')
	{
		while (USART_SendChar(message[index]) == 0)
		{
		}

		index++;
	}
}

static void WriteNumber(uint16_t number)
{
	while (USART_SendUnsigned16(number) == 0)
	{
	}
}

static void WriteAdcReading(uint16_t analog_reading)
{
	WriteString("ADC A2: ");
	WriteNumber(analog_reading);
	WriteString("\r\n");
}

static void PrintMenu(void)
{
	WriteString("\r\nMenu principal\r\n");
	WriteString("1. Mostrar ASCII de un caracter en LEDs\r\n");
	WriteString("2. Mostrar valor del potenciometro\r\n");
	WriteString("Seleccione una opcion: ");
}

int main(void)
{
	char serial_data = 0;
	uint16_t potentiometer_value = 0;
	program_mode_t current_mode = STATE_MENU;

	InitOutputs();
	PrintAsciiToLeds(0);

	ADC_Init();
	USART_Init(9600);
	sei();
	
	
	

	PrintMenu();

	while (1)
	{
		if (USART_ReadChar(&serial_data) != 0)
		{
			if (serial_data == '\r' || serial_data == '\n')
			{
				continue;
			}

			switch (current_mode)
			{
				case STATE_CHARACTER:

					PrintAsciiToLeds((uint8_t)serial_data);

					WriteString("\r\nCaracter recibido: ");
					while (USART_SendChar(serial_data) == 0)
					{
					}

					WriteString("\r\nValor decimal: ");
					WriteNumber((uint8_t)serial_data);
					WriteString("\r\n");

					current_mode = STATE_MENU;
					PrintMenu();
					break;

				case STATE_MENU:

					if (serial_data == '1')
					{
						WriteString("\r\nIngrese un caracter: ");
						current_mode = STATE_CHARACTER;
					}
					else if (serial_data == '2')
					{
						potentiometer_value = ADC_Read(2);

						WriteString("\r\n");
						WriteAdcReading(potentiometer_value);
						PrintMenu();
					}
					else
					{
						WriteString("\r\nOpcion invalida\r\n");
						PrintMenu();
					}

					break;

				default:
					current_mode = STATE_MENU;
					PrintMenu();
					break;
			}
		}

		_delay_ms(10);
	}
}


