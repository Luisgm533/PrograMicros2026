;
; Reloj_Digital_Assembler.asm
;
; Author : luisg
;

.cseg

; Vector de reset
; Cuando el micro arranca, salta a START
.org 0x0000
    RJMP START

; Vector de interrupcion por overflow de Timer0
; Cada vez que Timer0 se desborda, salta a TIMER0_ISR
.org OVF0addr
    RJMP TIMER0_ISR

; Inicio del programa principal
.org 0x0200


; =========================
; Pines
; =========================

; Botones conectados en PORTB
.equ BTN_MODE = PB0      ; Cambia entre hora, fecha y alarma
.equ BTN_EDIT = PB1      ; Cambia entre no editar, editar primer campo, editar segundo campo
.equ BTN_UP   = PB2      ; Incrementa valor
.equ BTN_DOWN = PB3      ; Decrementa valor

; Displays habilitados por lineas independientes
.equ DISP1 = PB4         ; Display 1
.equ DISP2 = PB5         ; Display 2
.equ DISP3 = PC4         ; Display 3
.equ DISP4 = PC5         ; Display 4

; Otras salidas
.equ LED_HORA  = PC0     ; LED indicador de modo hora
.equ LED_FECHA = PC1     ; LED indicador de modo fecha
.equ BUZZER    = PC2     ; Salida para buzzer
.equ COLON     = 7       ; PD7 usado para los dos puntos


; =========================
; Constantes
; =========================

; Prescaler de Timer0
; CS02 = 1 y CS00 = 1 da prescaler 1024
.equ PRESCALER0   = (1<<CS02) | (1<<CS00)

; Valor inicial de Timer0
; Se carga en 254 para que el overflow ocurra rapido
.equ TIMER_START0 = 254

; Cantidad de overflows para formar medio segundo
.equ HALFSEC      = 244

; Modos del sistema
.equ MODE_HORA    = 0
.equ MODE_FECHA   = 1
.equ MODE_ALARMA  = 2

; Estados de edicion
.equ EDIT_OFF     = 0    ; No se esta editando
.equ EDIT_FIRST   = 1    ; Se edita el primer campo
.equ EDIT_LAST    = 2    ; Se edita el segundo campo


; =========================
; Registros altos
; =========================

; Registros de trabajo y variables principales
.def TMP          = R16  ; Temporal principal
.def TMP2         = R17  ; Temporal secundario
.def MUX          = R18  ; Selector de display para multiplexado
.def TICKS        = R19  ; Cuenta overflows para formar medio segundo
.def HALF         = R20  ; Cuenta medios segundos para formar 1 segundo
.def SECS         = R21  ; Segundos actuales
.def MINS         = R22  ; Minutos actuales
.def HOURS        = R23  ; Horas actuales
.def MODE         = R24  ; Modo actual: hora, fecha o alarma
.def EDIT         = R25  ; Estado actual de edicion


; =========================
; Registros bajos
; =========================

; Fecha y alarma
.def MONTHS       = R2   ; Mes actual
.def DAYS         = R3   ; Dia actual
.def ALM_HOURS    = R4   ; Hora de alarma
.def ALM_MINS     = R5   ; Minuto de alarma

; Digitos ya separados para mostrar en displays
.def DB1          = R6   ; Digito 1
.def DB2          = R7   ; Digito 2
.def DB3          = R8   ; Digito 3
.def DB4          = R9   ; Digito 4

; Estado de la alarma
.def ALARM_ACTIVE = R10  ; 1 si la alarma esta sonando
.def ALARM_LATCH  = R11  ; Evita que la alarma se reactive muchas veces en el mismo minuto

; Estado logico del colon
; 0 = apagado
; 1 = encendido
.def COLON_STATE  = R12


