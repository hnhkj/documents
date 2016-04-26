/**
  ******************************************************************************
  * @file    table.c
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
//  Filename:   TABLE.c
//*********************************************************************
//  Author:     Lucio Di Jasio
//  Company:    Microchip Technology
//  Revision:   Rev 1.00
//  Date:       08/07/00
//
//  EEPROM TABLE Management routines
//     simple "linear list" management method
// 
//  Compiled using HiTech C compiler v.7.93
//  Compiled using CCS    PIC C compiler v. 2.535
//********************************************************************/
#define MAX_USER     8         // max number of TX that can be learned
#define EL_SIZE      8         // single record size in bytes


/*------------------------------------------------------------
; Table structure definition:
;
;  the EEPROM is filled with an array of MAX_USER user records
;  starting at address 0000
;  each record is EL_SIZE byte large and contains the following fields:
;  EEPROM access is in 16 bit words for efficiency
;
;   DatoHi  DatoLo  offset
;  +-------+-------+
;  | FCode | IDLo  |  0    XF contains the function codes (buttons) used during learning
;  +-------+-------+       and the top 4 bit of Serial Number
;  | IDHi  | IDMi  |  +2   IDHi IDMi IDLo contain the 24 lsb of the Serial Number 
;  +-------+-------+
;  | HopHi | HopLo |  +4   sync counter 
;  +-------+-------+
;  | HopHi2| HopLo2|  +6   second copy of sync counter for integrity checking
;  +-------+-------+
;
; NOTE a function code of 0f0 (seed transmission) is considered
; invalid during learning and is used here to a mark location free
;
;------------------------------------------------------------
; FIND Routine
;
; search through the whole table the given a record whose ID match
;
; INPUT:
;   IDHi, IDMi, IDLo,   serial number to search
;
; OUTPUT:
;   Ind                 address of record (if found)
;   EHop                sync counter value
;   ETemp               second copy of sync counter
; RETURN:               TRUE if matching record  found
*/
byte Find()
{
    byte Found;
    Found = FALSE;      // init to not found

    for (Ind=0; Ind < (EL_SIZE * MAX_USER); Ind+=EL_SIZE)
    {
        RDword( Ind);       // read first Word
        FCode = (Dato>>8);
        // check if 1111xxxx
        if ( (FCode & 0xf0) == 0xf0)
            continue;   // empty  

        if (IDLo != (Dato & 0xff))
            continue;   // fails match
        
        RDnext();       // read next word
        if ( ( (Dato & 0xff) == IDMi) && ( (Dato>>8) == IDHi))
        {
            Found = TRUE;     // match
            break;
        }
    } // for

    if (Found == TRUE)
    { 
        RDnext();               // read HopHi/Lo
        EHop = Dato;
        RDnext();               // read HopHi2/Lo2
        ETemp= Dato;
     }

     return Found;
}
/*-----------------------------------------------------------
; INSERT Routine
;
; search through the whole table for an empty space
;
; INPUT:
;   IDHi, IDMi, IDLo,   serial number to insert
;
; OUTPUT:
;   Ind                 address of empty record
;
; RETURN:               FALSE if no empty space found
*/
byte Insert()
{
    for (Ind=0; Ind < (EL_SIZE * MAX_USER); Ind+=EL_SIZE)
    {
        RDword(Ind);        // read first Word
        FCode = (Dato>>8);
        // check if 1111xxxx
        if ( (FCode & 0xf0) == 0xf0)
            return TRUE;    // insert point found
    } // for        

    return  FALSE;          // could not find any empty slot
} // Insert

/*-----------------------------------------------------------
; Function IDWrite 
;   store IDHi,Mi,Lo + XF at current address Ind
; INPUT:
;   Ind                 point to record + offset 0 
;   IDHi, IDMi, IDLo    Serial Number
;   XF                  function code
; OUTPUT:
*/
byte IDWrite()
{
    if (!FLearn) 
        return FALSE;           // Guard statement: check if Learn ON

    Dato = Buffer[7];
    Dato = (Dato<<8) + IDLo;
    WRword(Ind);                // write first word

    Dato = IDHi;
    Dato = (Dato<<8) + IDMi;
    WRword(Ind+2);              // write second word
    
    return TRUE;
} // IDWrite
            
/*------------------------------------------------------------
; Function HopUpdate
;   update sync counter of user record at current location
; INPUT:
;   Ind     record + offset 0
;   Hop     current sync counter
; OUTPUT:
;   none
*/
byte HopUpdate()
{
    if (!FHopOK) 
        return FALSE;           // Guard statement: check if Hop update 

    Hop = ((word)HopHi<<8) + HopLo;
    Dato = Hop;
    WRword(Ind+4);              // write at offset +4
    Dato = Hop;
    WRword(Ind+6);              // back up copy at offset +6
    FHopOK = FALSE;             // for safety disable updating hopping code
    
    return TRUE;
} // HopUpdate

/*-----------------------------------------------------------
; Function ClearMem
;   mark all records free
; INPUT:
; OUTPUT:
; USES:
*/
byte ClearMem()
{
    for (Ind=0; Ind < (EL_SIZE * MAX_USER); Ind+=EL_SIZE)
    {
        Dato = 0xffff;
        WRword( Ind);
    }

    return TRUE;
} // ClearMem

        
