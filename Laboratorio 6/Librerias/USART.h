/*
 * USART.h
 *
 */ 

#ifndef USART_H_
#define USART_H_

#include <avr/io.h>
#include <stdint.h>

#define USART_RX_BUFFER_SIZE 64
#define USART_TX_BUFFER_SIZE 64

void USART_Init(unsigned long baudrate);

uint8_t USART_Available(void);
uint8_t USART_ReadChar(char *data);

uint8_t USART_SendChar(char data);
uint8_t USART_SendString(const char *str);
uint8_t USART_SendUnsigned16(uint16_t value);

#endif /* USART_H_ */
