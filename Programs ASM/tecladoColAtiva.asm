; ----------------------------------------------------------------
;	Não esquecer de incluir as seguintes variáveis no CBLOCK:
;		FILTRO_BOTOES, ANT1, ANT2, ANT3, ANTTEMP, TECLA
; ----------------------------------------------------------------

#DEFINE   ALIN1 ANTTEMP,0
#DEFINE   ALIN2 ANTTEMP,1
#DEFINE   ALIN3 ANTTEMP,2
#DEFINE   ALIN4 ANTTEMP,3
#DEFINE   LIN1  PORTD,3
#DEFINE   LIN2  PORTD,2
#DEFINE   LIN3  PORTD,1
#DEFINE   LIN4  PORTD,0

;_________________________________________________________________
;   COMPARA DOIS BITS
;	SE FOREM IGUAIS SEGUE APÓS A MACRO
;	SE FOREM DIFERENTES DESVIA PARA DIFERENTE (RÓTULO A DEFINIR)
;_________________________________________________________________

#DEFINE	BIT1	PORT1,BT1
#DEFINE	BIT2	PORT2,BT2

COMPBITS		MACRO			BIT1,BIT2,DIFERENTE
				LOCAL			L1,IGUAL
				BTFSS			BIT1
				GOTO			L1
				BTFSS			BIT2
				GOTO			DIFERENTE
				GOTO			IGUAL
L1				BTFSC			BIT2
				GOTO			DIFERENTE
IGUAL
				ENDM

;_________________________________________________________________
;   MACROS USADAS NA VARREDURA
;_________________________________________________________________

#DEFINE	AB1	AFILE,ABIT
#DEFINE	B1	FILE,BIT

FILTRO_LINHA	MACRO			AB1,B1,TEC
				LOCAL			L1,L2,L3,L4
				MOVLF			FILTRO_BOTOES,.250
L2				COMPBITS		AB1,B1,L4
				GOTO			L1
L4				DECFSZ			FILTRO_BOTOES,F
				GOTO			L2
				; CONFIRMA BOTAO ALTERADO
				BTFSS			AB1
				GOTO			L3
				BCF				AB1
				MOVLF			TECLA,TEC
				GOTO			L1
L3				BSF				AB1
L1
				ENDM
;_________________________________________________________________
#DEFINE	COLDES	PORTDES,BITDES
#DEFINE	COLATIV	PORTATIV,BITATIV

FILTRO_PORTAS	MACRO			ANT,COLDES,COLATIV,TEC1,TEC2,TEC3,TEC4
				BSF				COLDES
				BCF				COLATIV
				MOVF			ANT,W
				MOVWF			ANTTEMP
				FILTRO_LINHA	ALIN1,LIN1,TEC1
				FILTRO_LINHA	ALIN2,LIN2,TEC2
				FILTRO_LINHA	ALIN3,LIN3,TEC3
				FILTRO_LINHA	ALIN4,LIN4,TEC4
				MOVF			ANTTEMP,W
				MOVWF			ANT
				ENDM
;_________________________________________________________________
;		SUBROTINA DE VARREDURA DO TECLADO
;_________________________________________________________________

VARRE_TECLADO
		;CLRWDT
		MOVLF			TECLA,.0
		FILTRO_PORTAS	ANT1,COL3,COL1,'1','4','7','*'
		FILTRO_PORTAS	ANT2,COL1,COL2,'2','5','8','0'
		FILTRO_PORTAS	ANT3,COL2,COL3,'3','6','9','#'
		RETURN
