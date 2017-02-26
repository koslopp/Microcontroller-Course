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
		BITMAP
	ENDC

#DEFINE		BITANT		BITMAP,0	;CONDIÇÃO ANTERIOR DE BOTAO

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
		BANK1			;SELECIONA BANCO 1
		MOVLW	0XFF	;0XFF -> W	
		MOVWF	TRISB	;CONFIGURA PORTB COMO ENTRADA
		MOVLW	0X0		;0X00 -> W
		MOVWF	TRISD	;CONFIGURA PORTD COMO SAIDA
		BANK0			;SELECIONA BANCO 0
		BSF		BITANT	;CONDICAO INICIAL BITANT
		CLRF	PORTD	;ZERA PORTD


LE_BOTAO	
		COMPBIT	PORTB,4,BITANT,TROCA	;MACRO COMPARA BIT
		GOTO 	LE_BOTAO				;VAI PARA LE_BOTAO

TROCA					;VERIFICA BORDA QUANDO BITANT != RB4
		BTFSC	BITANT	;BITANT=0?
		GOTO	ACAO	;NAO: BORDA DE DESCIDA. COMPLEMENTA PORTD
		GOTO	NADA	;SIM: BORDA DE SUBIDA. NÃO FAZ NADA

ACAO						;ACAO: COMPLEMENTA PORTD
		COMF	PORTD		;COMPLEMENTA PORTD
		CALL	FILTRO		;CHAMA FILTRO DE RUIDO NA CHAVE
		BCF		BITANT		;ZERA BITANT
		GOTO	LE_BOTAO	;VOLTA PARA LE_BOTAO

NADA						;NADA: SOMENTE CHAMA FILTRO DE RUIDO
		CALL	FILTRO		;CHAMA FILTRO DE RUIDO NA CHAVE
		BSF		BITANT		;SETA BITANT
		GOTO	LE_BOTAO	;VOLTA PARA LE_BOTAO

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                            SUBROTINAS
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *


FILTRO
		
		MOVLW	D'21'
		MOVWF	C2
		MOVLW	D'199'
		MOVWF	C1
		DECFSZ	C1,F
		GOTO	$-1
		DECFSZ	C2,F
		GOTO	$-5
		RETURN



; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; *                            FIM DO PROGRAMA
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

		END				; FIM DO PROGRAMA
