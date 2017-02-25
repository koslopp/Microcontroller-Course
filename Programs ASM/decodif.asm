DECODIF
        ; A diretiva LOW usa os 8 bits LSB do endere�o de TABELA (ex: LOW 0x314 = 0x14)
        ; W � fornecido como par�metro de entrada da subrotina; ele � somado com o LSB
        ; ..do endere�o de TABELA. Se a soma > 255 gera carry=1
        ADDLW   LOW TABELA      ; Afeta carry. Ser� feito o teste na instru��o BTFSC abaixo

        ; guarda em TEMP
        MOVWF   TEMP            ; n�o afeta carry

        ; A diretiva HIGH usa os 8 bits MSB do endere�o de TABELA (ex: HIGH 0x314 = 0x3)
        MOVLW   HIGH TABELA     ; n�o afeta carry

        ; Caso a soma de W com LOW TABELA ultrapasse 255...
        BTFSC   STATUS,C        ; aqui � feito o teste do carry gerado na 1� instru��o
        ; ent�o soma 1 a HIGH TABELA que est� em W
        ADDLW   0x01
        ; e coloca em PCLATH
        MOVWF   PCLATH

        ; TEMP -> PCL (isto ir� causar um desvio para TABELA+W)
        MOVF    TEMP,W
        MOVWF   PCL         ; a execu��o desta instru��o causa o desvio

TABELA
        RETLW   B'00111111'     ; 0
        RETLW   B'00000110'     ; 1
        RETLW   B'01011011'     ; 2
        RETLW   B'01001111'     ; 3
        RETLW   B'01100110'     ; 4
        RETLW   B'01101101'     ; 5
        RETLW   B'01111101'     ; 6
        RETLW   B'00000111'     ; 7
        RETLW   B'01111111'     ; 8
        RETLW   B'01101111'     ; 9
        RETLW   B'01110111'     ; A
        RETLW   B'01111100'     ; B
        RETLW   B'00111001'     ; C
        RETLW   B'01011110'     ; D
        RETLW   B'01111001'     ; E
        RETLW   B'01110001'     ; F
