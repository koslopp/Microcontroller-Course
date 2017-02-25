///////////////////////////////////////////////////////////////////////////
////                             MAIN.C                                ////
////             Generic Microgenios PIC16F877A main file              ////
////                                                                   ////
////                  Daniel Koslopp - 2013                   ////
////                                                                   ////
///////////////////////////////////////////////////////////////////////////

// 9600bps, 8 bit, sem paridade

#include <16f877a.h>    
#fuses HS,NOWDT,NOPROTECT,NOLVP
#use delay(CLOCK=8000000)   // PICGENIOS PIC16F877A clock

#use fast_io(A)      // Permite leitura e escrita nos PORTs
#use fast_io(C)      // ||
#use fast_io(D)      // ||
#use fast_io(E)      // ||


// Defines

#define RS PIN_E2 // RS no pino E2
#define EN PIN_E1 // EN no pino E1
#define lcd_comando(x)  lcd_escreve(0,x)
#define lcd_letra(x)    lcd_escreve(1,x)
#define lcd_clear()\
        lcd_comando(0x01)\
        delay_ms(2)
#define lcd_gotoxy(l,c)\
        lcd_comando(0x80+0x40*l+c)
#define lcd_cursor_off()\
        lcd_comando(0b00001100)
#define lcd_cursor_on()\
        lcd_comando(0b00001110)
#define lcd_cursor_pisca()\
        lcd_comando(0b00001111)
        
#byte OPTION_REG=0x181
#byte INTCON=0x0B
#byte PIR1=0x00C
#byte PIE1=0x08C
#byte SPBRG=0x099
#byte TXSTA=0x098
#byte RCSTA=0x018
#byte TXREG=0x019
#byte RCREG=0x01A

#bit TXIF=PIR1.4
#BIT RCIF=PIR1.5

// Global variables

int8 cont=0;

// Interruções

#int_timer0
void timer0interrup()
{
   clear_interrupt(INT_TIMER0);
   cont++;
   if(cont=201)
      cont=0;
}

// System initialization

void init()
{
   INTCON=0b10100000;           // Habilita TIMER0
   OPTION_REG=0b00000011;       // Prescale
   TXSTA=0b00100110; //X0(Transm. 8Bits)1(Hab. Transm.)X0(Assincrono)
                     //1XX(BRG alto -> BD=Fosc/(16*(SPBRG+1))
   RCSTA=0b10010000; //1(Hab. USART)0(Recp. 8Bits)0(Recp. unitária desab.)
                     //1(Recp. continua hab.)0(Desab. ADDEN)XXX
   SPBRG=51;         //Valor para Baud Rate = 9600 bits/sec
   output_drive(PIN_C6); //RC6/TX como saida
   output_drive(PIN_C7); //RC7/RX como entrada
   
   set_tris_d(0x00);            // PORTD como saída
   set_tris_e(0x00);            // PORTE como saída
   output_d(0x00);              // Zera o PORTD
   output_e(0x00);              // Zera o PORTE
}

void lcd_escreve(boolean BITRS, int8 ch)  //Escreve no lcd (comando BITRS=0 ou
                                          //dados BITRS=1)
{
   output_bit(RS,BITRS);
   output_d(ch);
   output_high(EN);
   delay_cycles(1);
   output_low(EN);
   delay_us(50);
}

void lcd_init()   // Inicializacao LCD
{
   delay_ms(30);
   lcd_escreve(0,0b00111000); //Function set RS-->0 D7AO D0-->00111000
   lcd_escreve(0,0b00001111); //Display on/off control RS-->0 D7AO D0-->00001111
   lcd_escreve(0,0b00000001); //Display clear  RS-->0 D7AO D0-->00000001
   delay_ms(2);               //Ou delay_us(2000)
   lcd_escreve(0,0b00000110); //Entry mode set  RS-->0 D7AO D0-->00000110

                              //Fim da inicialização
                              //Escrever dados no LCD
                              //Caracter isolado em C 'A'
}

void lcd_string(char ch)      //Escreve 
{
   switch(ch){
      case'\n':lcd_escreve(0,0xc0);   //Pula linha
               break;
      case'\c':lcd_escreve(0,0x01);   //Limpa
               delay_ms(2);
               break;   
      default:lcd_escreve(1,ch);
   }   
}

void  lcd_bintodec(val)  //
{
   
}
void transmite_letra(int8 ch)
{
   TXREG=ch;
   while(!TXIF);
   //TXIF=0;
}

// Main function: Code execution starts here 

void main()
{
   init();
   lcd_init();
   lcd_cursor_off();
   lcd_string("\f Transmissao\n    Serial");
   transmite_letra('1');
   transmite_letra('.');
   transmite_letra('U');
   transmite_letra('T');
   transmite_letra('F');
   transmite_letra('P');
   transmite_letra('R');
   transmite_letra('\r');
   printf(transmite_letra,"2.UTFPR");
   while(1)
   {
      
   }
}
