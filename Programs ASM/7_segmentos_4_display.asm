; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;	=-=-=-=-=-=-=-   DISCIPLINA SISTEMAS MICROPROCESSADOS   -=-=-=-=-=-=-=-=
;	PROGRAMA MODELO NÚMERO ZERO PARA MICROCONTROLADORES PIC16F877
;	MAURICIO DOS SANTOS KASTER
;	ALUNO: DANIEL KOSLOPP
;	AGO/2008
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

#INCLUDE <P16F877A.INC>
	__CONFIG _CP_OFF & _CPD_OFF & _DEBUG_OFF & _LVP_OFF & _WRT_OFF & _BODEN_ON & _PWRTE_ON & _WDT_OFF & _HS_OSC

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                         DEFINIÇÃO DAS VARIÁVEIS
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; VARIÁVEIS DO USUÁRIO LOCALIZADAS A PARTIR DO ENDEREÇO 0X20 DA RAM

	CBLOCK	0X20
		C1
		C2
		C3
		CONT
		TEMP
		BITMAP
	ENDC

#DEFINE		BITANT		BITMAP,0	;CONDIÇÃO ANTERIOR DE BOTAO
#DEFINE		TIPO_PISCA	BITMAP,1	;TIPO ATUAL DO PISCA (0:TODOS JUNTOS 1:ALTERNADO)

; VARIÁVEIS COM ENDEREÇO ESPECÍFICO

W_TEMP			EQU		0X7E
STATUS_TEMP		EQU		0X7F

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      DECLARAÇÃO DAS MACROS
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;#INCLUDE "MACROS.ASM"

COMPBIT	MACRO	F1,B1,F2,B2,DIFERENTES
		LOCAL	ZERO,IGUAIS

		BTFSS	F1,B1
		GOTO	ZERO
		BTFSC	F2,B2
		GOTO 	IGUAIS
		GOTO 	DIFERENTES

ZERO	BTFSC	F2,B2
		GOTO 	DIFERENTES

IGUAIS
		ENDM

MOVLF	MACRO	LITERAL,FILE
		MOVLW	LITERAL
		MOVWF	FILE
		ENDM
		
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                      DEFINIÇÃO DOS BANCOS DE RAM
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; Já incluídos na declaração das macros.
#DEFINE  BANK1  BSF	STATUS,RP0 	; SELECIONA BANK1 DA MEMORIA RAM
#DEFINE  BANK0  BCF	STATUS,RP0	; SELECIONA BANK0 DA MEMORIA RAM

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                          ENTRADAS E SAÍDAS DO KIT PICGENIOS
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
#DEFINE		BITDISP1	BITMAP,0
#DEFINE		BITDISP2	BITMAP,1
#DEFINE		BITDISP3	BITMAP,2
#DEFINE		BITDISP4	BITMAP,3
; DISPLAY LCD
#DEFINE		DADOS		PORTD
#DEFINE		RS			PORTE,2		; 1->DADO  0->COMANDO
#DEFINE		ENABLE		PORTE,1

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                   VETOR DE RESET DO MICROCONTROLADOR
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;  POSIÇÃO INICIAL PARA EXECUÇÃO DO PROGRAMA

		ORG		0X0000		; ENDEREÇO DO VETOR DE RESET
		GOTO	INICIO		; DESVIA PARA O INÍCIO DO PROGRAMA

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                             INTERRUPÇÕES
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

		ORG		0x0004		; ENDEREÇO DO VETOR DE INTERRUPÇÕES
		MOVWF	W_TEMP			; W -> W_TEMP
		SWAPF	STATUS,W		; TROCA NIBBLES STATUS -> W
		MOVWF	STATUS_TEMP		; W -> STATUS_TEMP
		BCF		STATUS,RP0		; Assegura o BANCO 0 ativo
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
		
		BCF		INTCON,TMR0IF	;LIMPA FLAG INT
		DECFSZ	CONT			;DECREMENTA E TEMPO 250ms ATINGIDO?
		GOTO	FIMINT			;NAO: FIM INTERRUPCAO
		
		MOVLF	.5,CONT

		BTFSC	BITDISP1
		GOTO	DISPLAY_2
		BTFSC	BITDISP2
		GOTO	DISPLAY_3
		BTFSC	BITDISP3
		GOTO	DISPLAY_4
		GOTO	DISPLAY_1

