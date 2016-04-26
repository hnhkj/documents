// *********************************************************************
//  Filename:   mem-87x.c
// *********************************************************************
//  Author:     Lucio Di Jasio
//  Company:    Microchip Technology
//  Revision:   Rev 1.00
//  Date:       08/11/00
//
//  Internal EEPROM routines for PIC16F87X 
// 
//  Compiled using HiTech PIC C compiler v.7.93
//  Compiled using CCS    PIC C compiler v. 2.535
// *********************************************************************

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