; =========================
; START
; =========================
START:
    ; Inicializa el stack pointer
  
    LDI TMP, LOW(RAMEND)
    OUT SPL, TMP
    LDI TMP, HIGH(RAMEND)
    OUT SPH, TMP

    ; Configura el reloj del micro a 1 MHz
   
    LDI TMP, (1<<CLKPCE)
    STS CLKPR, TMP

    LDI TMP, (1<<CLKPS2)
    STS CLKPR, TMP

    ; PORTD completo como salida
    ; Aqui estan los segmentos del display y el colon (los dos puntos) en PD7
    LDI TMP, 0xFF
    OUT DDRD, TMP

    ; Inicialmente apaga todo PORTD
    CLR TMP
    OUT PORTD, TMP

    ; Configuracion de PORTB
    ; PB0 a PB3 quedan como entradas con pull-up interno activo
    ; porque se escribe 1 en PORTB sin poner DDRB en salida
    LDI TMP, (1<<BTN_MODE)|(1<<BTN_EDIT)|(1<<BTN_UP)|(1<<BTN_DOWN)
    OUT PORTB, TMP

    ; PB4 y PB5 como salidas para activar display 1 y 2
    LDI TMP, (1<<DISP1)|(1<<DISP2)
    OUT DDRB, TMP

    ; Configuracion de PORTC
    ; PC0, PC1, PC2, PC4 y PC5 como salidas
    ; LED_HORA, LED_FECHA, BUZZER, DISP3 y DISP4
    LDI TMP, (1<<LED_HORA)|(1<<LED_FECHA)|(1<<BUZZER)|(1<<DISP3)|(1<<DISP4)
    OUT DDRC, TMP

    ; Apaga todas las salidas al inicio
    CBI PORTB, DISP1
    CBI PORTB, DISP2
    CBI PORTC, DISP3
    CBI PORTC, DISP4
    CBI PORTC, LED_HORA
    CBI PORTC, LED_FECHA
    CBI PORTC, BUZZER
    CBI PORTD, COLON

	; MODO EN EL QUE SE INICIA:


    ; Hora inicial 12:00:00
    LDI HOURS, 12
    CLR MINS
    CLR SECS

    ; Fecha inicial 25/03
    LDI TMP, 25
    MOV DAYS, TMP
    LDI TMP, 3
    MOV MONTHS, TMP

    ; Alarma inicial 00:00
    CLR ALM_HOURS
    CLR ALM_MINS


    ; Alarma apagada al inicio
    CLR ALARM_ACTIVE
    CLR ALARM_LATCH

    ; Colon apagado al inicio
    CLR COLON_STATE

    ; Modo inicial = hora
    ; Sin edicion al inicio
    CLR MODE
    CLR EDIT

    ; Inicializa contadores internos
    CLR TICKS // contador de overflows
    CLR HALF // contador de medios segundos
    CLR MUX // contador de multiplexado

    ; Configura Timer0
    RCALL RESET_TIMER0

    ; Habilita interrupciones globales
    SEI


MAIN:
    ; Prepara los 4 digitos que se deben mostrar
    RCALL UPDATE_DIGITS

    ; Actualiza LEDs segun el modo
    RCALL UPDATE_MODE_LEDS

    ; Revisa botones y actua si alguno fue presionado
    RCALL READ_BUTTONS

    ; Bucle infinito principal
    RJMP MAIN


; =========================
; TIMER0
; =========================

RESET_TIMER0:
    ; Carga prescaler de Timer0
    LDI TMP, PRESCALER0
    OUT TCCR0B, TMP

    ; Carga valor inicial del contador
    LDI TMP, TIMER_START0
    OUT TCNT0, TMP

    ; Habilita interrupcion por overflow de Timer0
    LDI TMP, (1<<TOIE0)
    STS TIMSK0, TMP
    RET


TIMER0_ISR:
    ; Guarda contexto minimo antes de trabajar
    PUSH R16
    PUSH R17
    IN   R16, SREG
    PUSH R16

    ; Reinicia configuracion del Timer0
    RCALL RESET_TIMER0

    ; Multiplexado
    ; Cambia el display activo en cada interrupcion
    INC MUX
    MOV TMP, MUX
    CPI TMP, 4
    BRLO T0_MUX_OK
    CLR MUX

T0_MUX_OK:
    RCALL DISPLAY

    ; Cuenta overflows para formar medio segundo
    INC TICKS
    MOV TMP, TICKS
    CPI TMP, HALFSEC
    BRNE T0_ALARM_LOGIC

    ; Si ya llego a HALFSEC, reinicia conteo
    CLR TICKS

    ; Cambia el estado logico del colon cada medio segundo
    ; Aqui no se enciende fisicamente PD7
    ; solo se guarda el estado en COLON_STATE
    MOV TMP, HALF
    TST TMP
    BREQ T0_COLON_SET

    CLR COLON_STATE
    RJMP T0_COLON_DONE

T0_COLON_SET:
    LDI TMP, 1
    MOV COLON_STATE, TMP

T0_COLON_DONE:

    ; Cada 2 medios segundos se cumple 1 segundo
    INC HALF
    MOV TMP, HALF
    CPI TMP, 2
    BRLO T0_ALARM_LOGIC

    ; Si ya paso 1 segundo, reinicia HALF
    CLR HALF

    ; El reloj solo avanza si no se esta editando
    MOV TMP, EDIT
    CPI TMP, EDIT_OFF
    BRNE T0_ALARM_LOGIC

    ; Incrementa segundos
    INC SECS
    MOV TMP, SECS
    CPI TMP, 60
    BRLO T0_ALARM_LOGIC

    ; Si segundos llega a 60, vuelve a 0 y suma minutos
    CLR SECS
    INC MINS
    MOV TMP, MINS
    CPI TMP, 60
    BRLO T0_ALARM_LOGIC

    ; Si minutos llega a 60, vuelve a 0 y suma horas
    CLR MINS
    INC HOURS
    MOV TMP, HOURS
    CPI TMP, 24
    BRLO T0_DAY_CHECK

    ; Si horas llega a 24, vuelve a 0
    CLR HOURS

