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
//-------------------------------------------------------------------------
//  LEGAL NOTICE
//
//  The information contained in this document is proprietary and 
//  confidential information of Microchip Technology Inc.  Therefore all 
//  parties are required to sign a non-disclosure agreement before 
//  receiving this document.
//-------------------------------------------------------------------------
//  Keeloq Decryption Algorithm
//
//  optimized for HITECH PIC C compiler v.7.85
// 
//  version 1.00     01/09/2001 Lucio Di Jasio
// 
//  INPUTS:
//      DKEY[0..7]      64bit decryption key (pre loaded)
//      Buffer[0..3]    32bit shift register (pre loaded with text to decrytp)
//  OUTPUTS:
//      Buffer[0..3]    32bit plain text (decrypted message)
// 
//=========================================================================
unsigned char DKEY[8];
unsigned char Buffer[4];

#define BIT_TEST( b, n) (( (b) & (1<<(n))) != 0)

unsigned char aux;      // keep it global for simple use in asm()

void Decrypt()
{
    unsigned char   i, j, key;  // 8 bit unsigned
    signed char     p;          // 8 bit signed
    
    p = 1;
    
    for (j=66; j>0; j--)
    {
        key = DKEY[p--];
        if ( p < 0)
            p += 8;
        for (i=8; i>0; i--)
        {
            // NLF
            if ( BIT_TEST( Buffer[3],6))
            {
                if ( !BIT_TEST( Buffer[3],1))
                    aux = 0b00111010;   // 10
                else
                    aux = 0b01011100;   // 11
            }
            else
            {
                if ( !BIT_TEST( Buffer[3],1))
                    aux = 0b01110100;   // 00
                else
                    aux = 0b00101110;   // 01
            }


            // move bit in position 7
            if ( BIT_TEST( Buffer[2],3)) 
                asm("swapf _aux,f");
            if ( BIT_TEST( Buffer[1],0)) 
                aux<<=2; 
            if (BIT_TEST( Buffer[0],0)) 
                aux<<=1;

            // xor with Buffer and Dkey
            aux ^= Buffer[1] ^ Buffer[3] ^ key;
            
            // shift in buffer
            #asm
            rlf _aux,w
            rlf _Buffer,f
            rlf _Buffer+1,f
            rlf _Buffer+2,f
            rlf _Buffer+3,F
            #endasm

            // rotate Dkey
            key<<=1;
        } // for i
    } // for j
} // decrypt 



