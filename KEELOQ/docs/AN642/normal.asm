;-------------------------------------------------------------------------
;  LEGAL NOTICE
;
;  The information contained in this document is proprietary and 
;  confidential information of Microchip Technology Inc.  Therefore all 
;  parties are required to sign a non-disclosure agreement before 
;  receiving this document.
;
; The information contained in this Application Note is for suggestion 
; only.  It is your responsibility to ensure that your application meets 
; with your specifications.  No representation or warranty is given and 
; no liability is assumed by Microchip Technology Incorporated with 
; respect to the accuracy or use of such information or infringement of 
; patents or other intellectual property arising from such use or 
; otherwise.
;-------------------------------------------------------------------------
;  MICROCHIP KEELOQ CODE HOPPING DECODER - NORMAL LEARN
;
;-------------------------------------------------------------------------
	PROCESSOR   PIC16C56A
	RADIX       DEC
    include     <p16c5x.inc>
    __CONFIG _WDT_ON & _CP_ON & _RC_OSC

;-------------------------------------------------------------------------
;CONFIGURATION CONTROL: 
;  -VERSION 1.6  Lucio Di Jasio
;
;           FILE:	NORMAL.ASM.	
;           DATE:	6 JUNE 2001
;           VER.:	1.6   
;           CHKSM:  3973H
;           FUSES:	RC,WDT=ON,CP=ON.
;           ASM.: 	MPASM VERSION 2.61 USED.
;           INCL:	NONE
;
; CHANGES:
;       1. includes __config statement
;       2. name changed to NORMAL.ASM
;       3. processor changed to PIC16C56A
;
;  -VERSION 1.5  S. DAWSON
;
;           FILE:	MCDEC15.ASM.	
;           DATE:	8 SEPTEMBER 1998 
;           VER.:	1.5
;	    FUSES:	RC,WDT=ON,CP=ON.
;           ASM.: 	MPASM VERSION 2.13 USED.
;	    INCL:	NONE
;
;
;     1.  CODE HAS BECOME A RESERVED WORD IN MPASM - CHANGED IT TO DISC
;     2.  ADDED DISCLAIMER
;
;  -FIFTH VERSION 18 APRIL 1996, S.G. DAWSON
;
;           FILE:	MCDEC14.ASM.	
;           DATE:	18 APRIL 1996. 
;           VER.:	1.4
;	    FUSES:	RC,WDT=ON,CP=ON.
;           ASM.: 	MPASM VERSION 1.30.01 USED.
;	    INCL:	NONE
;           
;
;      1.  STEMMING FROM THE MODIFICATION MADE IN THE 3RD REVISION.
;          THE NUMBER OF ROTATIONS IS DEPENDENT ON WHERE IN THE RECEIVE
;          ROUTINE THE RECEPTION FAILS.  IF FAIL ON THE FIRST SAMPLE THE
;          REGISTER WON'T HAVE BEEN SHIFTED.  FAILING ON THE 3RD BIT THE
;          SHIFT REGISTER WILL HAVE BEEN SKEWED.  ADDING RMT01 ALLOWS THE 
;          CORRECTION ONLY TO BE DONE IF THE REGISTER HAS BEEN SKEWED.
;      2.  MORE CHANGES TO COMMENTS INCLUDING INVERTING THE ORDER OF 
;          REVISION INFORMATION SO THAT THE MOST RECENT IS AT THE TOP OF
;          THE LIST.
;          
;  -FOURTH VERSION APRIL 1996, S.G. DAWSON
;
;           FILE:	MCDEC13.ASM.	
;           DATE:	APRIL 1996. 
;           VER.:	1.3
;	    FUSES:	RC,WDT=ON,CP=ON.
;           ASM.: 	MPASM VERSION 1.30.01 USED.
;	    INCL:	NONE
;           
;
;     1.  LEGAL INFORMATION ADDED.
;     2.  COMMENTS UPDATED TO FIT 75 COLUMN PAGE WIDTH WITH TAB SPACING
;         8 COLUMNS WIDE.
;
;  -THIRD VERSION  MARCH 1996, S.G. DAWSON
;
;           FILE:	MCDEC12.ASM.	
;           DATE:	MARCH 1996. 
;           VER.:	1.2
;	    FUSES:	RC,WDT=ON,CP=ON.
;           ASM.: 	MPASM VERSION 1.30.01 USED.
;	    INCL:	NONE
;           
;    1.  RECEIVE ROUTINE UPDATED TO ALLOW MORE TOLERANCE TO PULSE 
;        DISTORTION AT THE SMALLER BASIC PULSE WIDTHS.  THE PRIMARY 
;        CHANGE MADE SHIFTS THE 64-BIT ROTATION OF THE INPUT BUFFER FROM
;        AFTER THE THIRD SAMPLE IS TAKEN INTO THE DELAY BETWEEN SAMPLING 
;        THE DATA AND THE THIRD SAMPLE BEING TAKEN.  THE THIS ALLOWS THE 
;        RECEPTION ROUTINE TO GET BACK TO POLLING FOR THE RISING EDGE OF 
;        THE FOLLOWING BIT EARLIER AND ALLOWS MORE ROOM FOR PULSE 
;        DISTORTION ON THE FAST SIDE.
;
;  APRIL 1996, S.G. DAWSON
;
;           FILE:	MCDEC12a.ASM.	
;           DATE:	APRIL 1996. 
;           VER.:	1.2a
;	    FUSES:	RC,WDT=ON,CP=ON.
;           ASM.: 	MPASM VERSION 1.30.01 USED.
;	    INCL:	NONE
;           
;     1.  NTQ106 TRANSMISSIONS WERE ROTATED ONCE TOO MANY AS A RESULT OF
;         SHIFTING THE BIT UPDATE TO BEFORE THE 3RD SAMPLE.  THE 
;         MODIFICATION MADE ROTATES THE NTQ106 TRANSMISSIONS CORRECTLY.
;
;  -SECOND VERSION  MARCH 1996, S.G. DAWSON
;
;           FILE:	MCDEC11.ASM.	
;			DATE:	MARCH 1996. 
;			VER.:	1.1
;			FUSES:	RC,WDT=ON,CP=ON.
;			ASM.: 	MPASM VERSION 1.30.01 USED.
;			INCL:	NONE
;
;    1.  RECEIVE ROUTINE UPDATED TO RECEIVE ALL EXISTING KEELOQ ENCODER 
;        TRANSMISSIONS.
;    2.  RTCC UPDATED TO USE TIMER0 OVERFLOW AND KEEP MORE ACCURATE 
;        SYSTEM TIME.
;
;  -FIRST VERSION   9 MAY 1995
;           FILE:	MCDEC10.ASM.
;			DATE:	TUESDAY 9 MAY 1995. 
;			VER.:	1.0
;			CKSM:	2309H - FUSES:RC,WDT=ON,CP=ON.
;			ASM.: 	MPASM VERSION 1.10 USED.
;			INCL:	NONE
;
;
;------------------------------------------------------------------------
  ERRORLEVEL 0,-305,-306  ; Messages, Warnings and Errors Printed
                          ; Ignore [305] => Using default dest of
                          ; 1 file
                          ; Ignore [306] => Crossing Page Boundary

; GENERAL PURPOSE REGISTERS

IND	EQU	00H		; INDIRECT ADDRESS REGISTER
TIMER0	EQU	01H		; REAL TIME COUNTER CLOCK
PC	EQU	02H		; PROGRAM COUNTER
STATUS	EQU	03H             ; STATUS REGISTER
FSR	EQU	04H		; FILE SELECT REGISTER
PORTA	EQU	05H		; PORT A
PORTB	EQU	06H		; PORT B

; USER DEFINED REGISTER

FLAGS	EQU	07H		; USER FLAG REGISTER
ADDRESS	EQU	08H		; ADDRESS REGISTER
TXNUM	EQU	09H		; CURRENT TX
OUTBYT	EQU	0AH		; GENERAL DATA REGISTER
MASK	EQU	OUTBYT		; MASK REGISTER USED IN DECRYPTION

; COUNTER REGISTERS

CNT0    EQU     0BH		; LOOP COUNTERS
CNT1    EQU	0CH		
CNT2    EQU     0DH		

CNT_HI	EQU	0EH		; 16 BIT CLOCK COUNTER
CNT_LW	EQU	0FH		

; TEMP REGISTERS

TMP1	EQU	10H		; TEMP REGISTERS
TMP2	EQU	11H
TMP3	EQU	12H
TMP4	EQU	13H

; CIRCULAR BUFFER REGISTER

CSR4    EQU     14H            	; 64 BIT RECEIVE SHIFT REGISTER
CSR5    EQU     15H            
CSR6    EQU     16H            
CSR7    EQU     17H            

CSR0    EQU     18H            	
CSR1    EQU     19H            
CSR2    EQU     1AH            
CSR3    EQU     1BH            

; WORK REGISTERS

OLD_BUT	EQU	1CH		; STORE PREVIOUS BUTTON CODE
RAM_HI	EQU	1DH		; 16 BIT RAM COUNTER ( USED IN RESYNC )
RAM_LW	EQU	1EH
SREG	EQU	1FH		; PROGRAM STATE INDICATOR REGISTER

; **************  DECRYPTION REGISTER RE-MAPPINGS *******************
;
; NOTE : INDIRECT ADDRESSING USED, DO NOT CHANGE REGISTER ASSIGNMENT 
;
; ******************************************************************

KEY0	EQU	TMP2		; 64BIT SHFT REGISTER WITH DECRYPTION KEY
KEY1	EQU	TMP1
KEY2	EQU	TMP3
KEY3	EQU	TMP4
KEY4	EQU	CSR4
KEY5	EQU	CSR5
KEY6	EQU	CSR6
KEY7	EQU	CSR7

HOP1	EQU	CSR0		; 32 BIT HOPCODE REGISTER
HOP2	EQU	CSR1
HOP3	EQU	CSR2
HOP4	EQU	CSR3

; USER REGISTER RE-MAPPINGS

DAT1	EQU	CSR3		; 32 BIT DATA REGISTER
DAT2	EQU	CSR2
DAT3	EQU	CSR1
DAT4	EQU	CSR0

; NOTE : THESE REGISTERS ARE USED DURING KEYGEN AS A 32 BIT BUFFER

ETMP1	EQU	CNT2		; EXTENDED 32 BIT BUFFER 
ETMP2	EQU	OLD_BUT
ETMP3	EQU	RAM_HI
ETMP4	EQU	RAM_LW

; RECEIVED TRANSMISSION OPEN 32 BITS 

