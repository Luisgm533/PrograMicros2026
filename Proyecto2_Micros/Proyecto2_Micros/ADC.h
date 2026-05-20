/*
 * ADC.h
 *
 *  Author: luisg
 */ 


#ifndef ADC_H_
#define ADC_H_

#include <stdint.h>

void ADC_Init(void); // Función para inicializar el ADC
uint16_t ADC_Read(uint8_t channel); 

// Función para leer un canal ADC específico
// channel = canal analógico a leer (ADC0, ADC1, etc.)
// retorna un valor entre 0 y 1023

#endif