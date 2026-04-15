/*
 * LibreriaTimer1PWM.h
 *
 *  Author: luisg
 */ 

#ifndef LIBRERIA_TIMER1PWM_H
#define LIBRERIA_TIMER1PWM_H

#include <stdint.h>

void init_timer1_pwm_servo(void);
void TIMER1_PWM1_set_servo_us(uint16_t pulse_us);
void TIMER1_PWM1_set_servo_adc(uint16_t adc_value);

#endif