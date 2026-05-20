/*
 * Proyecto2_Micros.c
 *
 * Author : luisg
 */



#define F_CPU 16000000UL

#include <avr/io.h>
#include <util/delay.h>
#include <stdint.h>

#include "ADC.h"
#include "SERVO_PWM.h"
#include "USART.h"
#include "EEPROM_APP.h"
#include "BUTTON.h"
#include "LEDS.h"

typedef enum // Creamos los nombres para los estados del sistema
{
	MODO_MANUAL = 0, // 0 para manual
	MODO_EEPROM, // 1 para EEPROM 
	MODO_ADAFRUIT // 2 para Adafruit
} modo_t;

static modo_t modo_actual = MODO_ADAFRUIT; // Al encender el sistema los servos inician en modo Adafruit

static uint8_t reproducir_eeprom = 0; // Mantenemos la EEPROM en 0 para que no reproduzca nada

static uint16_t servo_pos[4] = {1500, 1500, 1500, 1500}; //ancho del pulso PWM en microsegundos
	
/*
1000 us significa extremo izquierdo ? 0°
1500 us significa centro ? 90°
2000 us significa extremo derecho ? 180° 
*/


// El pot lee de 0 a 1023 (lectura ADC) y hace la conversión del ADC a PWM que el el ancho de pulso en us
static uint16_t map_adc_to_us(uint16_t adc) // Conversor ADC a PWM
{
	return 1000 + ((uint32_t)adc * 1000) / 1023;  
}


static void mover_servos(uint16_t pos[4]) // Esta función manda a cada posición a su servo.
{
	SERVO_Set_us(0, pos[0]);
	SERVO_Set_us(1, pos[1]);
	SERVO_Set_us(2, pos[2]);
	SERVO_Set_us(3, pos[3]);
}

static void modo_manual(void) //Funcion de modo manual
{
	//Lee la lectura 
	uint16_t adc0 = ADC_Read(0);
	uint16_t adc1 = ADC_Read(1);
	uint16_t adc2 = ADC_Read(2);
	uint16_t adc3 = ADC_Read(3);

	// Luego convierte cada ADC a servo:
	servo_pos[0] = map_adc_to_us(adc0);
	servo_pos[1] = map_adc_to_us(adc1);
	servo_pos[2] = map_adc_to_us(adc2);
	servo_pos[3] = map_adc_to_us(adc3);

	mover_servos(servo_pos); // Mueve la posicion del servo

	if (BUTTON_SavePressed()) // Condicion si apachamos el boton, guardamos la posicion en la EEPROM
	{
		EEPROM_SavePosition(servo_pos);
		USART_SendString("Posicion guardada en EEPROM\r\n");
		_delay_ms(300);
	}
}

static void modo_eeprom(void)
{
	uint8_t total = EEPROM_GetSavedCount(); // Primero revisa cuántas posiciones hay guardadas:

	if (total == 0) // Si no hay posiciones guardadas, manda a la terminal que no hay posiciones guardadas
	{
		USART_SendString("No hay posiciones guardadas\r\n");
		_delay_ms(1000);
		return;
	}

	for (uint8_t i = 0; i < total; i++) // Si sí hay posiciones, las reproduce una por una
	{
		EEPROM_ReadPosition(i, servo_pos);
		mover_servos(servo_pos);
		_delay_ms(900);
	}
}

static void procesar_comando(char *buffer) // Procesador de Commandos, es decir aquí recibe el Input del usuario
{
	uint16_t s1, s2, s3, s4;

	if (buffer[0] == 'M')
	{
		if (buffer[1] == '1') // Si el comando es 1, se activa el modo manual
		{
			modo_actual = MODO_MANUAL;
			reproducir_eeprom = 0;
			LEDS_SetMode(LED_MODE_MANUAL);
			USART_SendString("Modo manual activo\r\n");
		}
		else if (buffer[1] == '2') // si el comando es 2, se activa modo EEPROM
		{
			modo_actual = MODO_EEPROM;
			reproducir_eeprom = 1;
			LEDS_SetMode(LED_MODE_EEPROM);
			USART_SendString("Modo EEPROM activo\r\n");
		}
		else if (buffer[1] == '3') // Si el comando es 3, se activa modo ADAFRUIT
		{
			modo_actual = MODO_ADAFRUIT;
			reproducir_eeprom = 0;
			LEDS_SetMode(LED_MODE_UART);
			USART_SendString("Modo Adafruit activo\r\n");
		}
	}
	
// Aquí se le envian las posiciones de cada servo en el modo Adafuit para que las interprete y pueda moverse hacia donde se requiere	
	else if (buffer[0] == 'S') 
	{
		modo_actual = MODO_ADAFRUIT;
		reproducir_eeprom = 0;
		LEDS_SetMode(LED_MODE_UART);

		if (USART_Parse4Values(buffer + 1, &s1, &s2, &s3, &s4))
		{
			servo_pos[0] = s1;
			servo_pos[1] = s2;
			servo_pos[2] = s3;
			servo_pos[3] = s4;

			mover_servos(servo_pos);
			USART_SendString("Movimiento recibido desde Adafruit\r\n");
		}
	}
	else if (buffer[0] == 'R') // Si llega el comando R sirve también para reproducir la EEPROM
	{
		modo_actual = MODO_EEPROM;
		reproducir_eeprom = 1;
		LEDS_SetMode(LED_MODE_EEPROM);
		USART_SendString("Reproduciendo EEPROM\r\n");
	}
}

int main(void) //Declara el buffer..
{
	char buffer[32]; // Ese buffer guarda lo que llega por serial.


	// Luego inicializa todo:
	
	ADC_Init();
	SERVO_Init();
	USART_Init(9600);
	EEPROM_Init();
	BUTTON_Init();
	LEDS_Init();

	LEDS_SetMode(LED_MODE_UART); // Después prende LED de Adafruit porque iniciamos en ese modo

	USART_SendString("Sistema iniciado\r\n");
	USART_SendString("Comandos: M1, M2, M3, R, S1000,1500,1200,1800\r\n");

	while (1) // Aquí vive todo el ciclo
	{
		if (USART_ReadLine(buffer, sizeof(buffer))) // Revisa si llegó algo por el USART (ADAFRUIT)
		{
			procesar_comando(buffer); // Luego ejectura ´según el modo 
		}

		if (modo_actual == MODO_MANUAL) // Ejecuta modo manual
		{
			modo_manual();
		}
		else if (modo_actual == MODO_EEPROM) // Ejecuta modo EEPROM
		{
			if (reproducir_eeprom)
			{
				modo_eeprom();
				reproducir_eeprom = 0;
				USART_SendString("Reproduccion EEPROM finalizada\r\n");
			}
		}
	}
}