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
#byte T2CON=0x12
#byte CCP1CON=0x17
#byte CCPR1L=0x15
#byte CCPR1H=0x16
#byte PR2=0x92

#bit TXIF=PIR1.4
#bit RCIF=PIR1.5

#define INC_PWM PIN_B3
#define DEC_PWM PIN_B4

// Global variables

int8 bitmap=3; #bit bitant_INC_PWM=bitmap.0
               #bit bitant_DEC_PWM=bitmap.1
char ch1=0;
char ch2=0;
char ch3=0;

// Interruções


// System initialization

void init()
{
   INTCON=0b10000000;           // Habilita Intr. Perifericos
   T2CON=0b00000100; //X0000(Postscale 1:1)1(TMR2 On)00(Prescale 1:1)
   CCP1CON=0b00001111; //XX00(Parte baixa CCPR1L)1111(PWM On)
   CCPR1L=0;
   PR2=99; //Tpwm=(PR2+1)*4*Tosc*Prescale -> Periodo 20us
   set_tris_c(0x00);             // PORTC como saída
   set_tris_a(0xFF);            // PORTA como entrada
   set_tris_b(0xFF);            // PORTB como entrada
   set_tris_d(0x00);            // PORTD como saída
   set_tris_e(0x00);            // PORTE como saída
   output_d(0x00);              // Zera o PORTD
   output_e(0x00);              // Zera o PORTE
   output_c(0x00);
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
      case'\f':lcd_escreve(0,0x01);   //Limpa
               delay_ms(2);
               break;   
      default:lcd_escreve(1,ch);
   }   
}

void lcd_bintodec(int8 val)           // rotina do ASC, para escrever número no lcd, binário para decimal
{
   ch1='0';
   ch2='0';
   ch3='0';
   
   while(val>99)
   {
   val=val-100;
   ch3++;
   }
   while(val>9)
   {
   val=val-10;
   ch2++;
   }
   ch1=val+'0';
}

void incrementa_pwm()
{
   switch(CCPR1L)
   {
      case 0: CCPR1L=20;
              PR2=99;
              break;
      case 20:CCPR1L=40;
              PR2=99;
              break;
      case 40:CCPR1L=60;
              PR2=99;
              break;
      case 60:CCPR1L=80;
              PR2=99;
              break;
      case 80:CCPR1L=100;
              PR2=99;
              break;
      case 100:CCPR1L=100;
              PR2=99;
              break;
   }
   
      
}


void decrementa_pwm()
{
   switch(CCPR1L)
   {
      case 0: CCPR1L=0;
              PR2=99;
              break;
      case 20:CCPR1L=0;
              PR2=99;
              break;
      case 40:CCPR1L=20;
              PR2=99;
              break;
      case 60:CCPR1L=40;
              PR2=99;
              break;
      case 80:CCPR1L=60;
              PR2=99;
              break;
      case 100:CCPR1L=80;
              PR2=99;
              break;
   }
}

void botao_inc()
{
   if(bitant_INC_PWM!=input(INC_PWM))
   {
      if(bitant_INC_PWM==1)
      {
         bitant_INC_PWM=0;
         incrementa_pwm();
         delay_ms(5);
      }
      else
         bitant_INC_PWM=1;
   }
}

void botao_dec()
{
   if(bitant_DEC_PWM!=input(DEC_PWM))
   {
      if(bitant_DEC_PWM==1)
      {
         bitant_DEC_PWM=0;
         decrementa_pwm();
         delay_ms(5);
      }
      else
         bitant_DEC_PWM=1;
   }
}

// Main function: Code execution starts here 

void main()
{
   init();
   lcd_init();
   lcd_cursor_off();
   lcd_string("        PWM");
   while(1)
   {
      botao_inc();
      botao_dec();
   }
}
