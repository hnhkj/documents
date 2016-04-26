//
//							 Software License Agreement
//
// The software supplied herewith by Microchip Technology Incorporated 
// (the "Company") for its PICmicro® Microcontroller is intended and 
// supplied to you, the Company’s customer, for use solely and 
// exclusively on Microchip PICmicro Microcontroller products. The 
// software is owned by the Company and/or its supplier, and is 
// protected under applicable copyright laws. All rights are reserved. 
//  Any use in violation of the foregoing restrictions may subject the 
// user to criminal sanctions under applicable laws, as well as to 
// civil liability for the breach of the terms and conditions of this 
// license.
//
// THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION. NO WARRANTIES, 
// WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED 
// TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
// PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE COMPANY SHALL NOT, 
// IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL OR 
// CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
//
//
//
//   Module DECCCS.h
// 
//  include this file when using the CCS C compiler
//
#define CCS

#DEVICE PIC16C63

typedef short bit;              // one bit
typedef unsigned int byte;      // one byte unsigned
typedef signed   int sbyte;     // one byte signed
typedef signed  long word;      // one word signed

// un-supported directives
#define static
#define volatile
#define interrupt

#define TRUE    1
#define FALSE   0
#define ON      1
#define OFF     0

//
// F872 special function registers
//
#byte TMR0 = 0x01       // Timer 0
#bit  T0IF = 0x0B.2     // Timer 0 interrupt flag
#bit  T0IE = 0x0B.5     // Timer 0 interrupt enable
#bit  GIE  = 0x0B.7     // Global Interrupt Enable

#byte OPTION = 0x81     // prescaler timer0 control
#byte ADCON1 = 0x9f     // A/D converter control

#byte TRISA = 0x85      // PORT A
#byte PORTA = 0x05
#bit RA0 = 0x05.0
#bit RA1 = 0x05.1
#bit RA2 = 0x05.2
#bit RA3 = 0x05.3
#bit RA4 = 0x05.4
#bit RA5 = 0x05.5

#byte TRISB = 0x86      // PORT B
#byte PORTB = 0x06
#bit RB0 = 0x06.0
#bit RB1 = 0x06.1
#bit RB2 = 0x06.2
#bit RB3 = 0x06.3
#bit RB4 = 0x06.4
#bit RB5 = 0x06.5
#bit RB6 = 0x06.6
#bit RB7 = 0x06.7

#byte TRISC = 0x87      // PORT C
#byte PORTC = 0x07

// internal EEPROM access
#byte EEADR  = 0x10d
#byte EEDATA = 0x10c
#byte EECON1 = 0x18c
#byte EECON2 = 0x18d
#bit  WR =   0x18c.1
#bit  RD =   0x18c.0
#bit  WREN = 0x18c.2
#bit  EEPGD =0x18c.7 

// macro versions of EEPROM write and read 
#define	EEPROM_WRITE(addr, value) while(WR)continue;EEADR=(addr);EEDATA=(value);EEPGD=0;GIE=0;WREN=1;\
					EECON2=0x55;EECON2=0xAA;WR=1;WREN=0
#define	EEPROM_READ(addr) ((EEADR=(addr)),(EEPGD=0),(RD=1),EEDATA)

// configuration and ID locations
#FUSES RC, NOWDT, NOPROTECT, BROWNOUT
#ID 0x1234

