; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;	=-=-=-=-=-=-=-   DISCIPLINA SISTEMAS MICROPROCESSADOS   -=-=-=-=-=-=-=-=
;	PROGRAMA MODELO N�MERO ZERO PARA MICROCONTROLADORES PIC16F877
;	MAURICIO DOS SANTOS KASTER
;	AGO/2008
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#INCLUDE <P16F877A.INC>
	__CONFIG _CP_OFF & _CPD_OFF & _DEBUG_OFF & _LVP_OFF & _WRT_OFF & _BODEN_ON & _PWRTE_ON & _WDT_OFF & _HS_OSC

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                         DEFINI��O DAS VARI�VEIS
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; VARI�VEIS DO USU�RIO LOCALIZADAS A PARTIR DO ENDERE�O 0X20 DA RAM

	CBLOCK	0X20
		CONT
		CT
		C1
		C2
		C3
		BITMAP
		TEMP
		DISP1		; VALORES DOS DISPLAYS, TROCADOS POR INTERRUP��O
		DISP2
		DISP3
		DISP4
		CTT0		; CONTAGEM DAS INTERRUP��ES DO TIMER 0
	ENDC

; VARI�VEIS COM ENDERE�O ESPEC�FICO

W_TEMP			EQU		0X7E
STATUS_TEMP		EQU		0X7F

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      DECLARA��O DAS MACROS
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;#INCLUDE "MACROS.ASM"

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      DEFINI��O DOS BANCOS DE RAM
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; J� inclu�dos na declara��o das macros.
#DEFINE	BANK1	BSF	STATUS,RP0 	; SELECIONA BANK1 DA MEMORIA RAM
#DEFINE	BANK0	BCF	STATUS,RP0	; SELECIONA BANK0 DA MEMORIA RAM

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                          ENTRADAS E SA�DAS DO KIT PICGENIOS
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; BOTOES
#DEFINE		BT1			PORTB,3
#DEFINE		BT2			PORTB,4
#DEFINE		BT3			PORTB,5
#DEFINE		BT4			PORTA,5
#DEFINE		BTX			PORTB,2
#DEFINE		BTY			PORTB,1
#DEFINE		BTZ			PORTB,0
; TECLADO MATRICIAL
#DEFINE		LIN1		PORTD,0
#DEFINE		LIN2		PORTD,1
#DEFINE		LIN3		PORTD,2
#DEFINE		LIN4		PORTD,3
#DEFINE		COL1		PORTB,0
#DEFINE		COL2		PORTB,1
#DEFINE		COL3		PORTB,2
; DISPLAY DE 7 SEGMENTOS
#DEFINE		SEGMENTOS	PORTD
#DEFINE		SEGA		SEGMENTOS,0
#DEFINE		SEGB		SEGMENTOS,1
#DEFINE		SEGC		SEGMENTOS,2
#DEFINE		SEGD		SEGMENTOS,3
#DEFINE		SEGE		SEGMENTOS,4
#DEFINE		SEGF		SEGMENTOS,5
#DEFINE		SEGG		SEGMENTOS,6
#DEFINE		SEGP		SEGMENTOS,7
#DEFINE		ENDISP1		PORTA,2
#DEFINE		ENDISP2		PORTA,3
#DEFINE		ENDISP3		PORTA,4
#DEFINE		ENDISP4		PORTA,5
; DISPLAY LCD
#DEFINE		DADOS		PORTD
#DEFINE		RS			PORTE,2		; 1->DADO  0->COMANDO
#DEFINE		ENABLE		PORTE,1

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                   VETOR DE RESET DO MICROCONTROLADOR
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  POSI��O INICIAL PARA EXECU��O DO PROGRAMA

		ORG		0X0000		; ENDERE�O DO VETOR DE RESET
		GOTO	INICIO		; DESVIA PARA O IN�CIO DO PROGRAMA

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                             INTERRUP��ES
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

		ORG		0x0004		; ENDERE�O DO VETOR DE INTERRUP��ES
		MOVWF	W_TEMP			; W -> W_TEMP
		SWAPF	STATUS,W		; TROCA NIBBLES STATUS -> W
		MOVWF	STATUS_TEMP		; W -> STATUS_TEMP
		BCF		STATUS,RP0		; Assegura o BANCO 0 ativo
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
		BCF		INTCON,T0IF		; LIMPA O FLAG DA INTERRUP��O DO TIMER 0
		;GOTO	FIMINT
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
FIMINT	SWAPF	STATUS_TEMP,W	; TROCA NIBBLES DE STATUS_TEMP -> W
		MOVWF	STATUS			; W -> STATUS
		SWAPF	W_TEMP,F		; TROCA NIBBLES DE W_TEMP -> W_TEMP
		SWAPF	W_TEMP,W		; TROCA NIBBLES DE W_TEMP -> W
		RETFIE				; FINALIZA A INTERRUP��O

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                         PROGRAMA PRINCIPAL
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

INICIO	MOVLW	D'0'
		MOVWF	CONT
REP1	INCF	CONT,F
		MOVF	CONT,W
		SUBLW	D'9'
		BTFSS	STATUS,Z
		GOTO	REP1
		GOTO	INICIO

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                            SUBROTINAS
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                            FIM DO PROGRAMA
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

		END				; FIM DO PROGRAMA