T0_DAY_CHECK:
    ; Si ahora son las 00:00, incrementa automaticamente el dia
    MOV TMP, HOURS
    CPI TMP, 0
    BRNE T0_ALARM_LOGIC
    MOV TMP, MINS
    CPI TMP, 0
    BRNE T0_ALARM_LOGIC
    RCALL INCREMENT_DAY_AUTO


T0_ALARM_LOGIC:
    ; Si ya existe latch, no se vuelve a disparar la alarma
    ; hasta que cambie el minuto
    MOV TMP, ALARM_LATCH
    TST TMP
    BREQ T0_CHECK_TRIGGER

    ; Si ya no coincide la hora actual con la hora de alarma,
    ; se libera el latch
    MOV TMP, HOURS
    CP  TMP, ALM_HOURS
    BRNE T0_CLEAR_LATCH

    MOV TMP, MINS
    CP  TMP, ALM_MINS
    BRNE T0_CLEAR_LATCH

    ; Si todavia coincide, salta directo a controlar buzzer
    RJMP T0_BUZZ_OUTPUT

T0_CLEAR_LATCH:
    CLR ALARM_LATCH
    RJMP T0_BUZZ_OUTPUT

T0_CHECK_TRIGGER:
    ; La alarma no se dispara si se esta editando
    MOV TMP, EDIT
    CPI TMP, EDIT_OFF
    BRNE T0_BUZZ_OUTPUT

    ; Compara hora actual con hora de alarma
    MOV TMP, HOURS
    CP  TMP, ALM_HOURS
    BRNE T0_BUZZ_OUTPUT

    MOV TMP, MINS
    CP  TMP, ALM_MINS
    BRNE T0_BUZZ_OUTPUT

    ; Si coinciden, activa la alarma
    LDI TMP, 1
    MOV ALARM_ACTIVE, TMP
    MOV ALARM_LATCH, TMP

T0_BUZZ_OUTPUT:
    ; Si la alarma esta activa, enciende buzzer
    MOV TMP, ALARM_ACTIVE
    TST TMP
    BREQ T0_BUZZ_OFF

    SBI PORTC, BUZZER
    RJMP T0_END

T0_BUZZ_OFF:
    CBI PORTC, BUZZER

T0_END:
    ; Restaura contexto y sale de la ISR
    POP R16
    OUT SREG, R16
    POP R17
    POP R16
    RETI


; =========================
; LEDs de modo
; Hora   solo LED_HORA
; Fecha  solo LED_FECHA
; Alarma ambos LEDs
; =========================

UPDATE_MODE_LEDS:
    ; Apaga ambos LEDs primero
    CBI PORTC, LED_HORA
    CBI PORTC, LED_FECHA

    ; Si el modo es hora, enciende LED_HORA
    MOV TMP, MODE
    CPI TMP, MODE_HORA
    BREQ UML_HORA

    ; Si el modo es fecha, enciende LED_FECHA
    MOV TMP, MODE
    CPI TMP, MODE_FECHA
    BREQ UML_FECHA

    ; Si no es hora ni fecha, entonces es alarma
    ; Enciende ambos LEDs
    SBI PORTC, LED_HORA
    SBI PORTC, LED_FECHA
    RET

UML_HORA:
    SBI PORTC, LED_HORA
    RET

UML_FECHA:
    SBI PORTC, LED_FECHA
    RET


; =========================
; UPDATE_DIGITS
; Hora   HHMM
; Fecha  DDMM
; Alarma HHMM
; =========================


UPDATE_DIGITS:
    ; Decide que informacion se va a mostrar segun MODE
    MOV TMP, MODE
    CPI TMP, MODE_HORA
    BREQ UD_HORA_NEAR

    MOV TMP, MODE
    CPI TMP, MODE_FECHA
    BREQ UD_FECHA_NEAR

    ; Si no es hora ni fecha, muestra alarma
    RJMP UD_BUILD_ALARMA

UD_HORA_NEAR:
    RJMP UD_BUILD_HORA

UD_FECHA_NEAR:
    RJMP UD_BUILD_FECHA


