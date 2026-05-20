/*
 * BUTTON.h
 *
 *  Author: luisg
 */ 


#ifndef BUTTON_H_ // Evita múltiples inclusiones del archivo
#define BUTTON_H_

#include <stdint.h> // Permite usar tipos como uint8_t

void BUTTON_Init(void);
// Función para inicializar el botón
// Configura el pin PD2 como entrada con pull-up

uint8_t BUTTON_SavePressed(void);
// Función que verifica si el botón fue presionado
// Retorna:
// 1 = botón presionado correctamente
// 0 = botón no presionado

#endif