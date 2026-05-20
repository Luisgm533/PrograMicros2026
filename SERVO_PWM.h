/*
 * SERVO_PWM.h
 *
 * Created: 6/05/2026 13:42:03
 *  Author: luisg
 */ 


#ifndef SERVO_PWM_H_
#define SERVO_PWM_H_

#include <stdint.h>

void SERVO_Init(void);
void SERVO_Set_us(uint8_t servo, uint16_t pulse_us);

#endif