UD_BUILD_ALARMA:
    ; Convierte hora de alarma en decenas y unidades
    MOV TMP, ALM_HOURS
    RCALL DIV10
    MOV DB1, TMP

    MOV TMP, ALM_HOURS
    RCALL MOD10
    MOV DB2, TMP

    ; Convierte minutos de alarma en decenas y unidades
    MOV TMP, ALM_MINS
    RCALL DIV10
    MOV DB3, TMP

    MOV TMP, ALM_MINS
    RCALL MOD10
    MOV DB4, TMP
    RET


UD_BUILD_FECHA:
    ; Convierte dia en decenas y unidades
    MOV TMP, DAYS
    RCALL DIV10
    MOV DB1, TMP

    MOV TMP, DAYS
    RCALL MOD10
    MOV DB2, TMP

    ; Convierte mes en decenas y unidades
    MOV TMP, MONTHS
    RCALL DIV10
    MOV DB3, TMP

    MOV TMP, MONTHS
    RCALL MOD10
    MOV DB4, TMP
    RET


UD_BUILD_HORA:
    ; Convierte hora actual en decenas y unidades
    MOV TMP, HOURS
    RCALL DIV10
    MOV DB1, TMP

    MOV TMP, HOURS
    RCALL MOD10
    MOV DB2, TMP

    ; Convierte minutos actuales en decenas y unidades
    MOV TMP, MINS
    RCALL DIV10
    MOV DB3, TMP

    MOV TMP, MINS
    RCALL MOD10
    MOV DB4, TMP
    RET


; =========================
; DISPLAY
; =========================


DISPLAY:
    ; Apaga todos los displays antes de encender uno
    ; Esto evita que queden dos activos a la vez
    CBI PORTB, DISP1
    CBI PORTB, DISP2
    CBI PORTC, DISP3
    CBI PORTC, DISP4

    ; Selecciona cual display encender segun MUX
    MOV TMP, MUX
    CPI TMP, 0
    BREQ DISP1_NEAR
    MOV TMP, MUX
    CPI TMP, 1
    BREQ DISP2_NEAR
    MOV TMP, MUX
    CPI TMP, 2
    BREQ DISP3_NEAR
    RJMP DISP_D4

DISP1_NEAR:
    RJMP DISP_D1
DISP2_NEAR:
    RJMP DISP_D2
DISP3_NEAR:
    RJMP DISP_D3

DISP_D1:
    ; Carga DB1 en segmentos
    ; Asegura que el colon quede apagado porque no pertenece a DIG1
    MOV TMP, DB1
    RCALL SEGMENT
    CBI PORTD, COLON
    SBI PORTB, DISP1
    RET

DISP_D2:
    ; Carga DB2 en segmentos
    ; Luego aplica el estado del colon
    ; porque el colon pertenece a DIG2
    MOV TMP, DB2
    RCALL SEGMENT

    MOV TMP, COLON_STATE
    TST TMP
    BREQ DISP_D2_COLON_OFF
    SBI PORTD, COLON
    RJMP DISP_D2_DONE

DISP_D2_COLON_OFF:
    CBI PORTD, COLON

DISP_D2_DONE:
    SBI PORTB, DISP2
    RET

DISP_D3:
    ; Carga DB3 en segmentos
    ; Asegura que el colon quede apagado porque no pertenece a DIG3
    MOV TMP, DB3
    RCALL SEGMENT
    CBI PORTD, COLON
    SBI PORTC, DISP3
    RET

DISP_D4:
    ; Carga DB4 en segmentos
    ; Asegura que el colon quede apagado porque no pertenece a DIG4
    MOV TMP, DB4
    RCALL SEGMENT
    CBI PORTD, COLON
    SBI PORTC, DISP4
    RET


; =========================
; BOTONES
; Si la alarma esta activa,
; cualquier boton solo la apaga
; =========================


READ_BUTTONS:
    ; Primero revisa si la alarma esta activa
    MOV TMP, ALARM_ACTIVE
    TST TMP
    BREQ RB_NORMAL

    ; Si la alarma esta activa, cualquier boton la silencia
    SBIS PINB, BTN_MODE
    RJMP SILENCE_ALARM
    SBIS PINB, BTN_EDIT
    RJMP SILENCE_ALARM
    SBIS PINB, BTN_UP
    RJMP SILENCE_ALARM
    SBIS PINB, BTN_DOWN
    RJMP SILENCE_ALARM
    RET

SILENCE_ALARM:
    ; Espera un poco por antirebote
    RCALL DEBOUNCE

    ; Apaga estado de alarma
    CLR ALARM_ACTIVE
    CBI PORTC, BUZZER