SER_0	EQU	CSR7		; 24/28 BIT SERIAL NUMBER
SER_1	EQU	CSR6
SER_2	EQU	CSR5
SER_3	EQU	CSR4

; RECEIVED TRANSMISSION ENCRYPTED 32 BITS 

FUNC	EQU	DAT1		; BUTTON CODE & USER BIT FUNCTION BYTE
DISC	EQU	DAT2		; DISCRIMINATION VALUE
CNTR_HI	EQU	DAT3		; 16 BIT RX COUNTER
CNTR_LW	EQU	DAT4

; ********* PORTA BIT DEFINITIONS *******

RES0	EQU	0H		; RESERVED
RFIN	EQU	1H		; RF INPUT
LEARN	EQU	2H		; LEARN BUTTON
LED	EQU	3H		; LEARN INDICATOR LED OUTPUT

; ********* PORTB BIT DEFINITIONS *******

S0	EQU	0H		; S0 OUTPUT
S1	EQU	1H		; S1 OUTPUT
S2	EQU	2H		; S2 OUTPUT
S3	EQU	3H		; S3 OUTPUT

DIO	EQU	4H		; EEPROM DATA LINE
CLK	EQU	5H		; EEPROM SERIAL CLOCK
CS	EQU	6H		; EEPROM CHIP SELECT
B_LRN	EQU	7H		; INDICATE FUNCTION LEARNT WAS RECEIVED

; ********* COMPILER DEFINES ******************
NBITS   EQU     64      	; MAXIMUM TRANSMISSION BIT LENGTH
MIN     EQU     540            	; TRANSMISSION HEADER MINIMUM LENGTH [æS]
MAX     EQU     10800 		; TRANSMISSION HEADER MAXIMUM LENGTH [æS]
TRISA	EQU	0111B		; PORTA: TRI-STATE VALUE
WRCFG	EQU	00000000B	; PORTB: EEPROM WRITE TRI-STATE VALUE
RDCFG	EQU	00010000B	; PORTB: EEPROM READ TRI-STATE VALUE

;****** NTQ106 FLAGS DEFINITIONS **************
BITIN	EQU	0H		; RESERVED 
FLAG1	EQU	1H		; RESERVED
FLAG2	EQU	2H		; RESERVED 
FLAG3	EQU	3H		; RESERVED
TCHECK	EQU	4H		; INDICATE ONLY 16 BIT COUNTER UPDATE
NTQ106	EQU	5H		; INDICATE MICROCHIP HCS TX RECEIVED
RESYNC	EQU	6H		; RESYNCH ACTIVE BIT
OUT_500	EQU	7H		; INDICATE BUSY WITH 500MS TIMEOUT ON 
				; OUTPUT

;******* PROGRAM STATES ***********************
PASS1	EQU	0C9H		; LEARN FIRST PASS
PASS2	EQU	0CAH 		; LEARN SECOND PASS
NORMAL	EQU	05CH		; NORMAL PROGRAM FLOW
BUSY	EQU	0C7H		; INDICATE LEARN STILL BUSY

;****** STATUS REGISTER BIT DEFINITIONS *****************
C       EQU       0		; CARRY
DC      EQU       1		; DIGIT CARRY
Z       EQU       2		; ZERO
PD      EQU       3		; POWER DOWN
TO      EQU       4		; TIMEOUT
PA0     EQU       5		; PAGE SELECT [0 OR 1]
PA1     EQU       6		; NOT USED IN PIC16C54, 16C56
OVF     EQU       7		; TIMER0 OVERFLOW

;-------------------------------------------------------------------------
; PAGE 0: 
;-------------------------------------------------------------------------
	ORG 00H

;-------------------------------------------------------------------------
;
; FUNCTION     : RESET ()	      			
;
; DESCRIPTION  : PROGRAM RESET ROUTINE
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
RESET	
	MOVLW	000111B			; SETUP TIMER0 PRESCALER
	OPTION

	CLRF	PORTA			; RESET PORTA
	CLRF	PORTB			; RESET PORTB

	MOVLW	TRISA			; SETUP PORTA FOR ALL OUTPUT
	TRIS	PORTA
	MOVLW	RDCFG			; UPDATE TRIS REGISTER FOR PORTB
	TRIS 	PORTB

	CLRF	FUNC			; RESET FUNCTION BYTE
	CLRF	OLD_BUT			; RESET OLD BUTTON CODE
	CLRF	FLAGS			; RESET FLAGS
	CLRF	CNTR_HI			; RESET CLOCK COUNTER
	CLRF	CNTR_LW

	MOVLW	NORMAL			; INDICATE NORMAL PROGRAM FLOW
	MOVWF	SREG

	BSF	STATUS,PA0		; SELECT PAGE #1
	GOTO	MAIN			; GOTO MAIN PROGRAM LOOP

;-------------------------------------------------------------------------
; UPPER PAGE CALLS
;-------------------------------------------------------------------------
SENDC	
	GOTO	SENDC1			; UPPER PAGE CALL TO SENDC

TST_LEARN
	GOTO	TST_LEARN1		; CALL LEARN BUTTON TEST ROUTINE

;-------------------------------------------------------------------------
;
; FUNCTION     	: CHK_TIMER ()	      			
;
; DESCRIPTION  	: TEST TIMEMOUT DURING EEPROM ROUTINES
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
CHK_TIMER
	CLRWDT				; RESET WATCHDOG TIMER
	BTFSS	TIMER0,7			; TEST FOR 32MS EVENT
	RETLW	0
	
	BCF	TIMER0,7			; CLEAR MSB OF TIMER0
	INCF	CNT_LW			; INCREASE 16 COUNTER
	SKPNZ
	INCF	CNT_HI			

	MOVLW	10D			; 10 x 32.7 ms EEPROM ACK TIMEOUT
	BTFSS	FLAGS,TCHECK		; FIRST TIME FLAG
	MOVWF	CNT1

    	BSF	FLAGS,TCHECK		; INDICATE NOT FIRST TIME PASS
	DECFSZ	CNT1			; CHECK FOR EEPROM ACK TIMEOUT
	RETLW	0
	GOTO	RESET			; ... EEPROM WAIT TIMEMOUT 

;-------------------------------------------------------------------------
;
; FUNCTION     	: ROT_SHIFT()	      			
;

; DESCRIPTION  	: RIGHT ROTATE 64 BIT RECEIVE SHIFT REGISTER
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
ROT_SHIFT
        RRF     CSR7
        RRF     CSR6                     
        RRF     CSR5                     
        RRF     CSR4                     
        RRF     CSR3                     
        RRF     CSR2                     
        RRF     CSR1                    
        RRF     CSR0                    
	RETLW	0

;-------------------------------------------------------------------------
;
; FUNCTION        : NTQ_LP1 ()
;
; DESCRIPTION     : WAIT FOR CNT1 TIMES 1 MS
;			CNT2 = OSC/[4*6*1000]  [ 1MS ]
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
NTQ_LP1
	MOVLW	200D			; DELAY COUNTER FOR 1 MS
	MOVWF	CNT2
NTQ_LP2
	NOP				; [1] WASTE TIME
	CLRWDT				; [1]
	DECFSZ	CNT2			; [1]
	GOTO	NTQ_LP2			; [2]

	DECFSZ	CNT1			; [1]
	GOTO	NTQ_LP1			; [2]
	RETLW	0

;-------------------------------------------------------------------------
;
; FUNCTION     	: ROTR()	      			
;
; DESCRIPTION  	: ROTATE 16 BIT SHIFT REGISTER RIGHT
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
ROTR
        RRF     TMP1
        RRF     TMP2
        BCF     TMP1,7
        SKPNC
        BSF     TMP1,7
        RETLW   0

;-------------------------------------------------------------------------
;
; FUNCTION     	: ROTL()	      			
;
; DESCRIPTION  	: ROTATE 16 BIT SHIFT REGISTER LEFT
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
ROTL
        RLF     TMP2
        RLF     TMP1
        BCF     TMP2,0
        SKPNC
        BSF     TMP2,0
        RETLW   0

;-------------------------------------------------------------------------
; Memory Map ROM Keys
;-------------------------------------------------------------------------
	ORG	3FH
KEY_LOOKUP
	ADDWF	PC,1			; ADD OFFSET TO PROGRAM COUNTER

KEYBASE	EQU	$			; BASE ADDRESS 40H
MAS_KEY	EQU	$			; MASTER KEY BASE ADDRESS
	RETLW	0EFH			; MKEY_0 LSB
	RETLW	0CDH			; MKEY_1
	RETLW	0ABH			; MKEY_2
	RETLW	089H			; MKEY_3
	RETLW	067H			; MKEY_4
	RETLW	045H			; MKEY_5
	RETLW	023H			; MKEY_6
	RETLW	001H			; MKEY_7 MSB

EN_KEY	EQU	$			; ENVELOPE KEY BASE ADDRESS
	RETLW	0FFH			; EN_KEY_0 LSB
	RETLW	0FFH			; EN_KEY_1 MSB

EE_KEY	EQU	$			; EEPROM KEY BASE ADDRESS
	RETLW	088H			; EKEY_0 LSB
	RETLW	077H			; EKEY_1
	RETLW	066H			; EKEY_2
	RETLW	055H			; EKEY_3
	RETLW	044H			; EKEY_4
	RETLW	033H			; EKEY_5
	RETLW	022H			; EKEY_6
	RETLW	011H			; EKEY_7 MSB

;-------------------------------------------------------------------------
;
; FUNCTION     	: TST_RTCC ()	      			
;
; DESCRIPTION  	: TEST TIMER0 COUNTER AND UPDATE OUTPUT IF REQUIRED
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
TST_RTCC
	CLRWDT				; RESET WATCHDOG TIMER
	MOVFW	STATUS
	XORWF	TIMER0,W
	ANDLW	080H

	BTFSS	STATUS,Z
	GOTO	TST_RTCC_2		; TEST FOR 32MS TIMEOUT
	RETLW	0H			; QUICK RETURN TO RECEIVE ROUTINE

; **** INCREASE 16 BIT CLOCK TIMER *******
TST_RTCC_2
	BCF	STATUS,OVF
	MOVFW	TIMER0
	ANDLW	080H
	IORWF	STATUS

	INCF	CNT_LW			; INCREASE 16 COUNTER
	BTFSC	STATUS,Z		; INCR MS BYTE IF ZERO (OVERFLOW)
	INCF	CNT_HI

	MOVLW	TRISA			; UPDATE TRIS REGISTER FOR PORTA
	TRIS 	PORTA
	MOVLW	RDCFG			; UPDATE TRIS REGISTER FOR PORTB
	TRIS 	PORTB

	BTFSS	TIMER0,7		; TEST FOR 32MS TIMEOUT
	RETLW	0H			; QUICK RETURN TO RECEIVE ROUTINE


