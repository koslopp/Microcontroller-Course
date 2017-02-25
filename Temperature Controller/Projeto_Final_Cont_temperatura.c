///////////////////////////////////////////////////////////////////////////
////                   CONTROLADOR DE TEMPERATURA                      ////
////             Generic Microgenios PIC16F877A main file              ////
////                                                                   ////
////               Daniel Koslopp e Talita Tobias - 2013               ////
////                                                                   ////
///////////////////////////////////////////////////////////////////////////

#include <16f877a.h>    
#fuses HS,NOWDT,NOPROTECT,NOLVP
#use delay(CLOCK=8000000)   // PICGENIOS PIC16F877A clock

#use fast_io(A)      // Permite leitura e escrita nos PORTs
#use fast_io(C)      // ||
#use fast_io(D)      // ||
#use fast_io(E)      // ||


//Bytes Registradores

#byte OPTION_REG=0x181                             
#byte INTCON=0x0B                                  
#byte ADCON0=0x1F
#byte ADCON1=0x9F
#byte ADRESH=0x1E
#byte ADRESL=0x1E
#byte PIE1=0x8C
#byte PIR1=0x0C
#byte T1CON=0x10
#byte TMR1L=0x0E
#byte TMR1H=0x0F
#byte T2CON=0x12
#byte CCP1CON=0x17
#byte CCPR1L=0x15
#byte CCPR1H=0x16
#byte PR2=0x92

//Defines

#define RS PIN_E2 //RS do LCD no pino E2 
#define EN PIN_E1 //EN do LCD no pino E1

#define C1 input(PIN_B0) //Coluna 1
#define C2 input(PIN_B1) //Coluna 2
#define C3 input(PIN_B2) //Coluna 3
#define L1 PIN_D3 //Linha 1
#define L2 PIN_D2 //Linha 2
#define L3 PIN_D1 //Linha 3
#define L4 PIN_D0 //Linha 4
#define COOLER PIN_C2 //Ventoinha

//Defines comandos LCD

#define lcd_comando(x)  lcd_escreve(0,x)
#define lcd_letra(x)    lcd_escreve(1,x)
#define lcd_gotoxy(l,c)\
        lcd_comando(0x80+0x40*l+c)
#define lcd_cursor_off()\
        lcd_comando(0b00001100)
#define lcd_cursor_on()\
        lcd_comando(0b00001110)
#define lcd_cursor_pisca()\
        lcd_comando(0b00001111)


// Global variables

char ch1='0';  //Usados na conversão de binario para decimal
char ch2='0';  //||
char ch3='0';  //||
char ch4='0';  //||
char ch5='0';  //||
char tecla='0';   //Indica tecla aperta no teclado matricial
int8 bitmap1;  //Mapeia bits dos botoes
int8 bitmap2;  //Mapeia bits dos botoes
int16 temp_desliga=50;   //Temperatura para desligar ventoinha
int16 temp_liga=100;  //Temperatura para ligar ventoinha
int1 tela=0;   //Tela do display. 0: Tela incial. 1: Tela configura parametros
int8 posicao_escreve=0; //Posicao de escrita na tela configura parametros
int16 temp_desliga2=0;   //Temperatura desliga temporaria tela config. param.
int16 temp_liga2=0;   //Temperatura liga temporaria tela config. param.


//Defines Variaveis

#bit  RBPU=OPTION_REG.7 //Ativa pull-ups port teclado
#bit  GO_DONE=ADCON0.2  //Começa conversão AD
#bit  ADIF=PIR1.6 //Flag conversão AD completa

#bit  bta_C1L1=bitmap1.0   //Botão 1
#bit  bta_C2L1=bitmap1.1   //Botão 2 
#bit  bta_C3L1=bitmap1.2   //Botão 3
#bit  bta_C1L2=bitmap1.3   //Botão 4
#bit  bta_C2L2=bitmap1.4   //Botão 5
#bit  bta_C3L2=bitmap1.5   //Botão 6
#bit  bta_C1L3=bitmap1.6   //Botão 7
#bit  bta_C2L3=bitmap1.7   //Botão 8
#bit  bta_C3L3=bitmap2.0   //Botão 9
#bit  bta_C1L4=bitmap2.1   //Botão * (cancel)
#bit  bta_C2L4=bitmap2.2   //Botão 0
#bit  bta_C3L4=bitmap2.3   //Botão # (enter)

