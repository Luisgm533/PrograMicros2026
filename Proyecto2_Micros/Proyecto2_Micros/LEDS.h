/*
 * LEDS.h
 *
 *  Author: luisg
 */ 


#ifndef LEDS_H_
#define LEDS_H_

typedef enum
{
	LED_MODE_MANUAL = 0,
	LED_MODE_EEPROM,
	LED_MODE_UART
} led_mode_t;

void LEDS_Init(void);
void LEDS_AllOff(void);
void LEDS_SetMode(led_mode_t mode);

#endif