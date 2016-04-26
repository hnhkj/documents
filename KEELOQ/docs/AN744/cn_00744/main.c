
// *********************************************************************
//  Filename:   MAIN.c
// *********************************************************************
//  Author:     Lucio Di Jasio
//  Company:    Microchip Technology
//  Revision:   Rev 1.00
//  Date:       08/07/00
//
//  Keeloq Normal Learn Decoder on a mid range PIC 
//  full source in C
//
//  Compiled using HITECH PIC C compiler v.7.93
//  Compiled using CCS    PIC C compiler v. 2.535
// ********************************************************************

//#include "decccs.h"  // uncomment for CCS compiler
#include "dechit.h" // uncomment for HiTech compiler
//
//---------------------------------------------------------------------
// I/O definitions for PIC16F872
// compatible with PICDEM-2 demo board
//
//           +-------- -------+
//  Reset   -|MCLR    O    RB7|-  NU(ICD data)
//  (POT)   -|RA0          RB6|-  NU(ICD clock)
//  RFin    -|RA1          RB5|-  Vlow(Led)
//  NU      -|RA2          RB4|-  LearnOut(Led)
//  NU      -|RA3      PRG/RB3|-  Out3(Led)
//  Learn   -|RA4/T0CKI    RB2|-  Out2(Led)
//  NU      -|RA5          RB1|-  Out1(Led)
//  GND     -|Vss      INT/RB0|-  Out0(Led)
//  XTAL    -|OSCIN        Vdd|-  +5V 
//  XTAL    -|OSCOUT       Vss|-  GND 
//  NU      -|RC0       RX/RC7|-  NU(RS232) 
//  NU      -|RC1       TX/RC6|-  NU(RS232)  
//  NU(SW3) -|RC2/CCP1     RC5|-  NU   
//  NU      -|RC3/SCL  SDA/RC4|-  NU   
//           +----------------+
//



#define RFIn   RA1           // i radio signal input
#define Learn  RA4           // i learn button 

#define Out0   RB0           // o S0 output
#define Out1   RB1           // o S1 output
#define Out2   RB2           // o S2 output
#define Out3   RB3           // o S3 output
#define  Led   RB4           // o LearnOut Led
#define Vlow   RB5           // o low battery 

#define MASKPA  0xff         // port A I/O config (all input)
#define MASKPB  0xc0         // port B I/O config (6 outputs)
#define MASKPC  0xff         // port C I/O config (NU)

// -----------------global variables ---------------------------

byte Buffer[9];             // receive buffer

//---------------------------------------------------------------
//
// keeloq receive buffer map
//
// | Plain text                                | Encrypted
// RV000000.KKKKIIII.IIIIIIII.IIIIIIII.IIIIIIII.KKKKOODD.DDDDDDDD.SSSSSSSS.SSSSSSSS
//      8       7       6        5         4       3         2        1        0
//
// I=S/N   -> SERIAL NUMBER       (28 BIT)
// K=KEY   -> buttons encoding     (4 BIT)
// S=Sync  -> Sync counter        (16 BIT)
// D=Disc  -> Discrimination bits (10 BIT)
// R=Rept  -> Repeat/first         (1 BIT)
// V=Vlow  -> Low battery          (1 BIT)
//
//-- alias -------------------------------------------------------------
//
#define     HopLo   Buffer[0] //sync counter
#define     HopHi   Buffer[1] //
#define     DisLo   Buffer[2] //discrimination bits LSB
#define     DOK     Buffer[3] //Disc. MSB + Ovf + Key
#define     IDLo    Buffer[4] //S/N LSB
#define     IDMi    Buffer[5] //S/N 
#define     IDHi    Buffer[6] //S/N MSB

#define S0  5   //  Buffer[3] function codes
#define S1  6   //  Buffer[3] function codes
#define S2  7   //  Buffer[3] function codes
#define S3  4   //  Buffer[3] function codes
#define VFlag  7//  Buffer[8] low battery flag

//----------------- flags defines ------------------------------------
bit FHopOK;     // Hopping code verified OK
bit FSame;      // Same code as previous
bit FLearn;     // Learn mode active
bit F2Chance;   // Resync required

//--------------------------------------------------------------------
// timings
//
#define TOUT    5           //   5 * 71ms = 350ms output delay
#define TFLASH  2           //   4 * 71ms = 280ms half period
#define TLEARN  255         // 255 * 71ms =  18s  learn timeout

//byte Flags;                 // various flags
byte CLearn, CTLearn;       // learn timers and counter
byte CFlash, CTFlash;       // led flashing timer and counter
byte COut;                  // output timer
byte FCode;      // function codes and upper nibble of serial number

word Dato;       // temp storage for read and write to mem.
word Ind;        // address pointer to record in mem.
word Hop;        // hopping code sync counter
word EHop;       // last value of sync counter (from EEPROM)
word ETemp;      // second copy of sync counter


//
// interrupt receiver
//
#include "rxim.c"

 
//
// external modules
//
#include "mem-87x.c"       // EEPROM I2C routines
#include "table.c"         // TABLE management
#include "keygen.c"        // Keeloq decrypt and normal keygen 

//
// prototypes
//
void Remote( void);              


