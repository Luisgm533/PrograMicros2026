/*
 * EEPROM_APP.h
 *
 *  Author: luisg
 */ 

#ifndef EEPROM_APP_H_
#define EEPROM_APP_H_

#include <stdint.h>

void EEPROM_Init(void);
void EEPROM_SavePosition(uint16_t pos[4]);
void EEPROM_ReadPosition(uint8_t index, uint16_t pos[4]);
uint8_t EEPROM_GetSavedCount(void);

#endif