//Interrupçao

#int_AD  //Trata interrupção AD
void trata_int()
{
   ADIF=0;  //Zera flag e hab. para uma proxima conversão
}

// System initialization

void init()
{
   RBPU=0;  //Coloca o PORTB em pull-up
   INTCON=0b11000000;   //Habilita Intr. Global e Perif.
   PIE1=0b01000000;     //Hab. Intr. AD
   ADCON0=0b10001001;   //Fosc/32 - Canal 1 - AD on
   ADCON1=0b00000100;   //Left Justif. RA3=RA1=RA0 como Analógica
   T1CON=0b00000011;    //Pre scale 1:1; Habilita clock externo; TMR1 on
   T2CON=0b00000100; //X0000(Postscale 1:1)1(TMR2 On)00(Prescale 1:1)
   CCP1CON=0b00001111;  //XX00(Parte baixa CCPR1L)1111(PWM On)
   CCPR1L=0;
   PR2=99; //Tpwm=(PR2+1)*4*Tosc*Prescale -> Periodo 20us
   set_tris_d(0x00);            //PORTD como saída
   set_tris_e(0x00);            //PORTE como saída
   set_tris_b(0xFF);            //PORTE como saída
   set_tris_c(0xFB);            //RC2 como saída (ventoinha)
   output_d(0x00);              //Zera o PORTD
   output_e(0x00);              //Zera o PORTE
   TMR1L=0;                     //Condição inicial da vel. ventoinha
   TMR1H=0;                     //||
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
      case'\f':lcd_escreve(0,0x01);   //Limpa Display
               delay_ms(2);
               break;   
      default:lcd_escreve(1,ch);      //Escreve caracter no display
   }   
}

