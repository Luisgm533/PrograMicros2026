/*
 * EEPROM_APP.c
 *
 * Created: 6/05/2026 13:44:45
 *  Author: luisg
 */ 

#include <avr/eeprom.h> // Librería para manejar la EEPROM del ATmega
#include <stdint.h>     // Librería para tipos estándar
#include "EEPROM_APP.h" // Librería propia de EEPROM

#define MAX_POSITIONS 10 // Cantidad máxima de posiciones que se pueden guardar

// Variable en EEPROM que guarda cuántas posiciones hay almacenadas
uint8_t EEMEM ee_count = 0;

// Arreglo en EEPROM para guardar posiciones de 4 servos
// [posición][servo]
uint16_t EEMEM ee_positions[MAX_POSITIONS][4];

void EEPROM_Init(void)
{
	// Lee cuántas posiciones hay guardadas
	uint8_t count = eeprom_read_byte(&ee_count);

	// Si el valor es inválido, reinicia el contador
	if (count > MAX_POSITIONS)
	{
		eeprom_update_byte(&ee_count, 0);
	}
}

uint8_t EEPROM_GetSavedCount(void)
{
	// Lee el número de posiciones guardadas
	uint8_t count = eeprom_read_byte(&ee_count);

	// Verifica que el valor sea válido
	if (count > MAX_POSITIONS)
	{
		count = 0;
	}

	return count; // Retorna cantidad de posiciones guardadas
}

void EEPROM_SavePosition(uint16_t pos[4])
{
	// Obtiene cuántas posiciones hay guardadas
	uint8_t count = EEPROM_GetSavedCount();

	// Si se llegó al límite, vuelve al inicio
	if (count >= MAX_POSITIONS)
	{
		count = 0;
	}

	// Guarda las 4 posiciones de los servos
	for (uint8_t i = 0; i < 4; i++)
	{
		eeprom_update_word(&ee_positions[count][i], pos[i]);
	}

	// Incrementa el contador de posiciones guardadas
	count++;

	// Guarda el nuevo contador en EEPROM
	eeprom_update_byte(&ee_count, count);
}

void EEPROM_ReadPosition(uint8_t index, uint16_t pos[4])
{
	// Verifica que el índice sea válido
	if (index >= MAX_POSITIONS) return;

	// Lee las posiciones guardadas
	for (uint8_t i = 0; i < 4; i++)
	{
		pos[i] = eeprom_read_word(&ee_positions[index][i]);

		// Verifica que el valor leído sea válido para un servo
		if (pos[i] < 1000 || pos[i] > 2000)
		{
			pos[i] = 1500; // Si es inválido, coloca el servo al centro
		}
	}
}

void EEPROM_ClearAll(void)
{
	// Reinicia el contador de posiciones guardadas
	// Esto hace que el sistema considere la EEPROM vacía
	eeprom_update_byte(&ee_count, 0);
}