//
// MAIN
//
// Main program loop, I/O polling and timing
//
void main ()
{
    // init
    ADCON1 = 0x7;       // disable analog inputs
    TRISA = MASKPA;     // set i/o config.
    TRISB = MASKPB;
    TRISC = MASKPC;
    PORTA = 0;          // init all outputs
    PORTB = 0;
    PORTC = 0;
    OPTION = 0x8f;      // prescaler assigned to WDT,
                        // TMR0 clock/4, no pull ups

       
    CTLearn = 0;        // Learn debounce
    CLearn = 0;         // Learn timer
    COut = 0;           // output timer
    CFlash = 0;         // flash counter
    CTFlash = 0;        // flash timer
    FLearn = FALSE;     // start in normal mode 
    F2Chance = FALSE;   // no resynchronization required

    InitReceiver();     // enable and init the receiver state machine

    // main loop
    while ( TRUE)
    {
        if ( RFFull)       // buffer contains a message
            Remote();

        // loop waiting 512* period = 72ms
        if ( XTMR < 512)
            continue;       // main loop

// once every 72ms 
        XTMR=0;

        // re-init fundamental registers 
        ADCON1 = 0x7;       // disable analog inputs
        TRISA = MASKPA;     // set i/o config.
        TRISB = MASKPB;
        TRISC = MASKPC;
        OPTION = 0x0f;      // prescaler assigned to WDT, TMR0 clock/4, pull up
        T0IE = 1;
        GIE = 1;
        
        // poll learn
        if ( !Learn)    // low -> button pressed
        {
            CLearn++;

            // pressing Learn button for more than 10s -> ERASE ALL
            if (CLearn == 128)      // 128 * 72 ms = 10s
            {
                Led = OFF;          // switch off Learn Led
                while( !Learn);     // wait for button release
                Led = ON;           // signal Led on
                ClearMem();         // erase all comand!
                COut = TOUT;        // single lomg flash pulse time
                                    // timer will switch off Led
                CLearn = 0;         // reset learn debounce
                FLearn = FALSE;     // exit learn mode
            }               

            // normal Learn button debounce
            if (CLearn == 4)        // 250ms debounce
            {
                FLearn = TRUE;      // enter learn mode comand!
                CTLearn = TLEARN;   // load timout value
                Led = ON;           // turn Led on
            }
          }
          else  CLearn=0;           // reset counter
            
         // outputs timing
         if ( COut > 0)             // if timer running
         {
            COut--;
            if ( COut == 0)         // when it reach 0
            {
                Led = OFF;          // all outputs off
                Out0 = OFF;
                Out1 = OFF;
                Out2 = OFF;
                Out3 = OFF;
                Vlow = OFF;
             }
         }
        
         // Learn Mode timout after 18s (TLEARN * 72ms)
         if ( CTLearn > 0)
         {
            CTLearn--;                  // count down
            if ( CTLearn == 0)          // if timed out
            {
                Led = OFF;              // exit Learn mode
                FLearn = FALSE;
            }
         }

         // Led Flashing 
         if ( CFlash > 0)
         {
            CTFlash--;                  // count down
            if ( CTFlash == 0)          // if timed out
            {
                CTFlash = TFLASH;       // reload timer
                CFlash--;               // count one flash
                Led = OFF;              // toggle Led
                if ( CFlash & 1)
                    Led = ON;        
            }
         }
         
     } // main loop
} // main 


//
// Remote Routine
//
// Decrypts and interprets receive codes
// Does Normal Operation and Learn Mode
//
// INPUT:  Buffer contains the received code word
//         
// OUTPUT: S0..S3 and LearnOut 
//
void Remote()
{
    // a frame was received and is stored in the receive buffer
    // move it to decryption Buffer, and restart receiving
    memcpy( Buffer, B, 9);
    RFFull = FALSE;                     // ready to receive a new frame

    // decoding
    NormalKeyGen();                     // compute the decryption key 
    Decrypt();                          // decrypt the hopping code portion

    if ( DecCHK() == FALSE)             // decription failed
        return;

    if ( FLearn)
    {
        // Learn Mode

        if ( Find()== FALSE)
        // could not find the Serial Number in memory
        {
            if ( !Insert())             // look for new space
                return;                 // fail if no memory available
        }

        // ASSERT Ind is pointing to a valid memory location
        IDWrite();                  // write Serial Number in memory
        FHopOK = TRUE;              // enable updating Hopping Code
        HopUpdate();                // Write Hoping code in memory

        CFlash = 32;                // request Led flashing
        CTFlash = TFLASH;           // load period timer
        Led = TRUE;                 // start with Led on
        FLearn = FALSE;             // terminate successfully Learn
    } // Learn

    else // Normal Mode of operation
    {
        if ( Find()== FALSE)
            return; 
        if ( !HopCHK())                 // check Hopping code integrity
            return;

        if ( FSame)                     // identified same code as last memorized
        {
            if ( COut >0)               // if output is still active
                COut = TOUT;            // reload timer to keep active
            else
                return;                 // else discard
        }

        else                            // hopping code incrementing properly
        {
            HopUpdate();                // update memory


        // set outputs according to function code
            if ( BIT_TEST(Buffer[3],S0))
                Out0 = ON;
            if ( BIT_TEST(Buffer[3],S1))
                Out1 = ON;
            if ( BIT_TEST(Buffer[3],S2))
                Out2 = ON;
            if ( BIT_TEST(Buffer[3],S3))
                Out3 = ON;

        // set low battery flag if necessary
            if ( BIT_TEST(Buffer[8],VFlag))
                Vlow = ON;

        // check against learned function code
            if ( (( Buffer[7] ^ FCode) & 0xf0) == 0)
                Led = ON;
                
        // init output timer
            COut = TOUT;
        }// recognized
    } // normal mode

} // remote


