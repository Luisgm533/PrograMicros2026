/*
 * LibreriaTimer2PWM.h
 *
 *  Author: luisg
 */ 

#ifndef LIBRERIA_TIMER2PWM_H
#define LIBRERIA_TIMER2PWM_H

#include <stdint.h>

void init_timer2_all(void);
void timer2_set_servo2(uint8_t value);
void timer2_set_led(uint8_t duty);

#endif