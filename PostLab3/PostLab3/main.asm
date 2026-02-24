// Lab3.asm
// Created: 18/02/2026 14:17:45
// Author : luisg

.include "M328PDEF.inc"

// =========================
// Constantes de temporización
// =========================
.equ T0_PRESC     = (1<<CS02) | (1<<CS00)   // Prescaler Timer0: 1024 (CS02=1, CS00=1)
.equ T0_PRELOAD   = 178                    // Precarga TCNT0 para ajustar el periodo de overflow (5 ms aprox)
.equ OVF_PER_SEC  = 200                    // Overflows por segundo (200 * 5ms = ~1s)
.equ STABLE_N     = 10                     // Lecturas consecutivas estables para debounce (10 * 5ms = 50ms)

// =========================
// Enables de displays 7seg (activo-bajo por cátodo común)
// =========================
// PB4 controla D1 (decenas)  y PB5 controla D2 (unidades)
.equ EN_TENS_BIT  = 4                      // Bit de enable para decenas  (PB4)
.equ EN_UNITS_BIT = 5                      // Bit de enable para unidades (PB5)

// =========================
// Vectores e inicio de programa
// =========================
.cseg
.org 0x0000
    RJMP RESET                              // Vector de reset
.org PCI1addr
    RJMP PCINT1_ISR                         // Vector de interrupción PCINT1 (PC0/PC1)
.org OVF0addr
    RJMP T0_OVF_ISR                         // Vector de overflow Timer0

// =========================
// Tabla 7 segmentos para cátodo común (1 = segmento encendido)
// Indices 0..9
// =========================
.org 0x0100
TABLA7SEG:
    .db 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F

// =========================
// RESET: configuración de stack, puertos, interrupciones y variables
// =========================
RESET:
    // Inicializar stack pointer
    LDI  R16, LOW(RAMEND)
    OUT  SPL, R16
    LDI  R16, HIGH(RAMEND)
    OUT  SPH, R16

    // Configurar PORTB
    // PB0..PB3 como salidas para LEDs, PB4 y PB5 como salidas para enables D1/D2
    LDI  R16, 0b00111111
    OUT  DDRB, R16
    CLR  R16
    OUT  PORTB, R16

    // Apagar ambos dígitos (activo-bajo, apagado = 1)
    SBI  PORTB, EN_TENS_BIT
    SBI  PORTB, EN_UNITS_BIT

    // Configurar PORTD
    // PD0..PD6 como salidas para segmentos A..G
    LDI  R16, 0b01111111
    OUT  DDRD, R16
    CLR  R16
    OUT  PORTD, R16

    // Configurar botones en PORTC
    // PC0 y PC1 como entradas con pull-up interno
    CLR  R16
    OUT  DDRC, R16
    LDI  R16, (1<<PC0) | (1<<PC1)
    OUT  PORTC, R16

    // Habilitar interrupciones por cambio de pin en PCINT1
    // PCIE1 habilita el grupo PCINT[14:8], aquí usamos PCINT8 (PC0) y PCINT9 (PC1)
    LDI  R16, (1<<PCIE1)
    STS  PCICR, R16
    LDI  R16, (1<<PCINT8) | (1<<PCINT9)
    STS  PCMSK1, R16

    // Configurar Timer0 para overflow periódico (~5ms)
    CLR  R16
    OUT  TCCR0A, R16                         // Modo normal
    LDI  R16, T0_PRESC
    OUT  TCCR0B, R16                         // Prescaler seleccionado
    LDI  R16, T0_PRELOAD
    OUT  TCNT0, R16                          // Precarga para ajustar el periodo
    LDI  R16, (1<<TOIE0)
    STS  TIMSK0, R16                         // Habilitar interrupción overflow Timer0

    // Uso de registros como variables globales
    // R20: contador LEDs (0..15) mostrado en PB0..PB3
    // R21: lectura previa de PINC para detectar cambios en PCINT
    // R22: contador de overflows para formar 1 segundo
    // R23: unidades del contador 00..59
    // R27: decenas del contador 00..59
    // R24: contador debounce para botón INC (PC0)
    // R25: contador debounce para botón DEC (PC1)
    // R26: flags de botones pendientes (bit0 INC, bit1 DEC)
    // R28: estado multiplex (0 muestra unidades, 1 muestra decenas)

    CLR  R20
    IN   R21, PINC                           // Guardar estado inicial de botones
    CLR  R22
    CLR  R23
    CLR  R27
    CLR  R24
    CLR  R25
    CLR  R26
    CLR  R28

    RCALL UPDATE_LEDS                        // Pintar LEDs iniciales

    SEI                                       // Habilitar interrupciones globales
