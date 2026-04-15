/*
 * PostLab4.c
 *
 * Author : luisg
 */ 



// LIBRERIAS QUE VOY A USAR
#include <avr/io.h>
#include <avr/interrupt.h>

// VARIABLES GLOBALES
volatile unsigned char contador = 0;        // contador de 8 bits que manejo con botones
volatile unsigned char adc_val = 0;         // valor actual leído del ADC
volatile unsigned char estado_prev_b = 0xFF; // guarda el estado anterior de los botones en PORTB


// ESTA FUNCION MUESTRA UN NUMERO HEXADECIMAL EN EL DISPLAY
void show_number(unsigned char num)
{
	unsigned char tabla[16] =
	{
		0x3F, // 0
		0x06, // 1
		0x5B, // 2
		0x4F, // 3
		0x66, // 4
		0x6D, // 5
		0x7D, // 6
		0x07, // 7
		0x7F, // 8
		0x6F, // 9
		0x77, // A
		0x7C, // b
		0x39, // C
		0x5E, // d
		0x79, // E
		0x71  // F
	};

	// aqui conservo PD7 porque ese pin ya no es segmento, sino un LED del contador
	PORTD = (PORTD & (1 << PD7)) | tabla[num & 0x0F];
}


// ESTA FUNCION ME DEVUELVE EL NIBBLE ALTO
unsigned char high_nibble(unsigned char num)
{
	return (num >> 4) & 0x0F;
}

// ESTA FUNCION ME DEVUELVE EL NIBBLE BAJO
unsigned char low_nibble(unsigned char num)
{
	return num & 0x0F;
}


// ANTIRREBOTE CORTO HECHO CON RETARDO
void antirrebote_corto(void)
{
	for (volatile unsigned int i = 0; i < 12000; i++);
}


// ESTA FUNCION ACTUALIZA LOS LEDS DEL CONTADOR DE 8 BITS
// bits 0 a 3  -> PB2, PB3, PB4, PB5
// bits 4 a 6  -> PC0, PC4, PC5
// bit 7       -> PD7
void update_counter_leds(unsigned char valor)
{
	// primero limpio todos los pines que uso para el contador
	PORTB &= ~((1 << PB2) | (1 << PB3) | (1 << PB4) | (1 << PB5));
	PORTC &= ~((1 << PC0) | (1 << PC4) | (1 << PC5));
	PORTD &= ~(1 << PD7);

	// luego enciendo solo los bits que sí estén en 1
	if (valor & (1 << 0)) PORTB |= (1 << PB2);
	if (valor & (1 << 1)) PORTB |= (1 << PB3);
	if (valor & (1 << 2)) PORTB |= (1 << PB4);
	if (valor & (1 << 3)) PORTB |= (1 << PB5);

	if (valor & (1 << 4)) PORTC |= (1 << PC0);
	if (valor & (1 << 5)) PORTC |= (1 << PC4);
	if (valor & (1 << 6)) PORTC |= (1 << PC5);

	if (valor & (1 << 7)) PORTD |= (1 << PD7);
}


// ESTA FUNCION ACTUALIZA LA ALARMA
// si el ADC es mayor que el contador, se enciende el LED de alarma en PC3
void update_alarm(void)
{
	if (adc_val > contador)
	{
		PORTC |= (1 << PC3);
	}
	else
	{
		PORTC &= ~(1 << PC3);
	}
}


// CONFIGURACION DE TIMER0 PARA HACER EL MULTIPLEXADO
void setup_timer0(void)
{
	TCCR0A = 0x00;                          // modo normal
	TCCR0B = (1 << CS01) | (1 << CS00);    // prescaler de 64
	TCNT0 = 6;                             // precarga para ajustar el tiempo
	TIMSK0 = (1 << TOIE0);                 // habilito interrupcion por overflow
}


// CONFIGURACION DEL ADC EN EL CANAL ADC6 / A6
void setup_adc(void)
{
	ADMUX = (1 << REFS0) | (1 << ADLAR) | (1 << MUX2) | (1 << MUX1);
	// REFS0 = referencia AVCC
	// ADLAR = ajuste a la izquierda para leer solo ADCH
	// MUX2 y MUX1 = seleccionan ADC6

	ADCSRA = (1 << ADEN)  |
	         (1 << ADIE)  |
	         (1 << ADPS2) |
	         (1 << ADPS1) |
	         (1 << ADPS0);
	// ADEN  = habilita ADC
	// ADIE  = habilita interrupcion del ADC
	// ADPS2:0 = prescaler 128

	ADCSRA |= (1 << ADSC); // inicio la primera conversion
}