DISPLAY_4
		BCF		ENDISP3
		BCF		BITDISP3
		MOVLW	.3
		CALL	DECODIFICADOR
		MOVWF	PORTD
		BSF		ENDISP4
		BSF		BITDISP4
		GOTO	FIMINT

DISPLAY_3
		BCF		ENDISP2
		BCF		BITDISP2
		MOVLW	.2
		CALL	DECODIFICADOR
		MOVWF	PORTD
		BSF		ENDISP3
		BSF		BITDISP3
		GOTO	FIMINT

DISPLAY_2
		BCF		ENDISP1
		BCF		BITDISP1
		MOVLW	.1
		CALL	DECODIFICADOR
		MOVWF	PORTD
		BSF		ENDISP2
		BSF		BITDISP2
		GOTO	FIMINT

DISPLAY_1
		BCF		ENDISP4
		BCF		BITDISP4
		MOVLW	.0
		CALL	DECODIFICADOR
		MOVWF	PORTD
		BSF		ENDISP1
		BSF		BITDISP1
		GOTO	FIMINT
	

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
FIMINT	SWAPF	STATUS_TEMP,W	; TROCA NIBBLES DE STATUS_TEMP -> W
		MOVWF	STATUS			; W -> STATUS
		SWAPF	W_TEMP,F		; TROCA NIBBLES DE W_TEMP -> W_TEMP
		SWAPF	W_TEMP,W		; TROCA NIBBLES DE W_TEMP -> W
		RETFIE				; FINALIZA A INTERRUPÇÃO

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                         PROGRAMA PRINCIPAL
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

INICIO
		
		BANK1
		MOVLW	B'00000011'		;PRESCALE 1:16 PARA 10ms
		MOVWF	OPTION_REG
		MOVLF	0X06,ADCON1
		MOVLF	B'11000011',TRISA
		CLRF	TRISD
	
		BANK0
		MOVLW	.5				;CARREGA VALOR PARA CONTAGEM DE 10ms
		MOVWF	CONT
		MOVLW	B'10100000'		;HABILITA INTERRUPCAO POR TIMER0
		MOVWF	INTCON
		CLRF	PORTD
		MOVLF	B'00000100',PORTA
		MOVLF	B'00000001',BITMAP
		CLRF	CONT

CICLO
		NOP
		NOP
		GOTO	$-2

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                            SUBROTINAS
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


DELAY	;CALCULAR 250ms
		
		MOVWF	C3
		MOVLW	D'130'
		MOVWF	C2
		MOVLW	D'222'
		MOVWF	C1
		DECFSZ	C1,F
		GOTO	$-1
		DECFSZ	C2,F
		GOTO	$-5
		DECFSZ	C3,F
		GOTO	$-9
		RETURN

DECODIFICADOR
	ANDLW	0X0F
	ADDLW	LOW TABELA
	MOVWF	TEMP
	MOVLW	HIGH TABELA
	BTFSC	STATUS,C
	ADDLW	0X01
	MOVWF	PCLATH
	MOVF	TEMP,W
	MOVWF	PCL

TABELA

	RETLW	B'00111111' ;0
	RETLW	B'00000110' ;1
	RETLW	B'01011011' ;2
	RETLW	B'01001111' ;3
	RETLW	B'01100110' ;4
	RETLW	B'01101101' ;5
	RETLW	B'01111101' ;6
	RETLW	B'00100111' ;7
	RETLW	B'01111111' ;8
	RETLW	B'01101111' ;9
	RETLW	B'01110111' ;A
	RETLW	B'01111100' ;B
	RETLW	B'00111001' ;C
	RETLW	B'01011110' ;D
	RETLW	B'01111001' ;E
	RETLW	B'01110001' ;F



; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                            FIM DO PROGRAMA
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

		END				; FIM DO PROGRAMA