SA_WAIT_RELEASE:
    ; Espera hasta que todos los botones queden liberados
    SBIS PINB, BTN_MODE
    RJMP SA_WAIT_RELEASE
    SBIS PINB, BTN_EDIT
    RJMP SA_WAIT_RELEASE
    SBIS PINB, BTN_UP
    RJMP SA_WAIT_RELEASE
    SBIS PINB, BTN_DOWN
    RJMP SA_WAIT_RELEASE
    RET


RB_NORMAL:
    ; Si no hay alarma sonando, revisa botones normalmente
    SBIS PINB, BTN_MODE
    RCALL HANDLE_MODE

    SBIS PINB, BTN_EDIT
    RCALL HANDLE_EDIT

    SBIS PINB, BTN_UP
    RCALL HANDLE_UP

    SBIS PINB, BTN_DOWN
    RCALL HANDLE_DOWN
    RET


HANDLE_MODE:
    ; Antirebote
    RCALL DEBOUNCE

    ; Si ya se solto el boton, salir
    SBIC PINB, BTN_MODE
    RET

    ; Cambia entre hora, fecha y alarma
    MOV TMP, MODE
    CPI TMP, MODE_HORA
    BREQ HM_FECHA_NEAR

    MOV TMP, MODE
    CPI TMP, MODE_FECHA
    BREQ HM_ALARMA_NEAR

    ; Si estaba en alarma, vuelve a hora
    CLR MODE
    CLR EDIT
    RJMP HM_WAIT_REL

HM_FECHA_NEAR:
    ; Si estaba en hora, pasa a fecha
    LDI MODE, MODE_FECHA
    CLR EDIT
    RJMP HM_WAIT_REL

HM_ALARMA_NEAR:
    ; Si estaba en fecha, pasa a alarma
    LDI MODE, MODE_ALARMA
    CLR EDIT

HM_WAIT_REL:
    ; Espera a que el boton se suelte
    SBIS PINB, BTN_MODE
    RJMP HM_WAIT_REL
    RET


HANDLE_EDIT:
    ; Antirebote
    RCALL DEBOUNCE

    ; Si ya se solto el boton, salir
    SBIC PINB, BTN_EDIT
    RET

    ; Cambia entre:
    ; EDIT_OFF
    ; EDIT_FIRST
    ; EDIT_LAST
    MOV TMP, EDIT
    CPI TMP, EDIT_OFF
    BREQ HE_FIRST_NEAR

    MOV TMP, EDIT
    CPI TMP, EDIT_FIRST
    BREQ HE_LAST_NEAR

    ; Si estaba en EDIT_LAST, vuelve a EDIT_OFF
    CLR EDIT
    RJMP HE_WAIT_REL

HE_FIRST_NEAR:
    ; Pasa a editar primer campo
    LDI EDIT, EDIT_FIRST
    RJMP HE_WAIT_REL

HE_LAST_NEAR:
    ; Pasa a editar segundo campo
    LDI EDIT, EDIT_LAST

HE_WAIT_REL:
    ; Espera soltar boton
    SBIS PINB, BTN_EDIT
    RJMP HE_WAIT_REL
    RET


HANDLE_UP:
    ; Antirebote
    RCALL DEBOUNCE

    ; Si ya se solto, salir
    SBIC PINB, BTN_UP
    RET

    ; Decide que incrementar segun modo actual
    MOV TMP, MODE
    CPI TMP, MODE_HORA
    BREQ HU_HORA_NEAR

    MOV TMP, MODE
    CPI TMP, MODE_FECHA
    BREQ HU_FECHA_NEAR

    ; Si no es hora ni fecha, es alarma
    RJMP HU_ALARMA

HU_HORA_NEAR:
    RJMP HU_HORA
HU_FECHA_NEAR:
    RJMP HU_FECHA

HU_ALARMA:
    ; En modo alarma, EDIT_FIRST edita horas y EDIT_LAST minutos
    MOV TMP, EDIT
    CPI TMP, EDIT_FIRST
    BREQ HU_ALM_H_NEAR
    MOV TMP, EDIT
    CPI TMP, EDIT_LAST
    BREQ HU_ALM_M_NEAR
    RJMP HU_WAIT_REL

HU_ALM_H_NEAR:
    RJMP INC_ALM_HOUR
HU_ALM_M_NEAR:
    RJMP INC_ALM_MIN

HU_FECHA:
    ; En modo fecha, EDIT_FIRST edita dia y EDIT_LAST mes
    MOV TMP, EDIT
    CPI TMP, EDIT_FIRST
    BREQ HU_DAY_NEAR
    MOV TMP, EDIT
    CPI TMP, EDIT_LAST
    BREQ HU_MON_NEAR
    RJMP HU_WAIT_REL

