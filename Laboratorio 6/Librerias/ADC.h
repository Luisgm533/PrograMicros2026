/*
 * ADC.h
 *
 */ 

#ifndef ADC_H_
#define ADC_H_

#include <avr/io.h>
#include <stdint.h>

void ADC_Init(void);
uint16_t ADC_Read(uint8_t channel);

#endif /* ADC_H_ */