MAIN:
    RJMP MAIN                                 // Loop vacío, todo lo hace el sistema por interrupciones

// =========================
// UPDATE_LEDS
// Actualiza PB0..PB3 sin modificar PB4/PB5 (enables del display)
// =========================
UPDATE_LEDS:
    IN   R16, PORTB                          // Leer salida actual de PORTB
    ANDI R16, 0xF0                           // Conservar PB4..PB7
    MOV  R17, R20                            // Copiar contador LEDs
    ANDI R17, 0x0F                           // Quedarse con 4 bits bajos
    OR   R16, R17                            // Mezclar LEDs con lo conservado
    OUT  PORTB, R16                          // Escribir de vuelta
    RET

// =========================
// LOAD_7SEG_DIGIT
// Entrada: R16 = dígito 0..9
// Salida: PORTD = patrón de segmentos para ese dígito
// =========================
LOAD_7SEG_DIGIT:
    LDI  ZL, LOW(TABLA7SEG*2)                // Z apunta a tabla en memoria de programa
    LDI  ZH, HIGH(TABLA7SEG*2)
    ADD  ZL, R16                             // Desplazamiento por índice
    CLR  R1                                   // R1 en 0 para acarreo
    ADC  ZH, R1                              // Ajustar alto si hubo acarreo
    LPM  R17, Z                              // Leer byte de tabla
    OUT  PORTD, R17                          // Sacar patrón a segmentos
    RET

// =========================
// SHOW_2DIGITS
// Multiplexa el display de 2 dígitos alternando cada llamada
// R28 = 0 muestra unidades (D2), R28 = 1 muestra decenas (D1)
// =========================
SHOW_2DIGITS:
    TST  R28                                 // Revisar estado de multiplex
    BRNE SHOW_TENS                           // Si R28 != 0, toca decenas

SHOW_UNITS:
    SBI  PORTB, EN_TENS_BIT                  // Apagar decenas (enable en 1)
    SBI  PORTB, EN_UNITS_BIT                 // Apagar unidades (enable en 1)

    MOV  R16, R23                             // Cargar unidades en R16
    RCALL LOAD_7SEG_DIGIT                    // Escribir patrón en PORTD

    CBI  PORTB, EN_UNITS_BIT                 // Encender unidades (enable activo-bajo)
    LDI  R28, 1                               // Próxima vez mostrar decenas
    RET

SHOW_TENS:
    SBI  PORTB, EN_TENS_BIT                  // Apagar decenas
    SBI  PORTB, EN_UNITS_BIT                 // Apagar unidades

    MOV  R16, R27                             // Cargar decenas en R16
    RCALL LOAD_7SEG_DIGIT                    // Escribir patrón en PORTD

    CBI  PORTB, EN_TENS_BIT                  // Encender decenas (enable activo-bajo)
    CLR  R28                                  // Próxima vez mostrar unidades
    RET

// =========================
// PCINT1_ISR
// Interrupción por cambio en PC0/PC1
// Marca flags en R26 y reinicia contadores de debounce
// =========================
PCINT1_ISR:
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    IN   R17, PINC                           // Leer estado actual de botones
    MOV  R16, R17
    EOR  R16, R21                            // R16 queda con bits que cambiaron respecto a la lectura previa

    // Si cambió PC0, marcar flag de INC y reiniciar debounce INC
    SBRS R16, 0                              // Saltar si bit0 está en 1, si no cambió no entra
    RJMP chk_dec
    SBR  R26, (1<<0)                         // Flag INC pendiente
    CLR  R24                                 // Reiniciar contador debounce INC

