/*
 * EEPROM_APP.c
 *
 * Created: 6/05/2026 13:44:45
 *  Author: luisg
 */ 


#include <avr/eeprom.h>
#include <stdint.h>
#include "EEPROM_APP.h"

#define MAX_POSITIONS 10

uint8_t EEMEM ee_count = 0;
uint16_t EEMEM ee_positions[MAX_POSITIONS][4];

void EEPROM_Init(void)
{
	uint8_t count = eeprom_read_byte(&ee_count);

	if (count > MAX_POSITIONS)
	{
		eeprom_update_byte(&ee_count, 0);
	}
}

uint8_t EEPROM_GetSavedCount(void)
{
	uint8_t count = eeprom_read_byte(&ee_count);

	if (count > MAX_POSITIONS)
	{
		count = 0;
	}

	return count;
}

void EEPROM_SavePosition(uint16_t pos[4])
{
	uint8_t count = EEPROM_GetSavedCount();

	if (count >= MAX_POSITIONS)
	{
		count = 0;
	}

	for (uint8_t i = 0; i < 4; i++)
	{
		eeprom_update_word(&ee_positions[count][i], pos[i]);
	}

	count++;
	eeprom_update_byte(&ee_count, count);
}

void EEPROM_ReadPosition(uint8_t index, uint16_t pos[4])
{
	if (index >= MAX_POSITIONS) return;

	for (uint8_t i = 0; i < 4; i++)
	{
		pos[i] = eeprom_read_word(&ee_positions[index][i]);

		if (pos[i] < 1000 || pos[i] > 2000)
		{
			pos[i] = 1500;
		}
	}
}