HU_DAY_NEAR:
    RJMP INC_DAY
HU_MON_NEAR:
    RJMP INC_MONTH

HU_HORA:
    ; En modo hora, EDIT_FIRST edita horas y EDIT_LAST minutos
    MOV TMP, EDIT
    CPI TMP, EDIT_FIRST
    BREQ HU_HOUR_NEAR
    MOV TMP, EDIT
    CPI TMP, EDIT_LAST
    BREQ HU_MIN_NEAR

HU_WAIT_REL:
    ; Si no habia campo valido en edicion, solo espera soltar boton
    SBIS PINB, BTN_UP
    RJMP HU_WAIT_REL
    RET

HU_HOUR_NEAR:
    RJMP INC_HOUR
HU_MIN_NEAR:
    RJMP INC_MIN


HANDLE_DOWN:
    ; Antirebote
    RCALL DEBOUNCE

    ; Si ya se solto, salir
    SBIC PINB, BTN_DOWN
    RET

    ; Decide que decrementar segun modo actual
    MOV TMP, MODE
    CPI TMP, MODE_HORA
    BREQ HD_HORA_NEAR

    MOV TMP, MODE
    CPI TMP, MODE_FECHA
    BREQ HD_FECHA_NEAR

    ; Si no es hora ni fecha, es alarma
    RJMP HD_ALARMA

HD_HORA_NEAR:
    RJMP HD_HORA
HD_FECHA_NEAR:
    RJMP HD_FECHA

HD_ALARMA:
    ; En modo alarma, EDIT_FIRST edita horas y EDIT_LAST minutos
    MOV TMP, EDIT
    CPI TMP, EDIT_FIRST
    BREQ HD_ALM_H_NEAR
    MOV TMP, EDIT
    CPI TMP, EDIT_LAST
    BREQ HD_ALM_M_NEAR
    RJMP HD_WAIT_REL

HD_ALM_H_NEAR:
    RJMP DEC_ALM_HOUR
HD_ALM_M_NEAR:
    RJMP DEC_ALM_MIN

HD_FECHA:
    ; En modo fecha, EDIT_FIRST edita dia y EDIT_LAST mes
    MOV TMP, EDIT
    CPI TMP, EDIT_FIRST
    BREQ HD_DAY_NEAR
    MOV TMP, EDIT
    CPI TMP, EDIT_LAST
    BREQ HD_MON_NEAR
    RJMP HD_WAIT_REL

HD_DAY_NEAR:
    RJMP DEC_DAY
HD_MON_NEAR:
    RJMP DEC_MONTH

HD_HORA:
    ; En modo hora, EDIT_FIRST edita horas y EDIT_LAST minutos
    MOV TMP, EDIT
    CPI TMP, EDIT_FIRST
    BREQ HD_HOUR_NEAR
    MOV TMP, EDIT
    CPI TMP, EDIT_LAST
    BREQ HD_MIN_NEAR

HD_WAIT_REL:
    ; Si no habia campo valido en edicion, solo espera soltar boton
    SBIS PINB, BTN_DOWN
    RJMP HD_WAIT_REL
    RET

HD_HOUR_NEAR:
    RJMP DEC_HOUR
HD_MIN_NEAR:
    RJMP DEC_MIN


; =========================
; INC / DEC HORA
; =========================

INC_HOUR:
    ; Incrementa hora y hace wrap de 23 a 0
    INC HOURS
    MOV TMP, HOURS
    CPI TMP, 24
    BRLO IH_WAIT
    CLR HOURS
IH_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_UP
    RJMP IH_WAIT
    RET

INC_MIN:
    ; Incrementa minutos y hace wrap de 59 a 0
    INC MINS
    MOV TMP, MINS
    CPI TMP, 60
    BRLO IM_WAIT
    CLR MINS
IM_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_UP
    RJMP IM_WAIT
    RET

DEC_HOUR:
    ; Si hora es 0, pasa a 23
    MOV TMP, HOURS
    TST TMP
    BRNE DH_OK
    LDI HOURS, 23
    RJMP DH_WAIT
DH_OK:
    ; Si no era 0, decrementa normalmente
    DEC HOURS
DH_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_DOWN
    RJMP DH_WAIT
    RET

DEC_MIN:
    ; Si minuto es 0, pasa a 59
    MOV TMP, MINS
    TST TMP
    BRNE DM_OK
    LDI MINS, 59
    RJMP DM_WAIT
DM_OK:
    ; Si no era 0, decrementa normalmente
    DEC MINS
DM_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_DOWN
    RJMP DM_WAIT
    RET