; *********** UPDATE LED IF REQUIRED ********
TST_LED
	MOVLW	PASS1			; TEST IF IN 1ST PASS OF SELFLEARN
	XORWF	SREG,W
	SKPZ				; ... IF NOT BYPASS
	GOTO	TST_500
	BSF	PORTA,LED		; INDICATE 1ST VALID TX RECEIVED

; ***** TEST FOR 500 MS TIMEMOUT ON OUTPUTS **********
TST_500
	BTFSS	CNT_LW,4		; TEST FOR 500 MS TIMEOUT
	GOTO	TST_30			; ... IF NOT TEST 30S TIMEOUT

	BCF	FLAGS,OUT_500		; RESET 500 MS OUTPUT INICATION
	BCF	PORTB,B_LRN		; RESET LEARN BUTTON CODE
	MOVLW	0F0H
	ANDWF	PORTB,1			; DOWN ALL PULSE OUTPUTS 
	CLRF	OLD_BUT

 ; ********* TEST FOR 30 S LEARN TIMEOUT *************
TST_30	
	MOVLW	NORMAL			; TIMEOUT USE ONLY WITH LEARN
	XORWF	SREG,W
	SKPNZ
	GOTO	TST_END			; ... IF NOT RETURN 

	BTFSC	CNT_HI,2		; TEST FOR LEARN TIMEOUT
	GOTO	RESET			; IF TIMEMOUT FORCE SOFT RESET

TST_END	
	RETLW	0H


;-------------------------------------------------------------------------
;
; FUNCTION     	: DECRYPT ()	      			
;
; DESCRIPTION  	: DECRYPTS 32 BIT [HOP1:HOP4] USING [CSR0:CSR7]
;
; PAGE		: 0 ( NOTE : MUST BE LOWER HALF OF PAGE )
;
;-------------------------------------------------------------------------
DECRYPT
        MOVLW   11+1            ; OUTER LOOP 11+1 TIMES 
        MOVWF   CNT1          	; OUTER LOOP 11+1 TIMES 

DECRYPT_OUTER
        MOVLW   48              ; INNER LOOP 48 TIMES
        MOVWF   CNT0          	; INNER LOOP 48 TIMES

DECRYPT_INNER
	CLRWDT			; RESET WATCHDOG TIMER
        MOVFW   CNT1		; LAST 48 LOOPS RESTORE THE KEY
        XORLW   1               ; LAST 48 LOOPS RESTORE THE KEY
        SKPNZ                   ; LAST 48 LOOPS RESTORE THE KEY
        GOTO    ROTATE_KEY      ; LAST 48 LOOPS RESTORE THE KEY

        ; THE LOOKUP TABLE IS COMPRESSED INTO IN 4 BYTES TO SAVE SPACE
        ; USE THE 3 LOW INDEX BITS TO MAKE UP AN 8-BIT BIT MASK
        ; USE THE 2 HIGH INDEX BITS TO LOOK UP THE VALUE IN THE TABLE
        ; USE THE BIT MASK TO ISOLATE THE CORRECT BIT IN THE BYTE
        ; PART OF THE REASON FOR THIS SCHEME IS BECAUSE NORMAL TABLE 
        ; LOOKUP REQUIRES AN ADDITIONAL STACK LEVEL
							
        CLRC                    ; CLEAR CARRY (FOR THE LEFT SHIFT)
       
        MOVLW   1               ; INITIALISE MASK = 1
        BTFSC   HOP3,3       	; SHIFT MASK 4X IF BIT 2 SET
        MOVLW   10000B          ; SHIFT MASK 4X IF BIT 2 SET
        MOVWF   MASK            ; INITIALISE MASK = 1

        BTFSS   HOP2,0       	; SHIFT MASK ANOTHER 2X IF BIT 1 SET
        GOTO    $+3
        RLF     MASK
        RLF     MASK            

        BTFSC   HOP1,0       	; SHIFT MASK ANOTHER 1X IF BIT 0 SET
        RLF     MASK

        ; MASK HAS NOW BEEN SHIFTED 0-7 TIMES ACCORDING TO BITS 2:1:0

        MOVLW   0               ; TABLE INDEX = 0
        BTFSC   HOP4,1
        IORLW   2               ; IF BIT 3 SET ADD 2 TO THE TABLE INDEX
        BTFSC   HOP4,6
        IORLW   4               ; IF BIT 4 SET ADD 4 TO THE TABLE INDEX

        ADDWF   PC              ; ADD THE INDEX TO THE PROGRAM COUNTER
				;  [ MUST BE IN LOWER HALF OF PAGE ]
                               
TABLE
        MOVLW   02EH            ; BITS 4:3 WERE 00
        GOTO    TABLE_END       ; END OF LOOKUP

        MOVLW   074H            ; BITS 4:3 WERE 01
        GOTO    TABLE_END       ; END OF LOOKUP

        MOVLW   05CH            ; BITS 4:3 WERE 10
        GOTO    TABLE_END       ; END OF LOOKUP

        MOVLW   03AH            ; BITS 4:3 WERE 11
                                 
TABLE_END
        ANDWF   MASK            ; ISOLATE THE CORRECT BIT
        MOVLW   0               ; COPY THE BIT TO BIT 7
        SKPZ                    ; COPY THE BIT TO BIT 7
        MOVLW   10000000B       ; COPY THE BIT TO BIT 7

        XORWF   HOP2,W    	; ONLY INTERESTED IN BIT HOP2,7
        XORWF   HOP4,W    	; ONLY INTERESTED IN BIT HOP4,7
        XORWF   KEY1,W		; ONLY INTERESTED IN BIT KEYREG1,7

        MOVWF   MASK            ; STORE W TEMPORARILY (WE NEED BIT 7)
        RLF     MASK            ; LEFT ROTATE MASK TO GET BIT 7 INTO CARRY

        RLF     HOP1         	; SHIFT IN THE NEW BIT
        RLF     HOP2
        RLF     HOP3
        RLF     HOP4

ROTATE_KEY
        CLRC			; CLEAR CARRY
        BTFSC   KEY7,7       	; SET CARRY IF LEFTMOST BIT SET
        SETC                    ; SET CARRY IF LEFTMOST BIT SET

        RLF     KEY0         	; LEFT-ROTATE THE 64-BIT KEY 
        RLF     KEY1
        RLF     KEY2
        RLF     KEY3
        RLF     KEY4
        RLF     KEY5
        RLF     KEY6
        RLF     KEY7         
	

        DECFSZ  CNT0          	; INNER LOOP 48 TIMES
        GOTO    DECRYPT_INNER   ; INNER LOOP 48 TIMES

        DECFSZ  CNT1          	; OUTER LOOP 12 TIMES (11+1 TO RESTORE KEY)
        GOTO    DECRYPT_OUTER   ; OUTER LOOP 12 TIMES (11+1 TO RESTORE KEY)

        RETLW   0               ; RETURN 


;-------------------------------------------------------------------------
;
; FUNCTION      : RECEIVE ()
;
; DESCRIPTION   : RECEIVE ROUTINE FOR NTQ106/HCS TRANSMITTERS
;
; PAGE          : 0
;
;-------------------------------------------------------------------------
RECEIVE

;******** WAIT FOR HEADER AND CALIBRATE *******************
	BCF     FLAGS,NTQ106            ; RESET NTQ106 TRANSMISSION FLAG
	BTFSS   PORTA,RFIN              ; INPUT LOW?
	GOTO    RMT_0                   ; YES; RECEIVE ERROR

	MOVLW   10                      ; 10 ms TIMER
	MOVWF   CNT1
RCV0
	MOVLW   200
	MOVWF   CNT0
RCV1
	BTFSS   PORTA,RFIN              ; INPUT HIGH?
	GOTO    RCV2                    ; NO, JUMP OUT OF LOOP
	DECFSZ  CNT0                    ; YES, CONTINUE WITH TIMING LOOP
	GOTO    RCV1                    ; 5 us X CNT0
	DECFSZ  CNT1                    ; DO 1 ms LOOP CNT1 TIMES
	GOTO    RCV0
RCV2
	CLRF    CNT0                    ; CLEAR CALIB COUNTER LOW BYTE
	CLRF    CNT1                    ; CLEAR CALIB COUNTER HIGH BYTE
RCV3
	BTFSC   PORTA,RFIN              ; [2][2] INPUT HIGH?
	GOTO    RCV6                    ; [0][0] YES--END CALIBRATION
	MOVLW   (MAX+2559)/10/256       ; [1][1] LOAD W WITH TIMEOUT VALUE
	INCF    CNT0                    ; [1][1] LOW BYTE OF COUNTER
	BTFSS   STATUS,Z		; [1][2] OVERFLOW IN LOW BYTE?
	GOTO    RCV5                    ; [2][0] NO-DON'T UPDATE HIGH BYTE
RCV4
	INCF    CNT1                    ; [0][1] YES--INCREMENT HIGH BYTE
	SUBWF   CNT1,W                  ; [0][1] COUNTER > MAX.?
	BTFSC   STATUS,C		; [0][2] COUNTER > MAX.?
	GOTO    RMT_0                   ; [0][0]   YES--HEADER TOO LONG
RCV5
	CLRWDT                          ; [1][1]
	GOTO    RCV3                    ; [2][2] LOOP BACK
					; TOTAL 10/13us (WTH/WTHOUT CARRY)
RCV6
	CLRC
	RRF     CNT1
	RRF     CNT0
	RRF     CNT1
	RRF     CNT0
	RRF     CNT1
	RRF     CNT0                    ; TOTAL:  7 us
					; DIVIDE CNT1:CNT0 BY 8 (600/8=75)
	MOVLW   MIN/80
	SUBWF   CNT0,W
	BTFSS   STATUS,C		; NEGATIVE?
	GOTO    RMT_0                   ; YES--HEADER SHORTER THAN MIN.

; ************* VALID HEADER RECEIVED *********************
RCV7
	MOVLW   NBITS                   ; VALID START MARKER WAS RECEIVED
	MOVWF   CNT1
	MOVF    CNT0,W
	MOVWF   CNT2                    ; CNT2 = CNT0
	MOVLW   5
	SUBWF   CNT2,1
	GOTO    DL1                   ; COMPENSATE FOR FIRST BIT

