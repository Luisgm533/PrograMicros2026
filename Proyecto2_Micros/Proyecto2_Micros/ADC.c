#define F_CPU 16000000UL // Define la frecuencia del microcontrolador en 16 MHz

#include <avr/io.h>       // Librería para manejar registros del ATmega328P
#include <stdint.h>       // Librería para usar tipos como uint8_t y uint16_t
#include <util/delay.h>   // Librería para usar delays
#include "ADC.h"          // Librería propia del ADC

void ADC_Init(void)
{
	ADMUX = (1 << REFS0); // Usa AVCC como voltaje de referencia del ADC

	ADCSRA = (1 << ADEN)  // Habilita el ADC
	| (1 << ADPS2)        // Configura prescaler del ADC
	| (1 << ADPS1)
	| (1 << ADPS0);       // Prescaler 128 para una lectura estable

	DIDR0 = (1 << ADC0D)  // Desactiva entrada digital en ADC0,1,2,3
	| (1 << ADC1D)        
	| (1 << ADC2D)        
	| (1 << ADC3D);       
}

uint16_t ADC_Read(uint8_t channel)
{
	channel &= 0x07; // Asegura que el canal esté entre ADC0 y ADC7

	ADMUX = (ADMUX & 0xF0) | channel; // Selecciona el canal ADC sin cambiar la referencia

	_delay_us(20); // Pequeña espera para estabilizar el cambio de canal

	ADCSRA |= (1 << ADSC); // Inicia una primera conversión ADC
	while (ADCSRA & (1 << ADSC)); // Espera a que termine

	ADCSRA |= (1 << ADSC); // Inicia una segunda conversión ADC
	while (ADCSRA & (1 << ADSC)); // Espera a que termine

	return ADC; // Retorna el valor leído entre 0 y 1023
}