// MAIN
int main(void)
{
	// CONFIGURACION DE PORTB
	// PB0 y PB1 son botones
	// PB2 a PB5 son LEDs del contador
	DDRB = (1 << PB2) | (1 << PB3) | (1 << PB4) | (1 << PB5);
	PORTB = (1 << PB0) | (1 << PB1); // pull-up en los botones

	// CONFIGURACION DE PORTC
	// PC0, PC4 y PC5 son LEDs del contador
	// PC1 y PC2 habilitan displays
	// PC3 es LED de alarma
	DDRC = (1 << PC0) | (1 << PC1) | (1 << PC2) | (1 << PC3) | (1 << PC4) | (1 << PC5);
	PORTC = 0x00;

	// CONFIGURACION DE PORTD
	// PD0 a PD6 son segmentos
	// PD7 es el bit 7 del contador
	DDRD = 0xFF;
	PORTD = 0x00;

	// guardo el estado inicial de los botones
	estado_prev_b = PINB;

	// actualizo desde el inicio los LEDs y la alarma
	update_counter_leds(contador);
	update_alarm();

	// inicializo timer y ADC
	setup_timer0();
	setup_adc();

	// habilito interrupciones por cambio en pin para PB0 y PB1
	PCMSK0 = (1 << PCINT0) | (1 << PCINT1);
	PCICR  = (1 << PCIE0);

	// habilito interrupciones globales
	sei();

	// lazo principal vacío porque todo lo manejo por interrupciones
	while (1)
	{
	}
}


// ISR DE LOS BOTONES
ISR(PCINT0_vect)
{
	unsigned char estado_actual;
	unsigned char cambios;

	// pequeño antirrebote
	antirrebote_corto();

	// leo estado actual de PORTB
	estado_actual = PINB;

	// detecto qué bits cambiaron con respecto al estado anterior
	cambios = estado_prev_b ^ estado_actual;

	// si cambió PB1 y ahora está en 0, significa que se presionó
	if ((cambios & (1 << PB1)) && !(estado_actual & (1 << PB1)))
	{
		contador++;
		update_counter_leds(contador);
		update_alarm();
	}

	// si cambió PB0 y ahora está en 0, significa que se presionó
	if ((cambios & (1 << PB0)) && !(estado_actual & (1 << PB0)))
	{
		contador--;
		update_counter_leds(contador);
		update_alarm();
	}

	// actualizo el estado anterior para la próxima interrupción
	estado_prev_b = estado_actual;
}


// ISR DE TIMER0
// aquí hago el multiplexado de los 2 displays
// display 1 muestra el nibble alto del ADC
// display 2 muestra el nibble bajo del ADC
ISR(TIMER0_OVF_vect)
{
	static unsigned char mux = 0;

	TCNT0 = 6; // vuelvo a cargar el timer

	// apago ambos displays antes de cambiar el dato
	PORTC &= ~((1 << PC1) | (1 << PC2));

	switch (mux)
	{
		case 0:
			show_number(high_nibble(adc_val));
			PORTC |= (1 << PC1);
			break;

		case 1:
			show_number(low_nibble(adc_val));
			PORTC |= (1 << PC2);
			break;
	}

	// alterno entre display 1 y display 2
	mux++;
	if (mux > 1)
	{
		mux = 0;
	}
}


// ISR DEL ADC
ISR(ADC_vect)
{
	unsigned char valor = ADCH; // como está ajustado a la izquierda, leo ADCH directamente

	// hago saturación en extremos para evitar valores raros
	if (valor < 5)
	{
		valor = 0;
	}

	if (valor > 250)
	{
		valor = 255;
	}

	// guardo el valor leído
	adc_val = valor;

	// actualizo la alarma comparando ADC con contador
	update_alarm();

	// inicio una nueva conversión
	ADCSRA |= (1 << ADSC);
}