;*************** WAIT FOR NEXT BIT ************************
; First timeout--to prevent HCS preamble being
; seen as data when the decoder calibrates on the
; HCS Guard Time.
; Normal mode data arrives at 0.5 Te
; Preamble pulses arrive at 1.5 Te
; Timeout = 1 Te
;
; Second Timeout--To check for HCS360 narrow mode
; Timeout = 1.5 Te (middle of preamble if not narrow mode)
;
; Third Timeout--Wait for narrow mode bit
; Bit arrives after 1 Te
; Timeout must be 1.5 Te for maximum value of Te, which 
; can't be done with a 5 cycle loop and 8 bit counter.
; Thus make timeout = 255x5 = 1275 = 1.18 Te(max)
;**********************************************************

RCV8					; Timeout = 1BPW
	MOVLW   1H                   	; Compensate for RTCC
	SUBWF   CNT0,0                  ; and CSR processing
	MOVWF   CNT2
RCV9
	BTFSC   PORTA,RFIN              ; (2) Wait for Next rising edge
	GOTO    RCV11                   ; (0) If rising edge found, sample
	GOTO    $+1                     ; (2) Delay 2 cycles
	CLRWDT                          ; (1) Clear watchdog Timer
	DECFSZ  CNT2                    ; (1) Decrement Timeout Value
	GOTO    RCV9                    ; (2) Loop Back
RCV9A
	RLF     CNT0,W
	MOVWF   CNT2                    ; 6xCNT0x2 = 3/2(CNT2x8) = 1.5 Te
RCV10
	BTFSC   PORTA,RFIN              ; (2) Check if clear - Data
	GOTO    RMT01			; (0) If high - Preamble
	CLRWDT                          ; (1) Clear watchdog Timer
	DECFSZ  CNT2,1                  ; (1) Decrement Timeout Counter
	GOTO    RCV10                   ; (2) Loop back

	MOVLW   0FFH                    ; Timeout = 1.18 Te(max)
	MOVWF   CNT2                    ; Refer to explanation above
RCV10A
	BTFSC   PORTA,RFIN              ; (2) Wait for rising edge
	GOTO    RCV11                   ; (0) Edge found--Process
	DECFSZ  CNT2,1                  ; (1) Decrement Timeout counter
	GOTO    RCV10A                  ; (2) Loop Back
	GOTO    RMT01			; (0) (5) TIMEOUT--no edge found
RCV11
	MOVF    CNT0,W                  ; CALIBRATION COUNTER
	MOVWF   CNT2                    ; (NOMINALLY 75 FOR 300 us PULSE)

	DECF    CNT2
	DECF    CNT2
	GOTO    $+1
DL1
	CLRWDT                          ; RESET WATCHDOG TIMER
	DECFSZ  CNT2                    ;
	GOTO    DL1                     ; CNT0 X 4 us

	BTFSS   PORTA,RFIN              ; INPUT HIGH?  FIRST SAMPLE
	GOTO    RMT01			; NO--ERROR

	MOVF    CNT0,W                  ; CALIBRATION COUNTER
	MOVWF   CNT2                    ; (NOMINALLY 75 FOR 300 us PULSE)
	DECF    CNT2
	CLRC                            ; OPTIONAL--LITTLE DIFFERENCE
	RLF     CNT2                    ; MULTIPLY BY 2 FOR 600 us
	GOTO    $+1
DL2
	CLRWDT                          ; RESET WATCHDOG TIMER
	DECFSZ  CNT2
	GOTO    DL2                     ; CNT0 X 4 us

	BCF     FLAGS,BITIN             ; CLEAR BIT POSITION
	BTFSS   PORTA,RFIN              ; LEAVE 0 IF LINE HIGH
	BSF     FLAGS,BITIN             ; MAKE 1 IF LINE LOW

	MOVF    CNT0,W                  ; CALIBRATION COUNTER
	MOVWF   CNT2                    ; (NOMINALLY 75 FOR 300 us PULSE)
	CLRC                            ; OPTIONAL--LITTLE DIFFERENCE
	RLF     CNT2                    ; MULTIPLY BY 2 FOR 600 us
	MOVLW	5			; [1]
	SUBWF	CNT2			; [1]
	BCF	STATUS,C		; [1]
	CALL    ROT_SHIFT               ; [10]+[2] CSR SHIFT + CALL
	BTFSC   FLAGS,BITIN		; [1]
	BSF     CSR7,7			; [1]

DL3
	CLRWDT                          ; RESET WATCHDOG TIMER
	DECFSZ  CNT2                    ;
	GOTO    DL3                     ; CNT0 X 4 us

	BTFSC   PORTA,RFIN              ; INPUT LOW?  THIRD SAMPLE
	GOTO    RMT0                    ; NO--RECEIVE ERROR

	CALL    TST_RTCC                ; CHECK RTCC


	DECFSZ  CNT1                    ; LAST BIT?
	GOTO    RCV8                    ; NO--GET NEXT BIT
	GOTO    RMT1

RMT_0
	BSF     CNT1,4                  ; HEADER ERROR--FORCE COUNTER > 8

RMT0					; HERE IF FAIL ON 3RD SAMPLE
	DECF	CNT1,1			; COMPENSATE FOR ROTATE BEFORE DL3

RMT01					; HERE IF FAIL ON 1ST SAMPLE
	CALL    TST_RTCC                ; CHECK RTCC

	MOVLW   9H                      ; TEST FOR NTQ106 TRANSMISSION
	SUBWF   CNT1,W                  ; IF CARRY FLAG SET (RX NOT OK)
	BTFSC   STATUS,C
	RETLW   0                       ; HERE IF NOT ALL BITS RECEIVED OK
RMT2
	CALL    ROT_SHIFT               ; COMPLETE 64-BIT SHIFT
	DECFSZ  CNT1                    ; COMPLETE 64-BIT SHIFT
	GOTO    RMT2
	CLRF    SER_0                   ; CLEAR UPPER BYTE OF SERIAL NR
	BSF     FLAGS,NTQ106            ; INDICATE NTQ106 TX RECEIVED
RMT1	
	CLRC				; CLEAR CARRY FLAG [ RECEIVE OK ]
	MOVFW	SREG
	XORLW	PASS2
	SKPNZ				; DON'T CLR TXNUM CONTAINS LRN POS
	RETLW	0

	BTFSS	FLAGS,OUT_500		; TEST IF 500 MS TIMEOUT 
	BSF	PORTA,LED		; ... IF SO SET LED ON
	CLRC
	RETLW   0                       ; RETURN WITH 1

;-------------------------------------------------------------------------
;
; FUNCTION     	: TST_LEARN ()	      			
;

; DESCRIPTION  	: TEST AND HANDLE LEARN BUTTON
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
TST_LEARN1
	CLRWDT				; RESET WATCHDOG TIMER
	BTFSC	PORTA,LEARN		; CHECK FOR LEARN BUTTON PRESSED
	RETLW	0			; ... IF NOT RETURN
	
	CLRF	CNT_HI			; RESET EVENT COUNTER 
	CLRF	CNT_LW

TST_LEARN2
	CALL	TST_RTCC		; CALL RTCC UPDATE ROUTINE

	BTFSS	CNT_HI,0		; TEST FOR ERASE TIMEMOUT,8.2 SEC
	GOTO	TST_LEARN3		; IF NOT WAIT FOR LEARN KEY LIFT

	MOVLW	PASS1			; INDICATE FIRST STATE OF LEARN
	MOVWF	SREG
	BSF	STATUS,PA0		; SELECT PAGE #1
	GOTO	NTQ_ERASE		; ERASE ALL LEARNED TRANSMITTERS

TST_LEARN3
	BSF	PORTA,LED		; LED ON TO INDICATE LEARN 

	BTFSS	PORTA,LEARN		; WAIT FOR LEARN BUTTON LIFT
	GOTO	TST_LEARN2		; ... IF NOT CHECK TIMER

	MOVLW	2H			; TEST IF LEARN PRESS > THAN 64 MS
	SUBWF	CNT_LW,W					       
	SKPC
	RETLW	0			; ... IF NOT ABORT LEARN

	MOVLW	PASS1			; INDICATE FIRST STATE OF LEARN
	MOVWF	SREG
	RETLW	0H

;-------------------------------------------------------------------------
;
; FUNCTION     	: SENDC ()	      			
;

; DESCRIPTION  	: SEND EEPROM COMMAND 
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
SENDC1
	CLRWDT				; RESET WATCHDOG TIMER

        BCF     PORTB,CS                ; RESET CS STATE
        BCF     PORTB,CLK               ; RESET CLK STATE
        BCF     PORTB,DIO               ; RESET DIO STATE

        MOVLW   WRCFG
        TRIS    PORTB                   ; DIO = OUTPUT
        GOTO    $+1                     ; WAIT FOR OUTPUTS TO SETTLE
        BSF     PORTB,CS                ; SELECT EEPROM
        SETC                            ; START BIT = 1
        MOVLW   9D                 	; START BIT + 8 DATA BITS
	MOVWF	CNT1

SENDC2
        SKPC                            ; TEST BIT
        BCF     PORTB,DIO               ; WRITE TO DIO
        SKPNC                           ; TEST BIT
        BSF     PORTB,DIO               ; WRITE TO DIO
        GOTO    $+1                     ; WAIT 2 US
        RLF     OUTBYT                  ; GET NEXT BIT INTO CARRY
        BSF     PORTB,CLK               ; CLOCK HIGH
        GOTO    $+1                     ; WAIT 2 US
        GOTO    $+1                     ; WAIT 2 US
        BCF     PORTB,CLK               ; CLOCK LOW
	DECFSZ	CNT1			; LOOP COUNTER
        GOTO	SENDC2
        BCF     PORTB,DIO               ; AVOID CONTENTION WITH READ
        RETLW   0

;-------------------------------------------------------------------------
;
; FUNCTION     	: EEWRITE ()	      			
;

; DESCRIPTION  	: ENCRYPT AND WRITE 16 BIT VALUE TO EEPROM 
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
EEWRITE
; ****** ENCRYPT 16-BIT WORD TO WRITE TO EEPROM ***************

FNC
        MOVLW   16D                	; 16 DATA BITS TO ENCRYPT
	MOVWF	CNT1

FNC2
	MOVLW   07H			; MASK ONLY LOWER 3 BITS
        ANDWF   TMP1,W
	MOVWF	OUTBYT			; TEMPORY STORE RESULT
	MOVLW	(EE_KEY-KEYBASE)	; GET BASE ADDRES OF EEPROM KEY
	ADDWF	OUTBYT,W		; ... AND ADD TO RESULT
        CALL    KEY_LOOKUP		; GET BYTE FROM KEY LOOKUP TABLE
        XORWF   TMP2			 
        CALL    ROTR                    ; ROTATE RIGHT 16 BIT WORD
	DECFSZ	CNT1
	GOTO	FNC2