void lcd_bintodec(int16 val)  //Rotina do ASC, para escrever número no lcd.
                              //Binário para decimal
{
   ch1='0';
   ch2='0';
   ch3='0';
   ch4='0';
   ch5='0';
   
   while(val>9999)
   {
   val=val-10000;
   ch5++;
   }
   while(val>999)
   {
   val=val-1000;
   ch4++;
   }
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


void scan_teclado_matricial()    //Verifica se alguma tecla foi acionada
{
   tecla=0; //Condição inicial. É alterada quando alguma tecla é acionada
   output_low(L1);   //Scan da linha 1
   output_high(L2);  //||
   output_high(L3);  //||
   output_high(L4);  //||
   if(bta_C1L1!=C1)
      if(bta_C1L1==1){ bta_C1L1=0; tecla='1'; delay_ms(10);} //scan 1
      else bta_C1L1=1;
   if(bta_C2L1!=C2)
      if(bta_C2L1==1){ bta_C2L1=0; tecla='2'; delay_ms(10);} //Scan 2
      else bta_C2L1=1;
   if(bta_C3L1!=C3)
      if(bta_C3L1==1){ bta_C3L1=0; tecla='3'; delay_ms(10);} //Scan 3
      else bta_C3L1=1;
   output_high(L1);  //Scan da linha 2
   output_low(L2);   //||
   output_high(L3);  //||
   output_high(L4);  //||
   if(bta_C1L2!=C1)
      if(bta_C1L2==1){ bta_C1L2=0; tecla='4'; delay_ms(10);} //scan 4
      else bta_C1L2=1;
   if(bta_C2L2!=C2)
      if(bta_C2L2==1){ bta_C2L2=0; tecla='5'; delay_ms(10);} //Scan 5
      else bta_C2L2=1;
   if(bta_C3L2!=C3)
      if(bta_C3L2==1){ bta_C3L2=0; tecla='6'; delay_ms(10);} //Scan 6
      else bta_C3L2=1;
   output_high(L1);  //Scan da linha 3
   output_high(L2);  //||
   output_low(L3);   //||
   output_high(L4);  //||
   if(bta_C1L3!=C1)
      if(bta_C1L3==1){ bta_C1L3=0; tecla='7'; delay_ms(10);} //scan 7
      else bta_C1L3=1;
   if(bta_C2L3!=C2)
      if(bta_C2L3==1){ bta_C2L3=0; tecla='8'; delay_ms(10);} //Scan 8
      else bta_C2L3=1;
   if(bta_C3L3!=C3)
      if(bta_C3L3==1){ bta_C3L3=0; tecla='9'; delay_ms(10);} //Scan 9
      else bta_C3L3=1;
   output_high(L1);  //Scan da linha 4
   output_high(L2);  //||
   output_high(L3);   //||
   output_low(L4);  //||
   if(bta_C1L4!=C1)
      if(bta_C1L4==1){ bta_C1L4=0; tecla='*'; delay_ms(10);} //scan * (cancel)
      else bta_C1L4=1;
   if(bta_C2L4!=C2)
      if(bta_C2L4==1){ bta_C2L4=0; tecla='0'; delay_ms(10);} //Scan 0
      else bta_C2L4=1;
   if(bta_C3L4!=C3)
      if(bta_C3L4==1){ bta_C3L4=0; tecla='#'; delay_ms(10);} //Scan # (enter)
      else bta_C3L4=1;
}

void tela_invalida() //Indica parametro invalido nas variaveis de temperatura
                     //limpa variaveis e retorna para tela de configuração
{
      lcd_cursor_off(); 
      lcd_string("\f");
      lcd_gotoxy(0,0);
      printf(lcd_string,"    PARAMETRO\n    INVALIDO");
      delay_ms(1000);
      temp_desliga2=temp_desliga;
      temp_liga2=temp_liga;
      posicao_escreve=0;
      lcd_string('\f');
      lcd_gotoxy(0,0);
      lcd_bintodec(temp_desliga2);
      printf(lcd_string,"TEMP DESLIG=%c%c%c",ch3,ch2,ch1);
      lcd_gotoxy(1,0);
      lcd_bintodec(temp_liga2);
      printf(lcd_string,"TEMP LIG   =%c%c%c",ch3,ch2,ch1);
      lcd_gotoxy(0,12);
      lcd_cursor_on();
}

void troca_tela() //Troca entre tela principal e tela de configuração
{
   if(tela==0) //Se tela principal, inicia tela de configuração
   {
      tela=1;
      temp_desliga2=temp_desliga;
      temp_liga2=temp_liga;
      posicao_escreve=0;
      lcd_string('\f');
      lcd_gotoxy(0,0);
      lcd_bintodec(temp_desliga2);
      printf(lcd_string,"TEMP DESLIG=%c%c%c",ch3,ch2,ch1);
      lcd_gotoxy(1,0);
      lcd_bintodec(temp_liga2);
      printf(lcd_string,"TEMP LIG   =%c%c%c",ch3,ch2,ch1);
      lcd_gotoxy(0,12);
      lcd_cursor_on();
   }
   else tela=0;   //Se tela de configuração, retorna a tela principal
}

void atualiza_tela() //Atualiza valores na tela
{
   if(tela==0) //Se tela principal, atualiza AD e VEL
   {
      lcd_cursor_off();
      lcd_gotoxy(0,0);
      lcd_bintodec(TMR1H*256+TMR1L);
      printf(lcd_string,"VEL=%c%c%c%c%c ",ch5,ch4,ch3,ch2,ch1);
      lcd_bintodec(ADRESH);
      printf(lcd_string,"AD=%c%c%c",ch3,ch2,ch1);
      lcd_gotoxy(1,0);
      lcd_bintodec(temp_liga);
      printf(lcd_string,"LIG=%c%c%c ",ch3,ch2,ch1);
      lcd_bintodec(temp_desliga);
      printf(lcd_string,"DESL=%c%c%c",ch3,ch2,ch1);
      if(tecla=='#') troca_tela();
   }
   else  //Se tela configuração, verifica acionamento do teclado
   {
      if(tecla!=0)   //Se teclado foi acionado verifica ação
      {
         if(tecla=='#')
         {
            if(posicao_escreve<3)   //Enter acionado no param. desliga
            {
               if(temp_desliga2==0) tela_invalida(); //Param. 0, tela invalida
               else //Vai para parametro liga
               {
                  lcd_gotoxy(1,12); 
                  posicao_escreve=4;
               }
            }
            else if(posicao_escreve==3) //Parametro desliga completo, vai para
                                        //param. liga. (paramtro pode ser 
                                        //aceito sem necessidade de digitar as
                                        //3 casas decimais)
            {
               posicao_escreve=4; 
               lcd_gotoxy(1,12); 
               temp_liga2=0;
            }
            else  //Enter acionado no parametro liga
            {
               if(temp_desliga2<temp_liga2) //Se temp. desliga e liga ok, salva
                                            //variaveis temporarias nos param.
                                            //principais
               {
                  temp_desliga=temp_desliga2;
                  temp_liga=temp_liga2;
                  troca_tela();
               }
               else tela_invalida();   //Casa param. desliga e liga nok, inval.
            }
         }
         else if(tecla=='*') troca_tela();   //Se cancela acionado, volta tela
                                             //pricipal sem salvar 
         else  //Numero acionado
         {
            switch(posicao_escreve) //Posicao entre 0 e 2 param. desliga.
                                    //Posicao==3 aguarda enter ou tela invalida
                                    //Posicao entre 4 e 6 param. liga.
                                    //Posica==7 aguarda enter ou tela invalida
            {
               case 0:  if(tecla>'2') tela_invalida(); //Se centena maior que
                                                       //200, param. invalido
                        else  //Salva centena param. desliga
                        {
                           lcd_bintodec(temp_desliga2);
                           temp_desliga2=temp_desliga2-(ch3-48)*100+(tecla-48)*100;
                           lcd_string(tecla);
                           posicao_escreve++;
                        }
                        break;
               case 1:  if((temp_desliga2==200) && (tecla>'5')) tela_invalida();
                        //Se dezena maior que 5 caso centena=2, param. invalido.
                        else  //Salva dezena param. desliga
                        {  
                           lcd_bintodec(temp_desliga2);
                           temp_desliga2=temp_desliga2-(ch2-48)*10+(tecla-48)*10;
                           lcd_string(tecla);
                           posicao_escreve++;
                        }
                        break;
               case 2:  if((temp_desliga2==250) && (tecla>'5')) tela_invalida();
                        //Se unidade maior que 5 caso centeza:dezena=250. param.
                        //invalido.
                        else  //Salva valor final desliga temporario
                        {
                           lcd_bintodec(temp_desliga2);
                           temp_desliga2=temp_desliga2-(ch1-48)+(tecla-48);
                           lcd_string(tecla);
                           posicao_escreve++;
                        }
                        break;
               case 3:  tela_invalida();  //Se nao foi enter, param. invalido
                        break;
               case 4:  if(tecla>'2') tela_invalida(); //Se centena maior que
                                                       //200, param. invalido
                        else  //Salva centena param. liga
                        {
                           lcd_bintodec(temp_liga2);
                           temp_liga2=temp_liga2-(ch3-48)*100+(tecla-48)*100;
                           lcd_string(tecla);
                           posicao_escreve++;
                        }
                        break;
               case 5:  if((temp_liga2==200) && (tecla>'5')) tela_invalida();
                        //Se dezena maior que 5 caso centena=2, param. invalido.
                        else  //Salva dezena param. desliga
                        {  
                           lcd_bintodec(temp_liga2);
                           temp_liga2=temp_liga2-(ch2-48)*10+(tecla-48)*10;
                           lcd_string(tecla);
                           posicao_escreve++;
                        }
                        break;
               case 6:  if((temp_liga2==250) && (tecla>'5')) tela_invalida();
                        //Se unidade maior que 5 caso centeza:dezena=250. param.
                        //invalido.
                        else  //Salva valor final param. liga temporario
                        {
                           lcd_bintodec(temp_liga2);
                           temp_liga2=temp_liga2-(ch1-48)+(tecla-48);
                           lcd_string(tecla);
                           posicao_escreve++;
                        }
                        break;
               case 7:  tela_invalida();  //Se nao foi enter, param. invalido
                        break;
            }
         }
      }
   }
}


// Main function: Code execution starts here 


void main()
{
   
   init();  //Condições inciais
   lcd_init(); //Inicializa LCD
   lcd_cursor_off(); 
   lcd_string(" PROJETO FINAL"); //Telas iniciais
   lcd_gotoxy(1,0);
   lcd_string("DANIEL E TALITA");
   delay_ms(1000);
   lcd_string("\f");
   lcd_gotoxy(0,0);
   lcd_string(" CONTROLADOR DE\n  TEMPERATURA");
   delay_ms(1000);
   lcd_string("\f");
   while(1)
   {
      GO_DONE=1;  //Inicia AD
      scan_teclado_matricial();  //Verifica teclado      
      if(ADRESH>temp_liga) {CCPR1L=95; PR2=99;} //Liga ventoinha
      if(ADRESH<temp_desliga) {CCPR1L=5; PR2=99;}  //Desliga ventoinha
      atualiza_tela();  //Atualiza tela LCD
   }
}