chk_dec:
    // Si cambió PC1, marcar flag de DEC y reiniciar debounce DEC
    SBRS R16, 1
    RJMP save_prev
    SBR  R26, (1<<1)                         // Flag DEC pendiente
    CLR  R25                                 // Reiniciar contador debounce DEC

save_prev:
    MOV  R21, R17                            // Guardar lectura actual como previa

    POP  R16
    OUT  SREG, R16
    POP  R17
    POP  R16
    RETI

// =========================
// T0_OVF_ISR
// Interrupción de overflow Timer0
// Refresca multiplex, hace debounce y actualiza contador 00..59 cada 1s
// =========================
T0_OVF_ISR:
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    // Recargar TCNT0 para mantener el periodo de overflow
    LDI  R16, T0_PRELOAD
    OUT  TCNT0, R16

    // Multiplexar display en cada overflow (~5ms)
    RCALL SHOW_2DIGITS

    // Leer botones (con pull-up, presionado suele ser 0 si el botón va a GND)
    IN   R17, PINC

    // =========================
    // Debounce para INC (PC0)
    // R26 bit0 indica que hubo cambio y está pendiente confirmar estabilidad
    // R24 cuenta lecturas consecutivas presionado
    // =========================
    SBRC R26, 0                               // Si flag INC está en 0, saltar el RJMP do_inc
    RJMP do_inc
    RJMP do_dec_part

do_inc:
    SBRS R17, 0                               // Si PC0 está en 1, saltar el RJMP inc_pressed
    RJMP inc_pressed                          // Si PC0 está en 0, se considera presionado
    CLR  R24                                  // Si no está presionado, limpiar contador
    CBR  R26, (1<<0)                          // Limpiar flag INC
    RJMP do_dec_part

inc_pressed:
    INC  R24                                  // Sumar lectura estable presionado
    CPI  R24, STABLE_N                        // Ya se mantuvo presionado suficientes ciclos
    BRLO do_dec_part                          // Si no, todavía no se acepta como válido
    INC  R20                                  // Acción INC sobre contador de LEDs
    ANDI R20, 0x0F                            // Mantener 0..15
    RCALL UPDATE_LEDS                         // Actualizar LEDs
    CLR  R24                                  // Reiniciar debounce
    CBR  R26, (1<<0)                          // Limpiar flag INC

do_dec_part:
    // =========================
    // Debounce para DEC (PC1)
    // R26 bit1 indica cambio pendiente
    // R25 cuenta lecturas consecutivas presionado
    // =========================
    SBRC R26, 1
    RJMP do_dec
    RJMP time_part

do_dec:
    SBRS R17, 1
    RJMP dec_pressed                          // Si PC1 está en 0, se considera presionado
    CLR  R25                                  // Si no está presionado, limpiar contador
    CBR  R26, (1<<1)                          // Limpiar flag DEC
    RJMP time_part

dec_pressed:
    INC  R25                                  // Sumar lectura estable presionado
    CPI  R25, STABLE_N
    BRLO time_part
    DEC  R20                                  // Acción DEC sobre contador de LEDs
    ANDI R20, 0x0F                            // Mantener 0..15
    RCALL UPDATE_LEDS                         // Actualizar LEDs
    CLR  R25
    CBR  R26, (1<<1)                          // Limpiar flag DEC

time_part:
    // =========================
    // Base de tiempo de 1 segundo
    // R22 acumula overflows hasta OVF_PER_SEC
    // =========================
    INC  R22
    CPI  R22, OVF_PER_SEC
    BRLO t0_end
    CLR  R22

    // =========================
    // Contador 00..59 en display
    // Unidades R23 0..9, decenas R27 0..5
    // =========================
    INC  R23
    CPI  R23, 10
    BRLO t0_end

    CLR  R23
    INC  R27
    CPI  R27, 6
    BRLO t0_end

    // Reset al llegar a 60
    CLR  R27
    CLR  R23

t0_end:
    POP  R16
    OUT  SREG, R16
    POP  R17
    POP  R16
    RETI