; ******* EEPROM WRITE ENABLE ******************

WRITE0  
	MOVLW	30H			; WRITE ENABLE COMMAND
	MOVWF   OUTBYT               	
        CALL    SENDC			; SEND COMMAND TO EEPROM
        BCF     PORTB,CS                ; END COMMAND, DESELECT

; ******** WRITE 16-BIT WORD TO EEPROM *********

WRITE1  
	MOVFW   ADDRESS			; GET EEPROM ADDRESS
	MOVWF	OUTBYT
        BSF     OUTBYT,6		; WRITE COMMAND
        CALL    SENDC                   ; SEND COMMAND TO EEPROM

	MOVLW	16D			; 16 DATA BITS
        MOVWF   CNT1	                

WRITE2
        BTFSS   TMP1,7			; TEST MSB OF 16 BIT WORD
        BCF     PORTB,DIO		; CLEAR DATA BIT
        BTFSC   TMP1,7			; ... ELSE 
        BSF     PORTB,DIO               ; SET DATA BIT
        GOTO    $+1                     ; WAIT 2 US
        RLF     TMP2                    ; SHIFT LO BYTE
        BSF     PORTB,CLK               ; CLOCK HIGH
        GOTO    $+1                     ; WAIT 2 US
        RLF     TMP1                    ; SHIFT HI BYTE
        BCF     PORTB,CLK               ; CLOCK LOW
	DECFSZ	CNT1
        GOTO	WRITE2             	; LOOP COUNTER
        BCF     PORTB,CS                ; END OF WRITE COMMAND, DESELECT

        MOVLW   RDCFG
        TRIS    PORTB                   ; DIO = INPUT
        BSF     PORTB,CS                ; CS HIGH TO WAIT FOR ACK

WRITE5  
	CALL	CHK_TIMER
	BTFSS	PORTB,DIO		; CHECK FOR ACK
	GOTO	WRITE5

WRITE6  
	BCF     PORTB,CS                ; END OF ACK

; ******* EEPROM WRITE DISABLE ****************
        MOVLW   000H             	; WRITE DISABLE COMMAND
	MOVWF	OUTBYT
        CALL    SENDC
        BCF     PORTB,CS                ; END OF DISABLE COMMAND, DESELECT

	INCF	ADDRESS			; POINT TO NEXT EE ADDR (DEFAULT)
	BSF	STATUS,PA0		; RE-SELECT PAGE #1
	RETLW	0H

;-------------------------------------------------------------------------
;
; FUNCTION     	: EEREAD ()	      			
;
; DESCRIPTION  	: READ 16 BIT VALUE FROM EEPROM AND DECRYPT
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
EEREAD
        MOVFW   ADDRESS
        MOVWF	OUTBYT
        BSF     OUTBYT,7                ; COMMAND = READ
        CALL    SENDC                   ; SEND COMMAND
        MOVLW   RDCFG
        TRIS    PORTB                   ; DIO = INPUT
	MOVLW   16D                	; 16 BITS TO READ
	MOVWF	CNT1

READ0   
	BSF     PORTB,CLK               ; CLOCK HIGH
        RLF     TMP2                    ; SHIFT LO BYTE
        BCF     TMP2,0                  ; ASSUME BIT WILL BE 0
        BTFSC   PORTB,DIO               ; READ DIO LINE
        BSF     TMP2,0                  ; COPY BIT TO REGISTER
        BCF     PORTB,CLK               ; CLOCK LOW
        RLF     TMP1                    ; SHIFT HI BYTE
        DECFSZ  CNT1			; LOOP COUNTER
	GOTO	READ0
        BCF     PORTB,CS                ; END READ CYCLE

; ******* DECRYPT 16-BIT WORD READ FROM EEPROM ***************

IFNC    
	MOVLW   16D
	MOVWF	CNT1

IFNC1   
	CALL    ROTL
	MOVLW	07H			; MASK ONLY LOWER 3 BITS
        ANDWF   TMP1,W
	MOVWF	OUTBYT			; TEMPORY STORE RESULT
	MOVLW	(EE_KEY-KEYBASE)	; GET BASE ADDRES OF EEPROM KEY
	ADDWF	OUTBYT,W		; ... AND ADD TO RESULT
	CALL    KEY_LOOKUP		; KEY BYTE FROM KEY LOOKUP TABLE
        XORWF   TMP2
	DECFSZ	CNT1	
        GOTO	IFNC1

	BSF	STATUS,PA0		; RE-SELECT PAGE #1
	RETLW	0H

;-------------------------------------------------------------------------
;
; FUNCTION     	: LEARN_OK ()
;
; DESCRIPTION  	: FLASH LED FOR 3 SEC [ INDICATE LEARN SUCCESSFUL ]
;
; PAGE		: 0
;
;-------------------------------------------------------------------------
LEARN_OK
	CLRF	CNT_HI			; RESET EVENT COUNTER		
	CLRF	CNT_LW

LEARN_OK2
	CLRWDT				; RESET WATCHDOG TIMER
	BTFSS	TIMER0,7			; TEST FOR 32MS TIMEOUT
	GOTO	LEARN_OK2		; ... IF NOT WAIT

	BCF	TIMER0,7			; RESET TIMER0 CLOCK
	INCF	CNT_LW			; INCREASE 16 COUNTER
	BTFSC	STATUS,Z		; INCREASE UPPER BYTE IF ZERO
	INCF	CNT_HI

	BTFSS	CNT_LW,2
	BCF	PORTA,LED 		; FLASH LED @ 4HZ
	BTFSC	CNT_LW,2		
	BSF	PORTA,LED

	BTFSS	CNT_LW,7		; WAIT FOR 3 SEK
	GOTO	LEARN_OK2
	GOTO	RESET			; RESET SYSTEM

;-------------------------------------------------------------------------
; PAGE 1:
;-------------------------------------------------------------------------
	ORG	200H


;-------------------------------------------------------------------------
; CALLS TO FIRST PAGE
;-------------------------------------------------------------------------

RESET1	
	BCF	STATUS,PA0		; SELECT PAGE #0
	GOTO	RESET			; GOTO RESET

EE_READ1
	BCF	STATUS,PA0		; SELECT PAGE #0
	GOTO	EEREAD			; CALL EEPROM READ ROUTINE

EE_CLEAR1
	CLRF	TMP1			; CLEAR UPPER 16 BITS
	CLRF	TMP2			; ... AND THEN WRITE TO EEPROM

EE_WRITE1
	BCF	STATUS,PA0		; SELECT PAGE #0
	GOTO	EEWRITE			; CALL EEPROM WRITE ROUTINE

;-------------------------------------------------------------------------
;
; FUNCTION     	: CHK_PASS2 ()
;
; DESCRIPTION  	: CHECK FOR PASS2 VALUE IN SREG
;
; PAGE		: 1
;
;-------------------------------------------------------------------------
CHK_PASS2
	MOVLW	PASS2			; TEST IF ON 2ND PASS OF SELFLEARN
	XORWF	SREG,W			; ZERO BIT WILL BE SET 
	RETLW	0

;-------------------------------------------------------------------------
;
; FUNCTION     	: WIPE_TX ()
;
; DESCRIPTION  	: WIPE CURRENT TX SERIAL NUMBER IN EEPROM
;
; PAGE		: 1
;
;-------------------------------------------------------------------------
WIPE_TX
	CLRF	TMP1			; SET TO ZERO
	CLRF	TMP2

	CALL	TX_LOOKUP		; TO GET BASR ADDRESS OF TX
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS

	CALL	EE_CLEAR1		; CLEAR LOWER 16 BITS
	CALL	EE_CLEAR1		; CLEAR UPPER 16 BITS
					; ... DO 1SEC ERROR LED NEXT

;-------------------------------------------------------------------------
;
; FUNCTION     	: ERROR_LED ()
;
; DESCRIPTION  	: LED ON FOR 1 SEC [ INDICATE ERROR ]
;
; PAGE		: 1
;
;-------------------------------------------------------------------------
ERROR_LED
	CLRF	CNT_HI			
	CLRF	CNT_LW

ERROR_LED2
	CLRWDT				; RESET WATCHDOG TIMER
	BTFSS	TIMER0,7			; TEST FOR 32MS TIMEOUT 
	GOTO	ERROR_LED2		; ... ELSE WAIT

	BCF	TIMER0,7			; RESET EVENT CLOCK
	INCF	CNT_LW			; INCREASE 16 COUNTER
	BTFSC	STATUS,Z		; INCREASE UPPER BYTE IF ZERO
	INCF	CNT_HI			

	BSF	PORTA,LED		; LED ON TO INDICATE ERROR

	BTFSS	CNT_LW,5		; WAIT FOR 1 SEK
	GOTO	ERROR_LED2
	GOTO	RESET1			; RESET SYSTEM

;-------------------------------------------------------------------------
;
; FUNCTION     	: TX_LOOKUP ()	      			
;
; DESCRIPTION  	: TRANSMITTER MEMORY LOOKUP TABLE
;
; PAGE		: 1	( NOTE : MUST BE LOWER HALF OF PAGE )
;
;-------------------------------------------------------------------------
TX_LOOKUP
	CALL	TX_LOOKUP2		; GET VALUE FROM LOOKUP TBLE BELOW
	MOVWF	ADDRESS			; STORE VALUE IN ADDRESS REGISTER
	RETLW	0

; ****** LOOKUP TABLE WITH BASE ADDRESS OF TRANSMITTERS ************
	
TX_LOOKUP2
	MOVFW	TXNUM			; GET CURRENT TRANSMITTER
	ADDWF	PC,1
	RETLW	10H			; TX0 BASE ADDRESS 
	RETLW	18H			; TX1 BASE ADDRESS
	RETLW	20H			; TX2 BASE ADDRESS
	RETLW	28H			; TX3 BASE ADDRESS
	RETLW	30H			; TX4 BASE ADDRESS
	RETLW	38H			; TX5 BASE ADDRESS

;-------------------------------------------------------------------------
;
; FUNCTION     	: BUT_LOOKUP ()	      			
;
; DESCRIPTION  	: TRANSMITTER BUTTON LOOKUP TABLE
;
; PAGE		: 1	( NOTE : MUST BE LOWER HALF OF PAGE )
;
;-------------------------------------------------------------------------
BUT_LOOKUP
	MOVFW	TXNUM			; GET CURRENT TRANSMITTER
	ADDWF	PC,1
	RETLW	02H			; TX0 BUTTON CODE ADDRESS
	RETLW	03H			; TX1 BUTTON CODE ADDRESS
	RETLW	08H			; TX2 BUTTON CODE ADDRESS
	RETLW	09H			; TX3 BUTTON CODE ADDRESS
	RETLW	0AH			; TX4 BUTTON CODE ADDRESS
	RETLW	0BH			; TX5 BUTTON CODE ADDRESS

