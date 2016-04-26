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
//**********************************************************************
//  Filename:   RXI.c
//*********************************************************************
//  Author:     Lucio Di Jasio
//  Company:    Microchip Technology
//  Revision:   Rev 1.00
//  Date:       08/07/00
//
//  Interrupt based receive routine
//
//  Compiled using HiTech PIC C compiler v.7.93
//  Compiled using CCS    PIC C compiler v.2.535
//********************************************************************
#define CLOCK           4       // MHz
#define TE            400       // us
#define OVERSAMPLING    3       
#define PERIOD          TE/OVERSAMPLING*4/CLOCK

#define NBIT            65      // number of bit to receive -1

byte B[9];                      // receive buffer 

static byte  RFstate;           // receiver state
static sbyte RFcount;           // timer counter
static byte  Bptr;              // receive buffer pointer
static byte  BitCount;          // received bits counter
word   XTMR;                    // 16 bit extended timer

volatile bit RFFull;            // buffer full
volatile bit RFBit;             // sampled RF signal

#define TRFreset    0
#define TRFSYNC     1
#define TRFUNO      2
#define TRFZERO     3

#define HIGH_TO     -10         // longest high Te
#define LOW_TO       10         // longest low  Te
#define SHORT_HEAD   20         // shortest Thead accepted 2,7ms
#define LONG_HEAD    45         // longest Thead accepted 6,2ms


#pragma int_rtcc   // install as interrupt handler (comment for HiTech!)
interrupt
rxi()
{
    // this routine gets called every time TMR0 overflows
    RFBit = RFIn;               // sampling RF pin verify!!!
    TMR0 -= PERIOD;             // reload
    T0IF = 0;

    XTMR++;                     // extended 16 long timer update

    if (RFFull)                 // avoid overrun
        return;

    switch( RFstate)            // state machine main switch
    {

    case TRFUNO:
        if ( RFBit == 0)
        { // falling edge detected  ----+
          //                            |
          //                            +----
                RFstate= TRFZERO;
        }
        else
        { // while high 
            RFcount--;
            if ( RFcount < HIGH_TO)
                RFstate = TRFreset;      // reset if too long
        }
        break;

    case TRFZERO:
        if ( RFBit)
        { // rising edge detected     +----
          //                          |
          //                      ----+
            RFstate= TRFUNO;
            B[Bptr] >>= 1;              // rotate 
            if ( RFcount >= 0)
            {
                B[Bptr]+=0x80;          // shift in bit
            }
            RFcount = 0;                // reset length counter
            
            if ( ( ++BitCount & 7) == 0)
                Bptr++;                 // advance one byte
            if (BitCount == NBIT)
            {
                RFstate = TRFreset;     // finished receiving 
                RFFull = TRUE;
            }    
        }
        else
        { // still low
            RFcount++;
            if ( RFcount >= LOW_TO)     // too long low
            {
                RFstate = TRFSYNC;      // fall back into RFSYNC state 
                Bptr = 0;               // reset pointers, while keep counting on 
                BitCount = 0;
            }
        }
        break;

    case TRFSYNC:
        if ( RFBit)
        { // rising edge detected  +---+                +---..
          //                       |   |  <-Theader->   |   
          //                           +----------------+
            if ( ( RFcount < SHORT_HEAD) || ( RFcount >= LONG_HEAD))
            {
                RFstate = TRFreset;
                break;                  // too short/long, no header
            }
            else
            {
                RFcount =0;             // restart counter
                RFstate= TRFUNO;
            }
        }
        else
        { // still low
            RFcount++;
        }
        break;

    case TRFreset:
    default:
        RFstate = TRFSYNC;        // reset state machine in all other cases
        RFcount = 0;
        Bptr = 0;
        BitCount = 0;
        break;
        
    } // switch

   
} // rxi 


void InitReceiver()
{
    T0IF = 0;
    T0IE = 1;                   // TMR0 overflow interrupt
    GIE = 1;                    // enable interrupts
    RFstate = TRFreset;         // reset state machine in all other cases
    RFFull = 0;                 // start with buffer empty
    XTMR = 0;                   // start extended timer
 }            

        

    
    