; =========================
; INC / DEC FECHA
; EDIT_FIRST = dia
; EDIT_LAST  = mes
; =========================

INC_DAY:
    ; Incrementa el dia
    INC DAYS

    ; Ajusta si se paso del maximo del mes
    RCALL CLAMP_OR_WRAP_DAY
INCD_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_UP
    RJMP INCD_WAIT
    RET

INC_MONTH:
    ; Incrementa el mes
    INC MONTHS
    MOV TMP, MONTHS
    CPI TMP, 13
    BRLO INCM_OK

    ; Si pasa de 12, vuelve a 1
    LDI TMP, 1
    MOV MONTHS, TMP

INCM_OK:
    ; Ajusta el dia si ese mes no soporta el valor actual
    RCALL CLAMP_DAY_TO_MONTH
INCM_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_UP
    RJMP INCM_WAIT
    RET

DEC_DAY:
    ; Si el dia es 1, lo pone al maximo del mes
    MOV TMP, DAYS
    CPI TMP, 1
    BRNE DECD_OK
    RCALL LOAD_MAX_DAY
    MOV DAYS, TMP
    RJMP DECD_WAIT
DECD_OK:
    ; Si no era 1, decrementa dia normalmente
    DEC DAYS
DECD_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_DOWN
    RJMP DECD_WAIT
    RET

DEC_MONTH:
    ; Si el mes es 1, pasa a 12
    MOV TMP, MONTHS
    CPI TMP, 1
    BRNE DECM_OK
    LDI TMP, 12
    MOV MONTHS, TMP
    RJMP DECM_DONE
DECM_OK:
    ; Si no era 1, decrementa normalmente
    DEC MONTHS
DECM_DONE:
    ; Ajusta el dia si hace falta
    RCALL CLAMP_DAY_TO_MONTH
DECM_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_DOWN
    RJMP DECM_WAIT
    RET


; =========================
; INC / DEC ALARMA
; =========================

INC_ALM_HOUR:
    ; Incrementa hora de alarma y hace wrap de 23 a 0
    INC ALM_HOURS
    MOV TMP, ALM_HOURS
    CPI TMP, 24
    BRLO IAH_WAIT
    CLR ALM_HOURS
IAH_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_UP
    RJMP IAH_WAIT
    RET

INC_ALM_MIN:
    ; Incrementa minuto de alarma y hace wrap de 59 a 0
    INC ALM_MINS
    MOV TMP, ALM_MINS
    CPI TMP, 60
    BRLO IAM_WAIT
    CLR ALM_MINS
IAM_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_UP
    RJMP IAM_WAIT
    RET

DEC_ALM_HOUR:
    ; Si hora de alarma es 0, pasa a 23
    MOV TMP, ALM_HOURS
    TST TMP
    BRNE DAH_OK
    LDI TMP, 23
    MOV ALM_HOURS, TMP
    RJMP DAH_WAIT
DAH_OK:
    ; Si no era 0, decrementa normalmente
    DEC ALM_HOURS
DAH_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_DOWN
    RJMP DAH_WAIT
    RET

DEC_ALM_MIN:
    ; Si minuto de alarma es 0, pasa a 59
    MOV TMP, ALM_MINS
    TST TMP
    BRNE DAM_OK
    LDI TMP, 59
    MOV ALM_MINS, TMP
    RJMP DAM_WAIT
DAM_OK:
    ; Si no era 0, decrementa normalmente
    DEC ALM_MINS
DAM_WAIT:
    ; Espera a que se suelte el boton
    SBIS PINB, BTN_DOWN
    RJMP DAM_WAIT
    RET


; =========================
; VALIDACION DE MES
; =========================

CLAMP_OR_WRAP_DAY:
    ; Obtiene el maximo dia valido segun el mes actual
    RCALL LOAD_MAX_DAY

    ; Si DAYS es menor o igual al maximo, no cambia nada
    CP DAYS, TMP
    BREQ COWD_OK
    BRLO COWD_OK

    ; Si DAYS es mayor al maximo, vuelve a 1
    LDI TMP2, 1
    MOV DAYS, TMP2
COWD_OK:
    RET


CLAMP_DAY_TO_MONTH:
    ; Obtiene el maximo dia valido segun el mes actual
    RCALL LOAD_MAX_DAY

    ; Si el dia actual es mayor que el maximo permitido,
    ; se ajusta al maximo
    CP TMP, DAYS
    BRLO CDTM_DO
    RET
CDTM_DO:
    MOV DAYS, TMP
    RET


