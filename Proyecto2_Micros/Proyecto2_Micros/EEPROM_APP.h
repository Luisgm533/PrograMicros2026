/*
 * EEPROM_APP.h
 *
 *  Author: luisg
 */ 
#ifndef EEPROM_APP_H_ // Evita múltiples inclusiones del archivo
#define EEPROM_APP_H_

#include <stdint.h> // Permite usar tipos como uint8_t y uint16_t

void EEPROM_Init(void);
// Inicializa la EEPROM
// Verifica que el contador de posiciones sea válido

void EEPROM_SavePosition(uint16_t pos[4]);
// Guarda una posición completa de los 4 servos en EEPROM

void EEPROM_ReadPosition(uint8_t index, uint16_t pos[4]);
// Lee una posición guardada desde EEPROM
// index = número de posición a leer
// pos = arreglo donde se almacenan los valores leídos

uint8_t EEPROM_GetSavedCount(void);
// Retorna la cantidad de posiciones guardadas en EEPROM

void EEPROM_ClearAll(void);
// Reinicia el contador de posiciones guardadas
// Hace que el sistema considere la EEPROM vacía

#endif