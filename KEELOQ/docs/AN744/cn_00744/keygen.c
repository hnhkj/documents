// -------------------------------------------------------------------------
// LEGAL NOTICE
//
//  The information contained in this document is proprietary and 
//  confidential information of Microchip Technology Inc.  Therefore all 
//  parties are required to sign a non-disclosure agreement before 
//  receiving this document.
// -------------------------------------------------------------------------
//
// Keeloq Normal Key Generation and Decryption
//  Compiled using CCS    PIC C compiler v. 2.535
//  Compiled using HITECH PIC C compiler v. 7.93
// 
// version 1.00     08/07/2000 Lucio Di Jasio
// 
// =========================================================================


byte    DKEY[8]; 		// Decryption key
byte    SEED[4];        // seed value = serial number
word    NextHop;        // resync value for 2 Chance

#ifdef HITECH
    #include "fastdech.c"   //  for HITECH optimized version 
#else
    #include "fastdecc.c"   //  for CCS optimized version 
#endif

// ----------------------------------------------------------------------
void LoadManufCode()
{
    DKEY[0]=0xef;   // DKEY=0123456789ABCDEF
    DKEY[1]=0xcd;
    DKEY[2]=0xAB;
    DKEY[3]=0x89;
    DKEY[4]=0x67;
    DKEY[5]=0x45;
    DKEY[6]=0x23;
    DKEY[7]=0x01;
}


//----------------------------------------------------------------------
//
// Key Generation routine
//
// Normal Learn algorithm
//
// INPUT:  Serial Number (Buffer[4..7])
//         Manufacturer code 
// OUTPUT: DKEY[0..7] computed decryption key      
//
void NormalKeyGen()
{
byte	HOPtemp[4]; 	// HOP temp buffer
byte    SKEYtemp[4]; 	// temp decryption key 

        // check if same Serial Number as last time while output active
        // it was stored in Seed 
        if (( SEED[0] != Buffer[4]) ||
            ( SEED[1] != Buffer[5]) ||
            ( SEED[2] != Buffer[6]) || 
            ( SEED[3] != (Buffer[7] & 0x0f)) ||
            (COut == 0))
        {
            // no new KeyGen is needed 
            memcpy( HOPtemp, Buffer, 4);    // save hopping code to temp
            memcpy( SEED, &Buffer[4], 4);   // make seed = Serial Number
            SEED[3] &= 0x0f;                // mask out function codes       

            // compute LSb of decryption key first
            memcpy( Buffer, SEED, 4);       // get SEED in
            Buffer[3] |= 0x20;              // add constant 0x20
            LoadManufCode();           
            Decrypt();
            memcpy( SKEYtemp, Buffer, 4);   // save result for later

            // compute MSb of decryption key 
            memcpy( Buffer, SEED, 4);       // get SEED in
            Buffer[3] |= 0x60;              // add constant 0x60
            LoadManufCode();
            Decrypt();
            memcpy( &DKEY[4], Buffer, 4);   // move it into DKEY MSb
            memcpy( DKEY, SKEYtemp, 4);     // add LSb

            // ready for Decrypt
            memcpy( Buffer, HOPtemp, 4);    // restore hopping code
        }
        else // same Serial Number as last time...
        {   // just keep on using same Decription Key
        } 

} // Normal KeyGen

//----------------------------------------------------------------------
//
// Valid Decryption Check
//
// INPUT:  Serial Number (Buffer[4..7])
//         Hopping Code  (Buffer[0..3])
// OUTPUT: TRUE if discrimination bits == lsb Serial Number
//              and decrypted function code == plain text function code 
byte DecCHK()
{
    // verify discrimination bits
    if ( DisLo != IDLo)     // compare low 8bit of Serial Number
        return FALSE;

    if ( ( (Buffer[3] ^ IDMi) & 0x3)!= 0) // compare 9th and 10th bit of SN 
        return FALSE;

    // verify function code
    if ( ((Buffer[3] ^ Buffer[7]) & 0xf0)!= 0)
        return FALSE;

    return TRUE;
} //  DecCHK



//----------------------------------------------------------------------
//
// Hopping Code Verification
//
// INPUT:  Hopping Code  (Buffer[0..3])
//         and previous value stored in EEPROM EHop
// OUTPUT: TRUE if hopping code is incrementing and inside a safe window (16)
//
byte ReqResync()
{
    F2Chance= TRUE;         // flag that a second (sequential) transmission 
    NextHop = Hop+1;        // is needed to resynchronize receiver
    return FALSE;           // cannot accept for now
}

byte HopCHK()
{
    FHopOK = FALSE;             // Hopping Code is not verified yet
    FSame = FALSE;              // Hopping Code is not the same as previous

    // make it a 16 bit signed integer 
    Hop = ((word)HopHi << 8) + HopLo;   

    if ( F2Chance)
        if ( NextHop == Hop)
        {
            F2Chance = FALSE;       // resync success
            FHopOK = TRUE;       
            return TRUE;
        }
        
    // verify EEPROM integrity
    if ( EHop != ETemp)
        return ReqResync();         // memory corrupted need a resync
    
    // main comparison
    ETemp = Hop - EHop;             // subtract last value from new one

    if ( ETemp < 0)                 // locked region
        return FALSE;               // fail

    else if ( ETemp > 16)           // resync region
        return ReqResync();

    else                            // 0>= ETemp >16 ; open window
    {
        if ( ETemp == 0)            // same code (ETemp == 0)
            FSame = TRUE;           // rise a flag

        FHopOK = TRUE;           
        return TRUE;
    }
} // HopCHK




