/**
  ******************************************************************************
  * @file    mem-87x.c
  ******************************************************************************
  */

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
//*********************************************************************
//  Filename:   mem-87x.c
//*********************************************************************
//  Author:     Lucio Di Jasio
//  Company:    Microchip Technology
//  Revision:   Rev 1.00
//  Date:       08/11/00
//
//  Internal EEPROM routines for PIC16F87X 
// 
//  Compiled using HiTech PIC C compiler v.7.93
//  Compiled using CCS    PIC C compiler v. 2.535
//;*********************************************************************

void RDword(word Ind)
{
    Dato = EEPROM_READ( Ind);
    Dato += (word) EEPROM_READ( Ind+1) <<8;
}

void RDnext()
{
    // continue reading
    EEADR++;        // NOTE generate no carry
    Dato = ((RD=1), EEDATA);
    EEADR++;
    Dato += ((RD=1), EEDATA)<<8;
}

void WRword(word Ind)
{
    EEPROM_WRITE( Ind, Dato); GIE = 1; // write and re-enable interrupt
    EEPROM_WRITE( Ind+1, Dato>>8); GIE = 1; 
}

