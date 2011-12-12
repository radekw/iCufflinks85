;.include "tn4def.inc"

.equ    LED = 0				; LED connected to PB0

.cseg

.org 0x0000		;Set address of next statement
	rjmp RESET	; Address 0x0000 (RESET)
	reti		; Address 0x0001
	reti		; Address 0x0002
	reti		; Address 0x0003
	reti		; Address 0x0004
	reti		; Address 0x0005
	reti		; Address 0x0006
	reti		; Address 0x0007
	reti		; Address 0x0008
	reti		; Address 0x0009
	reti		; Address 0x000A
	reti		; Address 0x000B
	reti		; Address 0x000C (WDT)
	reti		; Address 0x000D
	reti		; Address 0x000E

.def	temp   		= R16	; general purpose temp

RESET:
	sbi DDRB, LED ; LED output
	sbi PORTB, LED ; LED off

	; setting all pullups on unused pins (for power savings)
	; would having them all be outputs use less power?
	ldi temp, (1<<PORTB5)|(1<<PORTB4)|(1<<PORTB3)|(1<<PORTB2)|(1<<PORTB1)
	out PORTB, temp

	; Fast PWM (WGM[2:0] = 011), COM0A1 = 1, COM0A0 = 0
	ldi temp, 0b11000011
	out TCCR0A, temp
	; fastest clock
	ldi temp, 0b00000001
	out TCCR0B, temp

	; enable sleep mode
	ldi temp, (1<<SE) ; by default the mode is 000 Idle
	out MCUCR, temp

	sei		; enable global interrupts

LOOPSTART:
	ldi ZH,	high(SINETAB*2)
	ldi ZL, low (SINETAB*2) ; init Z-pointer to storage bytes

LOOP:
	LPM		temp, Z+		; read SINETAB value and increment Z
	cpi		temp, 0			; compare temp to 0
	brne	NORELOAD		; if temp =! 0, jump to NORELOAD
    rjmp	LOOPSTART

NORELOAD:
	out OCR0A, temp ; Shove the brightness into the PWM driver

	; set watchdog in interrupt mode and 4k cycles
	ldi temp, (0<<WDRF)
	out MCUSR, temp
	in temp, WDTCR
	ori temp, (1<<WDCE)|(1<<WDE)|(1<<WDIE)|(1<<WDP0)
	out WDTCR, temp
	ori temp, (0<<WDE)
	out WDTCR, temp
	; reset the watchdog timer to full value and sleep until it pops an interrupt
	wdr
	sleep

	rjmp	LOOP

SINETAB:
.db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 5, 8, 11, 15, 20, 25, 30, 36, 43, 49, 56, 64, 72, 80, 88, 97, 105, 114, 123, 132, 141, 150, 158, 167, 175, 183, 191, 199, 206, 212, 219, 225, 230, 235, 240, 244, 247, 250, 250, 250, 250, 252, 253, 254, 255, 254, 253, 252, 250, 247, 244, 240, 235, 230, 225, 219, 212, 206, 199, 191, 183, 175, 167, 158, 150, 141, 132, 123, 114, 105, 97, 88, 80, 72, 64, 56, 49, 43, 36, 30, 25, 20, 15, 11, 8, 5, 3, 2, 1, 0
