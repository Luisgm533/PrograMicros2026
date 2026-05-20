/*
 * USART.h
 *
 *  Author: luisg
 */ 

#ifndef USART_H_
#define USART_H_

#include <stdint.h>

void USART_Init(uint32_t baud);
uint8_t USART_ReadChar(char *data);
void USART_SendChar(char data);
void USART_SendString(const char *str);
uint8_t USART_ReadLine(char *buffer, uint8_t max_len);
uint8_t USART_Parse4Values(char *buffer, uint16_t *a, uint16_t *b, uint16_t *c, uint16_t *d);

#endif