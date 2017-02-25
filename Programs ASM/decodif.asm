DECODIF
        ; A diretiva LOW usa os 8 bits LSB do endereço de TABELA (ex: LOW 0x314 = 0x14)
        ; W é fornecido como parâmetro de entrada da subrotina; ele é somado com o LSB
        ; ..do endereço de TABELA. Se a soma > 255 gera carry=1
        ADDLW   LOW TABELA      ; Afeta carry. Será feito o teste na instrução BTFSC abaixo

        ; guarda em TEMP
        MOVWF   TEMP            ; não afeta carry

        ; A diretiva HIGH usa os 8 bits MSB do endereço de TABELA (ex: HIGH 0x314 = 0x3)
        MOVLW   HIGH TABELA     ; não afeta carry

        ; Caso a soma de W com LOW TABELA ultrapasse 255...
        BTFSC   STATUS,C        ; aqui é feito o teste do carry gerado na 1ª instrução
        ; então soma 1 a HIGH TABELA que está em W
        ADDLW   0x01
        ; e coloca em PCLATH
        MOVWF   PCLATH

        ; TEMP -> PCL (isto irá causar um desvio para TABELA+W)
        MOVF    TEMP,W
        MOVWF   PCL         ; a execução desta instrução causa o desvio

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
