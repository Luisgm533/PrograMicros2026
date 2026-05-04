/*
 * USART.h
 *
 *  Author: luisg
 */ 


#ifndef USART_H_
#define USART_H_

#include <avr/io.h>
#include <stdint.h>

void USART_Init(unsigned long baudrate);
uint8_t USART_ReadChar(char *data);
uint8_t USART_SendChar(char data);

#endif