;-------------------------------------------------------------------------
;
; FUNCTION     	: NTQ_KEYGEN ()	      			
;
; DESCRIPTION  	: GENERATE A KEY USING MASTER KEY ( ADDR 40H IN ROM )
;
; PAGE		: 1
;
;-------------------------------------------------------------------------
NTQ_KEYGEN
	MOVLW	KEY7			; POINT TO FIRST KEY BYTE
	MOVWF	FSR

	MOVLW	(MAS_KEY-KEYBASE+7)	; GET TABLE MSB OFFSET FOR M KEY
	MOVWF	CNT1

	MOVLW	8H			; INDICATE 8 BYTE TO READ
	MOVWF	CNT0			; BYTE COUNTER

NTQ_KEYGEN2
	BCF	STATUS,PA0		; SELECT PAGE #0
	MOVFW	CNT1
	CALL	KEY_LOOKUP		; GET BYTE FROM LOOKUP TABLE
	MOVWF	IND			; STORE BYTE IN KEY BYTE
	DECF	FSR			; NEXT ENTRY IN CIRCULAR BUFFER
	DECF	CNT1			; NEXT ENTRY IN KEY LOOKUP TABLE
	BSF	STATUS,PA0		; RE-SELECT PAGE #1
	DECFSZ	CNT0			; ALL BYTES READ
	GOTO	NTQ_KEYGEN2		; ... NO THEN READ NEXT BYTE
	MOVFW	KEY0			; SWAP KEY1 AND KEY0 
	MOVWF	OUTBYT			; NOTE :THIS MUST BE DONE BECAUSE
	MOVFW	KEY1			;       THE TMP1 & TMP2 (KEY0 & 
	MOVWF	KEY0			; 	KEY1) REGISTERS IS ALSO 
	MOVFW	OUTBYT			;       USED  DURING DECRYPTION 
	MOVWF	KEY1			;       (KEYGEN)

	BCF	STATUS,PA0		; SELECT PAGE #0
	CALL	DECRYPT 		; DECRYPT 32 BIT USING MASTER KEY
	BSF	STATUS,PA0		; RE-SELECT PAGE #1
	
	MOVFW	HOP2			; GET LOW 16BIT OF DECRYPTED WORD
	MOVWF	TMP1			
	MOVFW	HOP1
	MOVWF	TMP2
	CALL	EE_WRITE1		; ... AND WRITE TO EEPROM 

	MOVFW	HOP4			; GET UP 16 BIT OF DECRYPTED WORD
	MOVWF	TMP1
	MOVFW	HOP3
	MOVWF	TMP2
	CALL	EE_WRITE1		; ... AND WRITE TO EEPROM

	BTFSC	ADDRESS,1		; TEST IF FIRST 32BIT OF KEY GEN.
	GOTO	S_SEED2			; ... IF SO GENERATE SECOND 32BITS
	GOTO	CALC_END		; ... ELSE KEYGEN COMPLETE

;-------------------------------------------------------------------------
;
; FUNCTION     	: CALC_KEY ()	      			
;
; DESCRIPTION  	: CALCULATE NEW KEY FROM RECEIVED SERIAL NUMBER
;
; PAGE		: 1
;
;-------------------------------------------------------------------------
CALC_KEY
	MOVFW	HOP1			; STORE 32 BIT HOPCODE IN THE 
	MOVWF	ETMP1			; EXTENDED TEMP BUFFER
	MOVFW	HOP2
	MOVWF	ETMP2
	MOVFW	HOP3
	MOVWF	ETMP3
	MOVFW	HOP4
	MOVWF	ETMP4

	CALL	TX_LOOKUP		; GET TRANSMITTER BASE ADDRESS
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS

	MOVFW	SER_2			; GET LOWER 16 BIT OF SERIAL NR
	MOVWF	TMP1
	MOVFW	SER_3
	MOVWF	TMP2
	CALL	EE_WRITE1		; ... AND WRITE TO EEPROM
	
	MOVFW	SER_0			; GET UPPER 16 BIT OF SERIAL NR
	MOVWF	TMP1
	MOVFW	SER_1
	MOVWF	TMP2
	CALL	EE_WRITE1		; ... AND WRITE TO EEPROM

S_SEED1	
	MOVLW	20H			; PATCH IF TX IS MCHIP HCS ENCODER
	BTFSC	FLAGS,NTQ106		
	MOVLW	2BH			; PATCH IF TX IS A NTQ106 ENCODER
	IORWF	SER_0,W
	MOVWF	DAT1

	MOVFW	SER_1			; GET SERIAL NR FROM RX BUFFER
	MOVWF	DAT2
	MOVFW	SER_2
	MOVWF	DAT3
	MOVFW	SER_3
	MOVWF	DAT4
	GOTO	NTQ_KEYGEN		; GENERATE FIRST 32 KEY BITS

S_SEED2	
	CALL	TX_LOOKUP		; GET TRANSMITTER BASE ADDRESS
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS
	CALL	EE_READ1		; READ LOW 16BITS OF SER # FROM EE
	MOVFW	TMP1
	MOVWF	DAT3
	MOVFW	TMP2
	MOVWF	DAT4

	INCF	ADDRESS			
	CALL	EE_READ1		; READ UP 16BITS OF SER # FROM EE
	MOVLW	60H			; PATCH IF TX IS MCHIP HCS ENCODER
	BTFSC	FLAGS,NTQ106		
	MOVLW	65H			; PATCH IF TRANSMITTER IS A NTQ106
	IORWF	TMP1,W
	MOVWF	DAT1
	MOVFW	TMP2			
	MOVWF	DAT2

	INCF	ADDRESS			; POINT TO UPPER 32 BITS OF KEY
	INCF	ADDRESS
	INCF	ADDRESS
	GOTO	NTQ_KEYGEN		; GENERATE SECOND 32 KEY BITS

CALC_END
	MOVFW	ETMP1			; RECOVER 32 BIT HOPCODE FROM 
	MOVWF	HOP1			; EXTENDED BUFFER
	MOVFW	ETMP2
	MOVWF	HOP2
	MOVFW	ETMP3
	MOVWF	HOP3
	MOVFW	ETMP4
	MOVWF	HOP4

	CLRF	CNT_HI			; RESET EVENT CLOCK
	CLRF	CNT_LW
	GOTO	M_HOP

;-------------------------------------------------------------------------
;
; FUNCTION     	: NTQ_ERASE ()
;
; DESCRIPTION  	: ERASE ALL TRANSMITTERS
;
; PAGE		: 1
;
;-------------------------------------------------------------------------
NTQ_ERASE
	BSF	PORTA,LED		; SET LED ON

	MOVLW	1H			; POINT TO LEARN POINTER ADDRESS
	MOVWF	ADDRESS
	CALL	EE_CLEAR1		; NOTE: CURNT PAGE BIT SET TO #0

	CLRF	TXNUM			; POINT TO 1ST TX POSISTION IN EE
NTQ_ERASE2
	CALL	TX_LOOKUP		; GET TX BASE ADRESS
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS

	CALL    EE_CLEAR1	        ; CLEAR LOW 16BITS OF SERIAL NR
	CALL    EE_CLEAR1 	        ; CLEAR UP 16BITS OF SERIAL NR

	INCF	TXNUM			; POINT TO NEXT EEPROM INDEX
	MOVLW	6H			; TEST FOR LAST POSITION
	SUBWF	TXNUM,W
	SKPC				; IF NOT UPDATE NEXT ENTRY
	GOTO	NTQ_ERASE2
	BCF	PORTA,LED		; LED OFF TO IND ERASE ALL COMPLTE

M_ERASE3
	CLRWDT				; RESET WATCHDOG TIMER
	MOVLW	TRISA			; UPDATE TRI-STATE REGISTER
	TRIS	PORTA
	BTFSS	PORTA,LEARN		; WAIT FOR BUTTON LIFT
	GOTO	M_ERASE3	 
	GOTO	MAIN2			; THEN WAIT FOR NEXT TRANMISSION

;-------------------------------------------------------------------------
;
; FUNCTION     	: READ_KEY ()	      			
;
; DESCRIPTION  	: READ 64 BIT KEY FROM EEPROM [CSR0:CSR7] 
;
; PAGE		: 1
;
;-------------------------------------------------------------------------
READ_KEY
	MOVLW	3H			; POINT TO MSB OF KEY
	ADDWF	ADDRESS,1	

	MOVLW	KEY7			; POINT TO LSB OF 64 BIT SHFT REG
	MOVWF	FSR	
	MOVLW	3H			; READ 3x16BIT VALUES FROM EEPROM
	MOVWF	CNT2

READ_KEY2
	CALL	EE_READ1		; READ LOWER 16 BITS
	MOVFW	TMP1			; GET UPPER 8 BITS
	MOVWF	IND			; STORE 1ST 8BITS IN 64BT SHFT REG
	DECF	FSR			; POINT TO NEXT BYTE IN SHFT REG
	MOVFW	TMP2			; GET LOWER 8 BITS
	MOVWF	IND			; STORE 2ND 8BITS IN 64BT SHFT REG
	DECF	FSR			; POINT TO NEXT BYTE IN SHIFT REG
	DECF	ADDRESS			; POINT TO NEXT EEPROM ADDRESS
	DECFSZ	CNT2			; ALL THREE 16-BIT WORDS READ
	GOTO	READ_KEY2		; ... IF NOT GET NEXT 

	CALL	EE_READ1		; READ LOWER 16 BITS
	GOTO	M_DEC			; RETURN TO MAIN PROGRAM LOOP

;-------------------------------------------------------------------------
;
; FUNCTION     	: MAIN ()	      			
;
; DESCRIPTION  	: MAIN PROGRAM ROUTINE
;
; PAGE		: 1
;
;-------------------------------------------------------------------------
MAIN
	MOVLW	1H			; POINT LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_READ1		; READ LEARN POINTER WORD

	BTFSC	TMP2,3			; UPR BIT OF SELFLEARN NIBBLE ZERO
	GOTO	MAIN2			; IF NOT CONTINUE NORMAL PGM FLOW
	BTFSC	TMP2,7			; UPR BIT OF TXNUM NIBBLE ZERO
	GOTO	MAIN2			; IF NOT CONTINUE NORMAL PGM FLOW

	MOVLW	BUSY			; TEST IF LEARN PASS1 WAS ACTIVE 
	XORWF	TMP1,W
	SKPZ				; IF NOT CONTINUE NORMAL PGM FLOW
	GOTO	MAIN2

	SWAPF	TMP2,W			; RECOVER PREVIOUS TX NUMBER
	ANDLW	07H			; MASK ONLY LOWER 3 BITS

	CLRF	TMP1			; RESET SELFLEARN POINTER 
	MOVWF	TXNUM			; ... TO CURRENT TXNUM
	MOVWF	TMP2

	MOVLW	PASS2			; SET PGM IN 2ND PASS OF SELFLRN
	MOVWF	SREG			; .TO ALLOW WRITING OF SER NRS & 
					; .LEARN POINTER

	MOVLW	1H			; WRITE LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_WRITE1		; UPDATE EEPROM
	GOTO	WIPE_TX			; WIPE TX (SELFLEARN UNSUCCESFUL)