LOAD_MAX_DAY:
    ; Determina el numero maximo de dias del mes actual
    ; Resultado queda en TMP

    ; Febrero
    MOV TMP, MONTHS
    CPI TMP, 2
    BREQ LMD_28

    ; Meses de 30 dias
    MOV TMP, MONTHS
    CPI TMP, 4
    BREQ LMD_30
    MOV TMP, MONTHS
    CPI TMP, 6
    BREQ LMD_30
    MOV TMP, MONTHS
    CPI TMP, 9
    BREQ LMD_30
    MOV TMP, MONTHS
    CPI TMP, 11
    BREQ LMD_30
	g
    ; Resto de meses tienen 31 dias
    LDI TMP, 31
    RET

LMD_30:
    LDI TMP, 30
    RET

LMD_28:
    LDI TMP, 28
    RET


INCREMENT_DAY_AUTO:
    ; Incrementa el dia automaticamente al pasar medianoche
    INC DAYS
    RCALL CLAMP_OR_WRAP_DAY

    ; Si el dia quedo en 1, significa que el mes cambio
    MOV TMP, DAYS
    CPI TMP, 1
    BRNE IDA_DONE

    ; Incrementa mes
    INC MONTHS
    MOV TMP, MONTHS
    CPI TMP, 13
    BRLO IDA_DONE

    ; Si el mes llega a 13, vuelve a 1
    LDI TMP, 1
    MOV MONTHS, TMP

IDA_DONE:
    RET


; =========================
; DEBOUNCE
; =========================


DEBOUNCE:
    ; Retardo simple para reducir rebote mecanico del boton
    LDI TMP, 200
DB_LOOP:
    DEC TMP
    BRNE DB_LOOP
    RET


; =========================
; SEGMENTOS
; TMP = numero de 0 a 9
; conserva PD7 para no alterar el colon
; =========================


SEGMENT:
    ; Copia el numero de entrada
    MOV TMP2, TMP

    ; Compara y salta al patron correcto
    CPI TMP2, 0
    BREQ S0
    CPI TMP2, 1
    BREQ S1
    CPI TMP2, 2
    BREQ S2
    CPI TMP2, 3
    BREQ S3
    CPI TMP2, 4
    BREQ S4
    CPI TMP2, 5
    BREQ S5
    CPI TMP2, 6
    BREQ S6
    CPI TMP2, 7
    BREQ S7
    CPI TMP2, 8
    BREQ S8
    RJMP S9

S0:
    ; Patron de segmentos para mostrar 0
    LDI TMP2, 0b00111111
    RJMP OUTSEG

S1:
    ; Patron de segmentos para mostrar 1
    LDI TMP2, 0b00000110
    RJMP OUTSEG

S2:
    ; Patron de segmentos para mostrar 2
    LDI TMP2, 0b01011011
    RJMP OUTSEG

S3:
    ; Patron de segmentos para mostrar 3
    LDI TMP2, 0b01001111
    RJMP OUTSEG

S4:
    ; Patron de segmentos para mostrar 4
    LDI TMP2, 0b01100110
    RJMP OUTSEG

S5:
    ; Patron de segmentos para mostrar 5
    LDI TMP2, 0b01101101
    RJMP OUTSEG

S6:
    ; Patron de segmentos para mostrar 6
    LDI TMP2, 0b01111101
    RJMP OUTSEG

S7:
    ; Patron de segmentos para mostrar 7
    LDI TMP2, 0b00000111
    RJMP OUTSEG

S8:
    ; Patron de segmentos para mostrar 8
    LDI TMP2, 0b01111111
    RJMP OUTSEG

S9:
    ; Patron de segmentos para mostrar 9
    LDI TMP2, 0b01101111

OUTSEG:
    ; Lee PORTD actual para conservar el estado de PD7
    ; PD7 corresponde al colon y no debe borrarse al cambiar segmentos
    IN TMP, PORTD
    ANDI TMP, 0b10000000

    ; Combina el patron del numero con el estado actual del colon
    OR TMP2, TMP

    ; Escribe el resultado final en PORTD
    OUT PORTD, TMP2
    RET


; =========================
; DIV10 / MOD10
; =========================

DIV10:
    ; Calcula la parte entera de TMP / 10
    ; Ejemplo: si TMP = 25, devuelve 2
    CLR TMP2
DIV10_LOOP:
    CPI TMP, 10
    BRLO DIV10_DONE
    SUBI TMP, 10
    INC TMP2
    RJMP DIV10_LOOP
DIV10_DONE:
    MOV TMP, TMP2
    RET


MOD10:
    ; Calcula el residuo de TMP / 10
    ; Ejemplo: si TMP = 25, devuelve 5
MOD10_LOOP:
    CPI TMP, 10
    BRLO MOD10_DONE
    SUBI TMP, 10
    RJMP MOD10_LOOP
MOD10_DONE:
    RET