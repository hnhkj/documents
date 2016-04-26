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
//   Module GENC.C
// 
//   Keeloq Decryption Algorithm
//      generic implementation in C language 
//
//
//  INPUTS:
//      mpik, mpin      64 bit decryption key (preloaded)
//      csr             32 bit shift register (preloaded with text to decrypt)
//  OUTPUT:
//      csr             32 bit plain text   (decrypted message)
//
#include <stdio.h>

typedef unsigned int  word;
typedef unsigned long dword;

#define setbit( b, n)   ((b) |= ( 1 << (n)))
#define getbit( b, n)   (((b) & (1L<<n)) ? 1 : 0)
#define ifbit(x,y)      if (getbit(x,y))


dword   mpik,mpin;  // decryption key
dword   csr;        // shift register

dword decode(dword csr)

{
  dword lut[32] =
  { 0,1,1,1, 0,1,0,0, 0,0,1,0, 1,1,1,0, 0,0,1,1, 1,0,1,0, 0,1,0,1, 1,1,0,0 };
 /*   E        2        4        7        C        5        A        3   */

  dword pik,pin,bitin,keybit,keybit2;
  word bitlu;
  int ix;


  // Load Key

  pik = mpik;
  pin = mpin;
  

  for(ix=0; ix < 528; ix++)
  {
	 // Rotate Code Shift Register

	 bitin = getbit(csr,31);
	 csr<<=1;

	 // Get Key Bit

	 keybit2=getbit(pin,15);

	 // Rotate Key Right

	 keybit=getbit(pik,31);
	 pik=(pik<<1)|getbit(pin,31);
	 pin=(pin<<1)|keybit; /* 64-bit left rotate */

	 // Get result from Non-Linear Lookup Table

	 bitlu = 0;
	 ifbit (csr, 1) setbit(bitlu,0);
	 ifbit (csr, 9) setbit(bitlu,1);
	 ifbit (csr,20) setbit(bitlu,2);
	 ifbit (csr,26) setbit(bitlu,3);
	 ifbit (csr,31) setbit(bitlu,4);

    // Calculate Result of XOR and shift in 

	 csr    = csr ^ bitin ^ ((csr&0x10000L)>>16) ^ lut[bitlu]
		^ keybit2;
  }
	 return csr;
}