MAIN2
	MOVLW	NORMAL			; INDICATE NORMAL PROGRAM FLOW
	MOVWF	SREG

M_LOOP	
	BTFSS	SREG,2			; TEST FOR NORMAL STATE
	GOTO	M_LOOP2

	BTFSS	FLAGS,OUT_500		; TST 500MS TIMEOUT AFTR OUTPUT
	BCF	PORTA,LED		; SET LED OFF IF NORMAL PGM FLOW

M_LOOP2
	BCF	STATUS,PA0		; CLEAR PAGE BIT #0
	CALL	TST_LEARN		; TEST & HANDLE LEARN BUTTON
	CALL	RECEIVE			; RECEIVE TRANSMISSION 
	BSF	STATUS,PA0		; SET PAGE BIT #0

	SKPNC				; CHECK IF TRANSMISSION VALID
	GOTO	M_LOOP			; ... IF NOT WAIT FOR NEXT TX

	MOVLW	0FH			; MAXIMUM SERIAL NUMBER IS 28 BITS
	ANDWF	SER_0,1

	MOVFW	SER_0			; CHECK SERIAL # NOT EQUAL TO ZERO
	IORWF	SER_1,W
	IORWF	SER_2,W
	IORWF	SER_3,W
	SKPNZ				; ... IF ZERO WAIT FOR NEXT TX
	GOTO	M_LOOP

	CALL	CHK_PASS2		; IF ON SECOND PASS OF LEARN 
	SKPZ				; .DON'T CLR,TXNUM HAS LRN POS
	CLRF	TXNUM			; .ELSE POINT TO FIRST TX

; ******* COMPARE LOWER WORD OF SERIAL NUMBER ********
M_SERIAL
	CALL	TX_LOOKUP		; GET TX BASE ADDRESS
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS
	CALL	EE_READ1		; READ LOW 16BITS OF SER # FROM EE
  
	MOVFW	TMP1			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_2,W
	SKPZ				; ... IF NOT EQUAL DO ERROR
	GOTO	M_SER_ERR
	MOVFW	TMP2			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_3,W
	SKPZ				; ... IF NOT EQUAL DO ERROR
	GOTO	M_SER_ERR
	
; ******* COMPARE UPPER WORD OF SERIAL NUMBER ********
M_SERIAL2
	INCF	ADDRESS			; POINT TO NEXT ENTRY 
	CALL	EE_READ1		; READ UP 16BITS OF SER # FROM EE

	MOVFW	TMP1			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_0,W
	SKPZ				; ... IF NOT EQUAL DO ERROR
	GOTO	M_SER_ERR

	MOVFW	TMP2			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_1,W
	SKPZ				; ... IF NOT EQUAL DO ERROR
	GOTO	M_SER_ERR
	
; **************** TEST IF LEARN ACTIVE *******************
M_PASS	
	MOVLW	PASS1			; TEST IF ON FIRST PASS OF LEARN
	XORWF	SREG,W
	SKPNZ				 
	GOTO	CALC_KEY		; IF EQU GENERATE DECRYPTION KEY

	CALL	CHK_PASS2
	SKPNZ				
	GOTO	M_HOP			; IF EQU DECODE TRANSMISSION

	MOVLW	NORMAL			; TEST FOR NORMAL PROGRAM FLOW
	XORWF	SREG,W
	SKPNZ				
	GOTO	M_HOP			; IF EQU DECODE TRANSMISSION
	GOTO	RESET1			; ELSE PGM STATE ERROR => RESET

; ******** SERIAL NUMBER COMPARE ERROR FOUND **************
M_SER_ERR
	CALL	CHK_PASS2		; CHECK IF IN 2ND STATE OF LEARN
	SKPNZ
	GOTO	RESET1			; IF SO WIPE CURRENT TX USING 
                                        ; .RECOVERY

; ******** SEARCH NEXT POSITION FOR SERIAL NUMBER *********
M_NEXT	
	INCF	TXNUM			; POINT TO NEXT TX POSITION
	MOVLW	6H			; TEST FOR LAST POSITION
	SUBWF	TXNUM,W
	SKPC				; ... IF NOT GET NEXT ENTRY
	GOTO	M_SERIAL

; **** SERIAL NUMBER NOT FOUND ( ONLY IN NORMAL / PASS1 ) ****
	MOVLW	PASS1			; TEST IF ON 1ST PASS OF SELFLEARN
	XORWF	SREG,W
	SKPZ				; IF EQUAL CONTINUE 
	GOTO	M_LOOP			; ELSE WAIT FOR NEXT TRANSMISSION

; ****** IF SERIAL NOT IN MAP READ SELFLEARN POINTER ******
	MOVLW	1H			; POINT TO LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_READ1		; READ LEARN POINTER FROM EEPROM

	MOVLW	07H			; MASK TXNUM FROM POINTER
	ANDWF	TMP2,W
	MOVWF	TXNUM

	BTFSS	TXNUM,2			; TXNUM < 4 IS VALID
	GOTO	CALC_KEY		; YES, GENERATE DECRYPTION KEY

	BTFSC	TXNUM,1			; TXNUM > 5 IS INVALID
	CLRF	TXNUM			; ... LEARN POSITION SET TO ZERO
  	GOTO	CALC_KEY		; LEARN CURRENT RECEIVED TX

; *************** DECRYPT HOPCODE *************************
M_HOP	
	CALL	TX_LOOKUP		; LOOK UP TRANSMITTER BASE ADDRESS
	BSF	ADDRESS,2		; ADD 4 TO BASE ADDRESS

	GOTO	READ_KEY		; READ 64 BIT DECODER KEY
M_DEC	
	BCF	STATUS,PA0		; SELECT PAGE #0
	CALL	DECRYPT			; DECRYPT HOPCODE 
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

	MOVLW	PASS1			; TEST IF ON 1ST PASS OF SELFLEARN
	XORWF	SREG,W
	SKPNZ				; IF EQU UPDATE BUTTON CODES & 
	GOTO	M_SL_UPDATE		; .DISCR VALUE

	CALL	CHK_PASS2		; TEST IF ON SECOND PASS OF LEARN
	SKPNZ				; IF EQU CHECK DISCR VALUE
	GOTO	M_DIS

	MOVLW	NORMAL			; TEST FOR NORMAL PROGRAM FLOW
	XORWF	SREG,W
	SKPNZ				; IF EQU CHECK DISCR VALUE
	GOTO	M_DIS

	GOTO	RESET1			; ELSE PGM STATE ERROR => RESET

; **** UPDATE BUTTON CODE AND DISCR VALUE AFTER SELFLEARN ****
M_SL_UPDATE
	MOVLW	1H			; POINT LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_READ1		; READ LEARN POINTER FROM EEPROM

	MOVLW	BUSY			; INDICATE LEARN ACTIVE IN EEPROM
	MOVWF	TMP1			

	MOVLW	0FH			; MASK LEARN POINTER
	ANDWF	TMP2,1
	MOVLW	6H			; TEST FOR INVALID LEARN POINTER
	SUBWF	TMP2,W			; TEST FOR INVALID LEARN POINTER
	SKPNC				; TEST FOR INVALID LEARN POINTER
	CLRF	TMP2			; IF INVALID POINT TO 1ST POSITION

	SWAPF	TXNUM,W			; COPY TXNUM INTO UPPER NIBBLE
	IORWF	TMP2,1

	CALL	EE_WRITE1		; UPDATE LEARN POINTER IN EEPROM

	CALL	BUT_LOOKUP		; GET BUTTON CODE BASE ADDRESS
	MOVWF	ADDRESS
	
	MOVFW	FUNC			; GET CURRENT RX BUTTON CODE
	MOVWF	TMP1
	MOVFW	DISC			; GET CURRENT RX DISCR CODE
	MOVWF	TMP2

	CALL	EE_WRITE1		; AND WRITE BUTTON & DISCR CODES

	MOVFW	CNTR_HI			; STORE ONE RX COUNTER 
	MOVWF	TMP1
	MOVFW	CNTR_LW
	MOVWF	TMP2

	CALL	TX_LOOKUP		; POINT TO LSB WORD OF SERIAL NR
	CALL	EE_WRITE1		; WRITE ONE 16-BIT COUNTER TO EE

	BCF	PORTA,LED		; LED OFF TO SHOW 1ST VALID TX REC
	MOVLW	PASS2			; INDICATE PASS2 OF LRN NOW ACTIVE
	MOVWF	SREG
	GOTO	M_RESYNC		; FORCE A COUNTER RESYNC

; ************** TEST DICRIMINATION VALUE *****************
M_DIS
	CALL	BUT_LOOKUP		; POINT TO BUTTON CODE ADDRESS
	MOVWF	ADDRESS			; STORE VALUE IN ADDRESS REGISTER
	CALL	EE_READ1

	CALL	CHK_PASS2		; CHECK IF IN SECOND PASS OF LEARN
	SKPZ
	GOTO	M_DIS2			; IF NOT CHECK ONLY DISCR VALUE

	MOVFW	TMP1			; CHECK BUT CODE IF ON 2ND PASS 
					; .OF LEARN
	XORWF	FUNC,W
	ANDLW	0F0H			; MASK BUTTON CODES
	SKPZ				; IF EQUAL CONTINUE
	GOTO	RESET1			; ELSE LEARN ERROR, FORCE A RESET

M_DIS2
	MOVFW	TMP2			; CHECK DISCRIMINATION VALUE 
	XORWF	DISC,W
	SKPNZ				; IF EQUAL CONTINUE
	GOTO	M_CNT

	BCF	FLAGS,RESYNC		; RESET RESYNC FLAG
	CALL	CHK_PASS2		; TEST IF IN SECOND PASS OF LEARN 
	SKPNZ
	GOTO	RESET1			; YES, FORCE A RESET
	GOTO	MAIN			; NO, THEN WAIT FOR NEXT TX

