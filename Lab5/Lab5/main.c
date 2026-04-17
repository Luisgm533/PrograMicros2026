/*
 * Lab5.c
 *
 * Author : luisg
 */ 


#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include "LibreriaTimer1PWM.h"
#include "LibreriaADC.h"
#include "LibreriaTimer2PWM.h"

// ======================================
// VARIABLES GLOBALES
// ======================================
volatile uint8_t adc_channel_actual = 0;

// ======================================
// PROTOTIPOS
// ======================================
void init_timer0(void);

// ======================================
// MAIN
// ======================================
int main(void)
{
    cli();

    setup_adc();          // ADC
    init_timer0();        // Trigger ADC
    init_timer1();        // Servo 1 en D9 con Timer1
    init_timer2_all();    // Servo 2 en D11 + LED en D3 con Timer2

    sei();

    while (1)
    {
        // Todo ocurre en interrupciones
    }

    return 0;
}

// ======================================
// TIMER0 - ADC
// ======================================
void init_timer0(void)
{
    TCCR0A = 0;
    TCCR0B = 0;

    // Prescaler 64
    TCCR0B |= (1 << CS01) | (1 << CS00);

    TCNT0 = 0;

    // Interrupt overflow
    TIMSK0 |= (1 << TOIE0);
}

// ======================================
// ISR TIMER0
// ======================================
ISR(TIMER0_OVF_vect)
{
    TCNT0 = 0;
    ADCSRA |= (1 << ADSC);
}

// ======================================
// ISR ADC (3 CANALES)
// ======================================

ISR(ADC_vect)
{
    uint8_t lectura = ADCH;

    switch (adc_channel_actual)
    {
        case 0:
            TIMER1_PWM1_set_servo_PW(lectura); // Servo 1 -> D9
            adc_channel_actual = 1;
            adc_set_channel(1);
            break;

        case 1:
            timer2_set_servo2(lectura);        // Servo 2 -> D11
            adc_channel_actual = 2;
            adc_set_channel(2);
            break;

        case 2:
            timer2_set_led(lectura);           // LED -> D3
            adc_channel_actual = 0;
            adc_set_channel(0);
            break;
    }
}