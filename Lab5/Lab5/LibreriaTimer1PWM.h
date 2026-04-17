/*
 * LibreriaTimer1PWM.h
 *
 *  Author: luisg
 */ 

#ifndef LIBRERIA_TIMER1PWM_H
#define LIBRERIA_TIMER1PWM_H

#include <stdint.h>

void init_timer1(void);
void TIMER1_PWM1_set_servo_PW(uint8_t value);

#endif