; *************** CHECK COUNTERS VALID ************
M_CNT
	BTFSS	FLAGS,RESYNC		; TEST RESYNC BIT
	GOTO	M_CNT1			; IF NOT GET COUNTERS FROM EEPROM

	MOVFW	RAM_HI			; GET PREVIOUS TX COUNTER 
	MOVWF	TMP1
	MOVFW	RAM_LW
	MOVWF	TMP2
	GOTO	M_SUB			; SUBSTRACT FROM CURRENT COUNTER

M_CNT1
	CALL	TX_LOOKUP		; POINT LOWER 16 BIT COUNTER
	CALL	EE_READ1		; READ LOWER 16BIT COUNTER FROM EE

	MOVFW	TMP1			; TEMPORY STORE 1ST 16BIT COUNTER
	MOVWF	TMP3
	MOVFW	TMP2
	MOVWF	TMP4

	INCF	ADDRESS			; POINT TO UPPER 16-BIT COUNTER
	CALL	EE_READ1		; READ UP 16BIT COUNTER FROM EE

	MOVFW	TMP1			; COMPARE UP BYTES OF EE COUNTER
	XORWF	TMP3,W
	SKPZ				; IF EQUAL COMPARE LOWER
	GOTO	M_CNT3			; IF NOT EQUAL FORCE RESYNC

	MOVFW	TMP2			; COMPARE LOW BYTES OF EE COUNTER
	XORWF	TMP4,W
	SKPNZ				; IF NOT EQUAL FORCE RESYNC
	GOTO	M_SUB			; ELSE SUBSTRACT FROM RECEIVED 
					; .COUNTER VALUE

M_CNT3	
	GOTO	M_RESYNC		; FORCE RESYNC (EE CNTERS INVALID)

; ************ CHECK COUNTER WINDOWS ***********
M_SUB
	MOVFW	TMP2			; 16 BIT COUNTER SUBSTRACTION
	SUBWF	CNTR_LW,W
	MOVWF	TMP2			
	SKPC				; SKIP IF NO BORROW
	INCF	TMP1			; ... ELSE INCR HI BYTE
	MOVFW	TMP1
	SUBWF	CNTR_HI,W
	MOVWF	TMP1

	MOVFW	TMP1			; CHECK FOR REPEATED CODES 
	IORWF	TMP2,W
	SKPNZ				; IF NOT EQUAL CONTINUE
	GOTO	M_TZERO			; ELSE RESET EVENT COUNTER AND 
					; .WAIT FOR NEXT TX

M_CHECK0
	BTFSS	FLAGS,RESYNC		; TEST IF RESYNC ACTIVE
	GOTO	M_CHECK1		; IF NOT CHECK FOR COUNTER VALID

	BCF	FLAGS,RESYNC		; RESET RESYNC FLAG
	MOVFW	TMP1			; TEST IF IN 2 WINDOW (UPPER BYTE)
	SKPZ				; ELSE  ABORT
	GOTO	M_CNT_FAIL
	MOVLW	0FEH			; TEST IF CONSECUTIVE 
	ANDWF	TMP2,W			; .TRANSMISSIONS (LOW BYTE)
	SKPNZ				; IF NOT EQUAL COUNTER INVALID
	GOTO	M_UPDATE		; ELSE CNTR VALID, UPDATE EE CNTRS

M_CNT_FAIL
	CALL	CHK_PASS2		; TEST IF ON SECOND PASS OF LEARN
	SKPNZ				
	GOTO	RESET1			; IF SO WIPE CURNT TX (USE RESET)
	GOTO	M_LOOP			; ELSE ABORT 

M_CHECK1
	BTFSC	TMP1,7			; TEST IF IN DARK REGION (> 7FFF)
	GOTO	M_LOOP			; IF SO IGNORE TRANSMISSION

	MOVFW	TMP1			; TEST FOR RESYNC REQUIRED
	SKPZ
	GOTO	M_RESYNC		; DIFFERENCE > 256, FORCE RESYNC

	MOVFW	TMP2			; 16 BIT COUNTER ZERO
	SKPNZ				; 
	GOTO	M_LOOP			; COUNTERS EQUAL, IGNORE TX

M_CHECK2
	MOVLW	0F0H			; TEST IF IN 16 WINDOW
	ANDWF	TMP2,W
	SKPNZ				; IF NOT VALID FORCE CNTER RESYNC
	GOTO	M_UPDATE		; ELSE UPDATE EEPROM COUNTERS

M_RESYNC
	BSF	FLAGS,RESYNC		; INDICATE RESYNC REQUIRED
	MOVFW	CNTR_HI			; STORE CURRENT RXED 16BIT COUNTER
	MOVWF	RAM_HI
	MOVFW	CNTR_LW
	MOVWF	RAM_LW
	GOTO	M_LOOP			; WAIT FOR NEXT TRANSMISSION

; ***************** UPDATE EEPROM COUNTER *****************
M_UPDATE
	CALL	TX_LOOKUP		; GET CURRENT TX BASE ADDRESS
	MOVFW	CNTR_HI			; STORE FIRST 16-BIT RXED COUNTER
	MOVWF	TMP1
	MOVFW	CNTR_LW
	MOVWF	TMP2
	CALL	EE_WRITE1		; WRITE LSB WORD OF SER NR TO EE

	MOVFW	CNTR_HI			; STORE SECOND 16BIT RXED COUNTER
	MOVWF	TMP1
	MOVFW	CNTR_LW
	MOVWF	TMP2
	CALL	EE_WRITE1		; WRITE MSB WORD OF SER NR TO EE

	CALL	CHK_PASS2		; TEST IF ON SECOND PASS OF LEARN
	SKPNZ				; IF NOT CONTINUE
	GOTO	M_PTR			; ELSE UPDATE LEARN POINTER IN EE

	MOVLW	NORMAL			; TEST FOR NORMAL PROGRAM FLOW
	XORWF	SREG,W
	SKPNZ				
	GOTO	M_BUT			; IF EQU CHECK FOR F3 BUTTON
	GOTO	M_LOOP			; ELSE FLASH WAIT FOR NEXT TX

; **** MAYBE UPDATE LEARN POINTER AFTER VAILD SELFLEARN ****
M_PTR
       	MOVLW	1H			; POINT TO LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_READ1		; READ LEARN POINTER FROM EEPROM

	MOVFW	TMP2			; MASK LEARN POINTER
	ANDLW	07H			; STORE RESULT IN W REGISTER
	MOVWF	TMP2			; AND TMP2 REGISTER

	XORWF	TXNUM,W			; LEARNING EXISTING OR NEW TX
	SKPNZ				; TXNUM EQUAL LRN PNTR FOR NEW TX
	INCF	TMP2			; IF NEW TX INCREMENT LRN POINTER

	MOVLW	6H			; TEST FOR LAST POSITION
	SUBWF	TMP2,W			; TEST FOR LAST POSITION
	SKPNC				; TEST FOR LAST POSITION
	CLRF	TMP2			; IF LAST POS POINT TO FIRST POS
	CLRF	TMP1			; ALWAYS CLR UP BYTE OF LRN POINTR

       	MOVLW	1H			; POINT TO LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_WRITE1		; WRITE LEARN POINTER TO EEPROM

	MOVLW	NORMAL			; INDICATE NRMAL PGM FLOW
	MOVWF	SREG
	BCF	STATUS,PA0		; SELECT PAGE #0
	GOTO	LEARN_OK		; THEN INDICATE LEARN SUCCESSFUL

; *************** TEST RECEIVED BUTTON CODE ***************
M_BUT
	BCF	FLAGS,OUT_500		; ILEGAL BUTTON CODE, 
					; .RESET 500MS TIMER FLAG

	MOVFW	PORTB			; CHECK FOR TOGGLE OUTPUT ACTIVE
	ANDLW	0FH
	SKPNZ				; IF ACTIVE CHECK FOR NEW BUT CODE
	GOTO	M_ON			; ELSE UPDATE BUTTON OUTPUT

	MOVFW	FUNC			; CHECK FOR NEW BUT CODE WHILE 
	XORWF	OLD_BUT,W		; .OUTPUT PREVIOUS
	ANDLW	0F0H
	SKPNZ				; IF A NEW BCODE CLR OUTPUT 131MS
	GOTO	M_ON			; ELSE UPDATE OUTPUT

; ***** FORCE OUTPUT DOWN FOR 131 MS BEFORE NEW OUTPUT *****
M_OFF	
	MOVLW	070H			; CLEAR OUTPUTS ON PORTB
	ANDWF	PORTB,1
	BCF	STATUS,PA0		; SELECT PAGE #0
	MOVLW	130D			; WAIT 131 MS
	MOVWF	CNT1
	CALL	NTQ_LP1
	BSF	STATUS,PA0		; SELECT PAGE #1

M_ON
	CALL	BUT_LOOKUP		; READ TX BUTTON CODES FROM EEPROM
	MOVWF	ADDRESS			
	CALL	EE_READ1		

	MOVFW	FUNC			; GET RECEIVED BUTTON CODE
	XORWF	TMP1			; AND COMPARE WITH EEPROM 
	SKPZ
	GOTO	M_OUTPUT		; NOT A LEARNED BUTTON CODE	
	BSF	PORTB,B_LRN		; INDICATE RXED BUTTON CODE LRNED

; ******** UPDATE OUTPUT WITH CURRENT BUTTON CODE *********
M_OUTPUT
	MOVFW	FUNC			; STORE CURRENT RXED BUTTON CODE
	MOVWF	OLD_BUT

	MOVLW	0F0H			; MASK ONLY BUTTON CODES
	ANDWF	FUNC,1
	SWAPF	FUNC,1			; GET BUTTON CODE FROM FUNC BYTE
	
	BTFSC	FUNC,0			; CHANGE BUTTON TO S-OUTPUT FORMAT
	BSF	FUNC,4			; [ S2 S1 S0 S3 ]
	CLRC				
	RRF	FUNC,W			

	IORWF	PORTB,1			; UPDATE OUTPUT WITH BUTTON CODE
	MOVLW	RDCFG			; SETUP TRI-STATE REG OF PORTB
	TRIS	PORTB

M_END2	
	MOVLW	000111B			; SETUP TIMER0 PRESCALER
	OPTION

M_TZERO
	CLRF	CNT_HI			; RESET TIMER0 CLOCK
	CLRF	CNT_LW			
	CLRF	TIMER0

M_END	
	GOTO	M_LOOP			; WAIT FOR NEXT TRANMISSION

;-------------------------------------------------------------------------
; END OF FILE : PIC_DEC.ASM
;-------------------------------------------------------------------------
	ORG	3FFH
	GOTO	RESET
	END


