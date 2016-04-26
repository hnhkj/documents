;------------------------------------------------------------------------------
;  MICROCHIP KEELOQ SECURITY SYSTEM
;
;------------------------------------------------------------------------------
;  LEGAL NOTICE
;
;  The information contained in this document is proprietary and 
;  confidential information of Microchip Technology Inc.  Therefore all 
;  parties are required to sign a non-disclosure agreement before 
;  receiving this document.
;------------------------------------------------------------------------------

;**************************************************************************
; Program:      SECSYS14.ASM
;               Microchip EEPROM Alarm System
; Description:  This program is an example of a KeeLoq decoder, based
;               on the Microchip PIC platform.  The code is intended for
;               modification by users to implement their own security
;               systems.
; Processor:    Microchip PIC 16C57
; Assembler:    Microchip MPASM v1.30
; Options:      WDT=On; RC Oscillator (4 MHz); Code Protection=On
;**************************************************************************
; Revision record:
; 1.40  19 July 1996 Fanie Delport
;	a. Included adapted receive routine that can handle a wider range 
;	   of transmission speeds.  
; 1.30  9 June 1996  Kobus Marneweck SECSYS13.ASM
;       a. Added destination to remove warnings
; 1.10  26 October 1995  Fanie Delport SECSYS11.ASM
;       a. Included adapted recieve routine to cater for 
;	   all Keeloq encoders.
;	b. Removed macros.
;	c. Added comments.
; 1.00  02 October 1995  Kobus Marneweck SECSYS10.ASM
;       Initial version, adapted from Microchip decoder v 1.0 by V N Delport
;**************************************************************************

	LIST P=16C57,F=INHX8M,R=DEC

; GENERAL PURPOSE REGISTERS

IND	EQU	00H		; INDIRECT ADDRESS REGISTER
RTCC	EQU	01H		; REAL TIME COUNTER CLOCK
PC	EQU	02H		; PROGRAM COUNTER
STATUS	EQU	03H             ; STATUS REGISTER
FSR	EQU	04H		; FILE SELECT REGISTER
PORTA   EQU     05H		; PORT A
PORTB   EQU     06H		; PORT B
PORTC   EQU     07H		; PORT C

; USER DEFINED REGISTER

ADDRESS	EQU	0CH		; ADDRESS REGISTER
TXNUM	EQU	0DH		; CURRENT TX
OUTBYT	EQU	0EH		; GENERAL DATA REGISTER
MASK	EQU	OUTBYT		; MASK REGISTER USED IN DECRYPTION
TMP_CNT EQU	OUTBYT		; RECEIVE ROUTINE TEMPORARY COUNTER
CSR8	EQU	ADDRESS		; MSB OF RX REGISTER


; COUNTER REGISTERS

CNT0    EQU     18H		; LOOP COUNTERS
CNT1    EQU	19H		
CNT2    EQU     1AH		

CNT_HI	EQU	1BH		; 16 BIT CLOCK COUNTER
CNT_LW	EQU	1CH		

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

CSR0    EQU     08H            	
CSR1    EQU     09H            
CSR2    EQU     0AH            
CSR3    EQU     0BH            

; **** WORK REGISTERS ********

STACK	EQU	1EH		; EXTRA STACK LEVEL
FLAGS	EQU	1FH		; USER FLAG REGISTER
FLAGS1	EQU	0FH		; USER FLAG REGISTER
RAMS	EQU	1DH		; RAM STATE

; **************  DECRYPTION REGISTER RE-MAPPINGS *******************
;
; NOTE : INDIRECT ADDRESSING USED, DO NOT CHANGE REGISTER ASSIGNMENT 
;
; ******************************************************************

KEY0	EQU	TMP2		; 64 BIT SHIFT REGISTER WITH DECRYPTION KEY
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

; ***** USER REGISTER RE-MAPPINGS ***************

DAT1	EQU	CSR3		; 32 BIT DATA REGISTER
DAT2	EQU	CSR2
DAT3	EQU	CSR1
DAT4	EQU	CSR0

; NOTE : THESE REGISTERS ARE USED DURING KEYGEN AS A 32 BIT BUFFER

ETMP1	EQU	30H		; EXTENDED 32 BIT BUFFER IN RAM PAGE 1
ETMP2	EQU	31H
ETMP3	EQU	32H 
ETMP4	EQU	33H 

; SECOND SET OF COUNTERS
CNT1_LW	EQU	34H
CNT1_HI	EQU	35H
CNT2_LW	EQU	36H
CNT2_HI	EQU	37H

; RECEIVED TRANSMISSION OPEN 32 BITS 

SER_0	EQU	CSR7		; 24/28 BIT SERIAL NUMBER
SER_1	EQU	CSR6
SER_2	EQU	CSR5
SER_3	EQU	CSR4

; RECEIVED TRANSMISSION ENCRYPTED 32 BITS 

FUNC	EQU	DAT1		; BUTTON CODE & USER BIT FUNCTION BYTE
CODE	EQU	DAT2		; DISCRIMINATION VALUE
CNTR_HI	EQU	DAT3		; 16 BIT RX COUNTER
CNTR_LW	EQU	DAT4

; ********* EEPROM MEMORY ALLOCATION *******
LRN_PTR	EQU	1H		; LEARN POINTER
SSTATUS	EQU	2H		; SYSTEM STATUS
BSTATUS EQU	3H		; BACKUP STATUS
TMPCNT	EQU	4H		; TEMPORARY COUNTER FOR RE-SYNC

X1	EQU	0C7H		; VALUES FOR STATE RECOVER
X2	EQU	08BH

; ********* PORTA BIT DEFINITIONS *******

DIO	EQU	0H		; 0/1 EEPROM DATA LINE
CLK	EQU	1H		; 0 EEPROM SERIAL CLOCK
CS	EQU	2H		; 0 EEPROM CHIP SELECT
RFIN	EQU	3H		; 1 RF INPUT

; ********* PORTB BIT DEFINITIONS *******

IMMO	EQU	0H		; 0 IMMOBILIZE OUTPUT
SIREN	EQU	1H		; 0 SIREN OUTPUT
PLIGHT  EQU	2H		; 0 PARKING LIGHT OUTPUT

LOCK	EQU	4H		; 0 LOCK OUTPUT
UNLOCK	EQU	5H		; 0 UNLOCK OUTPUT
TRUNK	EQU	6H		; 0 TRUNK OUTPUT
LED	EQU	7H		; 0 LED INDICATOR

; ********* PORTC BIT DEFINITIONS *******

IGN	EQU	0H		; 1 IGNITION INPUT
TRIG	EQU	1H		; 1 TRIG INPUT
DOOR	EQU	2H		; 1 DOORS INPUT
LEARN	EQU	3H		; 1 LEARN INPUT

; ********* COMPILER DEFINES ******************
NBITS   EQU     66      	; MAXIMUM TRANSMISSION BIT LENGTH
MIN     EQU     560            	; TRANSMISSION HEADER MINIMUM LENGTH [ÊS]
;MAX     EQU     10800 		; TRANSMISSION HEADER MAXIMUM LENGTH [ÊS]
TRISA	EQU	1001B		; PORTA: TRI-STATE VALUE
WRCFG	EQU	1000B		; PORTA: EEPROM WRITE TRI-STATE VALUE
RDCFG	EQU	1001B		; PORTA: EEPROM READ TRI-STATE VALUE
TRISB	EQU	00000000B	; PORTB: TRI-STATE VALUE
TRISC	EQU	11111111B	; PORTC: TRI-STATE VALUE
E_OK	EQU	000H		;  0  VALID RESPONSE

;****** STATE DEFINITIONS **************
ARMEDS	EQU	0A5H		
DRIVES	EQU	05AH
IMMOBS	EQU	03CH
LEARNS	EQU	0C3H
ALARMS	EQU	042H

;****** FLAGS DEFINITIONS **************
NORMAL	EQU	0H		; NORMAL PROGRAM FLOW
PASS1	EQU	1H		; LEARN FIRST PASS
PASS2	EQU	2H		; LEARN SECOND PASS
LFLASH	EQU	3H		; FLASH LED
PFLASH	EQU	4H		; FLASH PLIGHT
NTQ106	EQU	5H		; INDICATE NTQ106 TRANSMISSION RECEIVED
RESYNC	EQU	6H		; RESYNCH ACTIVE BIT
RPT     EQU     7H		; REPEATED CODE

;****** FLAGS1 DEFINITIONS **************
BITIN	EQU	0H		; RF DATA BIT
S_RSTR	EQU	1H		; FLAGS MUST BE RESTORED
ENTRY	EQU	2H		; ENTRY FLAG		
BAT_LOW	EQU	3H		; ENCODER BATTERY LOW INDICATOR


;****** STATUS REGISTER BIT DEFINITIONS *****************
CARRY   EQU       0		; CARRY
DC      EQU       1		; DIGIT CARRY
ZERO    EQU       2		; ZERO
PD      EQU       3		; POWER DOWN
TO      EQU       4		; TIMEOUT
PA0     EQU       5		; PAGE SELECT [0 OR 1]
PA1     EQU       6		; PAGE SELECT [0 OR 1]
OVF     EQU       7		; RTCC OVERFLOW

;**************************************************************************
; PAGE 0: 
;**************************************************************************
	ORG 00H

;**************************************************************************
;
; FUNCTION     : RESET ()	      			
;
; DESCRIPTION  : PROGRAM RESET ROUTINE
;
; PAGE		: 0
;
;**************************************************************************
RESET	
	MOVLW	00000111B		; SETUP RTCC PRESCALER
	OPTION				; 1 : 256

	BSF	STATUS,PA0		; SELECT PAGE #1
	GOTO 	RESET_P1	     	; GOTO MAIN PROGRAM LOOP

;**************************************************************************
; UPPER PAGE CALLS
;**************************************************************************

SENDC	GOTO	SENDC1			; UPPER PAGE CALL TO SENDC

TST_LEARN
	GOTO	TST_LEARN1		; CALL LEARN BUTTON TEST ROUTINE

TST_RTCC
	GOTO	TST_RTCC1

EE_WRITE0
	GOTO	EEWRITE			; CALL EEPROM WRITE ROUTINE

M_LOOP0
	BSF	STATUS,PA0
	GOTO	M_LOOP

;**************************************************************************
;
; FUNCTION     	: ROT_SHIFT()	      			
;
; DESCRIPTION  	: RIGHT ROTATE 66 BIT RECEIVE SHIFT REGISTER
;
; PAGE		: 0
;
;**************************************************************************
ROT_SHIFT
        RRF     CSR8,1			; [1] RIGHT ROTATE RECEIVE SHIFT REGISTER
        RRF     CSR7,1			; [1] RIGHT ROTATE RECEIVE SHIFT REGISTER
        RRF     CSR6,1                  ; [1] RIGHT ROTATE RECEIVE SHIFT REGISTER   
        RRF     CSR5,1                  ; [1] RIGHT ROTATE RECEIVE SHIFT REGISTER   
        RRF     CSR4,1                  ; [1] RIGHT ROTATE RECEIVE SHIFT REGISTER   
        RRF     CSR3,1                  ; [1] RIGHT ROTATE RECEIVE SHIFT REGISTER   
        RRF     CSR2,1                  ; [1] RIGHT ROTATE RECEIVE SHIFT REGISTER   
        RRF     CSR1,1                  ; [1] RIGHT ROTATE RECEIVE SHIFT REGISTER  
        RRF     CSR0,1                  ; [1] RIGHT ROTATE RECEIVE SHIFT REGISTER  
	RETLW	E_OK			; [2] 
;**************************************************************************
;
; FUNCTION     	: ROTR()	      			
;
; DESCRIPTION  	: ROTATE 16 BIT SHIFT REGISTER RIGHT
;
; PAGE		: 0
;
;**************************************************************************
ROTR
        RRF     TMP1,F
        RRF     TMP2,F
        BCF     TMP1,7
        BTFSC	STATUS,CARRY
        BSF     TMP1,7
        RETLW   0
;**************************************************************************
;
; FUNCTION     	: ROTL()	      			
;
; DESCRIPTION  	: ROTATE 16 BIT SHIFT REGISTER LEFT
;
; PAGE		: 0
;
;**************************************************************************
ROTL
        RLF     TMP2,F
        RLF     TMP1,F
        BCF     TMP2,0
        BTFSC	STATUS,CARRY
        BSF     TMP2,0
        RETLW   0

;**************************************************************************
;
; FUNCTION     	: EEREAD ()	      			
;
; DESCRIPTION  	: READ 16 BIT VALUE FROM EEPROM AND DECRYPT
;
; PAGE		: 0
;
;**************************************************************************
EEREAD
        MOVFW   ADDRESS
        MOVWF	OUTBYT
        BSF     OUTBYT,7                ; COMMAND = READ
        CALL    SENDC                   ; SEND COMMAND
        MOVLW   RDCFG
        TRIS    PORTA                   ; DIO = INPUT
	MOVLW   16D                	; 16 BITS TO READ
	MOVWF	CNT1

READ0   BSF     PORTA,CLK               ; CLOCK HIGH
        RLF     TMP2,F                  ; SHIFT LO BYTE
        BCF     TMP2,0                  ; ASSUME BIT WILL BE 0
        BTFSC   PORTA,DIO               ; READ DIO LINE
        BSF     TMP2,0                  ; COPY BIT TO REGISTER
        BCF     PORTA,CLK               ; CLOCK LOW
        RLF     TMP1,F                  ; SHIFT HI BYTE
        DECFSZ  CNT1,F			; LOOP COUNTER
	GOTO	READ0
        BCF     PORTA,CS                ; END READ CYCLE

; ******* DECRYPT 16-BIT WORD READ FROM EEPROM ***************

IFNC    
	MOVLW   16D
	MOVWF	CNT1

IFNC1   CALL    ROTL
	MOVLW	07H			; MASK ONLY LOWER 3 BITS
        ANDWF   TMP1,W
	MOVWF	OUTBYT			; TEMPORY STORE RESULT
	MOVLW	(EE_KEY-KEYBASE)	; GET BASE ADDRES OF EEPROM KEY
	ADDWF	OUTBYT,W		; ... AND ADD TO RESULT
	CALL    KEY_LOOKUP		; KEY BYTE FROM KEY LOOKUP TABLE
        XORWF   TMP2,F
	DECFSZ	CNT1,F	
        GOTO	IFNC1

	RETLW	0H

;**************************************************************************
; Memory Map ROM Keys
;**************************************************************************
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

EE_KEY	EQU	$			; EEPROM KEY BASE ADDRESS
	RETLW	088H			; EKEY_0 LSB
	RETLW	077H			; EKEY_1
	RETLW	066H			; EKEY_2
	RETLW	055H			; EKEY_3
	RETLW	044H			; EKEY_4
	RETLW	033H			; EKEY_5
	RETLW	022H			; EKEY_6
	RETLW	011H			; EKEY_7 MSB

;**************************************************************************
; FUNCTION      : RECEIVE
;
; DESCRIPTION   : RECEIVE ROUTINE FOR KEELOQ TRANSMISSIONS
;
; PAGE          : 0
;
;**************************************************************************
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
	BTFSS   PORTA,RFIN              ; [2] INPUT HIGH?
	GOTO    RCV2                    ; [0] NO, JUMP OUT OF LOOP
	DECFSZ  CNT0,1                  ; [1] YES, CONTINUE WITH TIMING LOOP
	GOTO    RCV1                    ; [2] 5 us X CNT0
	DECFSZ  CNT1,1                  ; [0] DO 1 ms LOOP CNT1 TIMES
	GOTO    RCV0			; [0]

RCV2
	CLRF    CNT0                    ; [1] CLEAR CALIB COUNTER LOW BYTE
	CLRF    CNT1                    ; [1] CLEAR CALIB COUNTER HIGH BYTE

;*************************************************************************
;  2.5 IS AVERAGE FOR DETECTING FALLING EDGE IN RCV1
;  2   INSTRUCTIONS FOR JUMP OUT RCV1 TO RCV2
;  2   INSTRUCTIONS FOR RCV2 - CLEAR CALIBRATION COUNTER
;  TOTAL 6.5 INSTRUCTIONS < 1 CALIBRATION LOOP SO DISCARD
;*************************************************************************

RCV3
	BTFSC   PORTA,RFIN              ; [2][2] INPUT HIGH?
	GOTO    RCV6                    ; [0][0] YES--END CALIBRATION
	INCF	CNT0,1			; [1] INCREMENT 16BIT COUNTER	
	SKPNZ	      			; [2]
	INCF	CNT1,1			; [0]
	CLRWDT				; [1] RESET WATCH DOG TIMER
	NOP				; [1]
	BTFSS	CNT1,3			; [1]
	GOTO	RCV3  			; [2]
	GOTO	RMT_0 			; [0]
		      			; TOTAL = 10
		      			
RCV6
	CLRC				; [1] DIVIDE CNT1:CNT0 BY 8 (600/8=75)
	RRF     CNT1,1			; [1]
	RRF     CNT0,1			; [1]
	RRF     CNT1,1			; [1]
	RRF     CNT0,1			; [1]
	RRF     CNT1,1			; [1]
	RRF     CNT0,1                  ; [1] 
					
	MOVLW   MIN/80			; [1]
	SUBWF   CNT0,W			; [1]
	BTFSS   STATUS,CARRY		; [2] NEGATIVE?
	GOTO    RMT_0                   ; [0] YES--HEADER SHORTER THAN MIN.
					; TOTAL = 11
; ************* VALID HEADER RECEIVED *********************
RCV7
	MOVLW   NBITS                   ; [1] VALID START MARKER WAS RECEIVED
	MOVWF   CNT1			; [1]
	MOVF    CNT0,W			; [1]
	MOVWF   CNT2                    ; [1] CNT2 = CNT0
	MOVLW   6H			; [1] SEE NOTE BELOW
	SUBWF   CNT2,1			; [1]
	GOTO    DL1                   	; [2] COMPENSATE FOR FIRST BIT
					; TOTAL = 8

;**********************************************************************************
;  2.5 IS AVERAGE PLAY BETWEEN RISING EDGE AND JUMP OUT OF CALIBRATION LOOP.
;  2   FOR JUMP OUT OF RCV3 TO RCV6
; 11   INSTRUCTIONS FOR RVC6 - CAIBRATION COUNTER DIVIDE
;  8   INSTRUCTIONS FOR RCV7 - COMPENSATE FOR POST CALIBRATION CALCUATIONS
; TOTAL 22.5 INSTRUCTIONS BETWEEN RISING EDGE AND ENTERING DL1
;  THEREFORE SUBTRACT 22.5/4 = 5.625 TO COMPENSATE FOR POST CALCULATION ON 1ST BIT
;**********************************************************************************

RCV8					
	MOVLW	4H			; [1] WAIT A MAXIMUM OF 4 Te
	MOVWF	TMP_CNT			; [1] SET TEMP LOOP COUNTER

RCV10A
	MOVFW	CNT0                  	; [1] and CSR processing
	MOVWF   CNT2			; [1] Refer to explanation above

RCV10B
	BTFSC   PORTA,RFIN              ; [2] Wait for rising edge
	GOTO    RCV11                   ; [0] Edge found--Process
	CLRWDT                          ; [1] Clear watchdog Timer
	BTFSC   PORTA,RFIN              ; [2] Wait for Next rising edge
	GOTO    RCV11                   ; [0] Edge found--Process
	DECFSZ  CNT2,1                  ; [1] Decrement Timeout counter
	GOTO    RCV10B                  ; [2] Loop Back
					; TOTAL = 8, RFIN CHECKED EVERY 4uS ON AVERAGE

	DECFSZ	TMP_CNT,1		; [1] ALL Te PERIODS
	GOTO	RCV10A			; [2] ... NO, THEN WAIT FOR NEXT ONE
	GOTO    RMT01                   ; [0] ... YES, [0] TIMEOUT--no edge found

RCV11
	MOVLW	3H			; [1]  SEE NOTE BELOW
	SUBWF	CNT0,W			; [1]
	MOVWF	CNT2			; [1]

;*************************************************************************
; 2   SETUP OF TEMP LOOP COUNTER  ( ONLY ONCE )
; 2   SETUP TE LOOP COUNTER       ( MAX 4 )
; 3   DECREMENT TEMP LOOP COUNTER ( MAX 4 )
; 4   IS THE AVERAGE PLAY BETWEEN EDGE AND EDJE BEING DETECTED IN RCV9
; 2   JUMP OUT OF RCV10B TO RCV11
; 3   FOR RCV11
; TOTAL 10 INSTRUCTIONS BETWEEN EDGE AND ENTERING DL1
; THEREFORE SUBTRACT 10/4 = 2.5 => 3 DL1 LOOPS TO COMPENSATE FOR 
;*************************************************************************

DL1
	CLRWDT                          ; [1] RESET WATCHDOG TIMER
	DECFSZ  CNT2,1                  ; [1] [2, IF SKIP]
	GOTO    DL1                     ; [2] CNT0 X 4 us

SAMPLE1
	BTFSS   PORTA,RFIN              ; [2] INPUT HIGH?  FIRST SAMPLE
	GOTO    RMT01                   ; [0] NO--ERROR

	MOVF    CNT0,W                  ; [1] CALIBRATION COUNTER
	MOVWF   CNT2                    ; [1] (NOMINALLY 75 FOR 300 us PULSE)
	DECF    CNT2,1			; [1] SUBTRACT 2 FROM FINAL CALIB COUNTER TO COMPENATE FOR THIS
	GOTO	$+1			; [2]
	NOP				; [1]
					; TOTAL = 8 => 1 LOOP COUNTER
DL2
	CLRWDT                          ; [1] RESET WATCHDOG TIMER
	GOTO	$+1			; [2] WAISTE TIME
	GOTO	$+1			; [2] WAISTE TIME
	DECFSZ  CNT2,1			; [1]
	GOTO    DL2                     ; [2] CNT0 X 8 us [ CNT0 x Te ]

SAMPLE2
	BCF     FLAGS1,BITIN             ; [1]   CLEAR BIT POSITION
	BTFSS   PORTA,RFIN              ; [1.5] LEAVE 0 IF LINE HIGH
	BSF     FLAGS1,BITIN             ; [0.5] MAKE 1 IF LINE LOW
					; SUB TOTAL = 3 CYCLES

	CALL    ROT_SHIFT               ; [11]+[2] CSR SHIFT + CALL
	BCF	CSR8,7			; [1]
	BTFSC   FLAGS1,BITIN		; [1.5]
	BSF     CSR8,7			; [0.5]
					; SUB TOTAL = 16 CYCLES


	MOVF    CNT0,W                  ; [1] CALIBRATION COUNTER
	MOVWF   CNT2                    ; [1] (NOMINALLY 75 FOR 300 us PULSE)
	MOVLW	3			; [1] SEE CALCULATION BELOW
	SUBWF	CNT2,1			; [1]
	NOP				; [1]
					; SUB TOTAL = 5 CYCLE
					; TOTAL = 24 => 24/8 = 3 LOOP COUNTERS
					 
;*************************************************************************
; TOTAL = 24 INSTRUCTIONS
; SUBTRACT 24/8 = 3 TO COMPESATE FOR UPDATEING CSR AND OTHER PROCESSING 
; AFTER DATA SAMPLE IS TAKEN.
;*************************************************************************

DL3
	GOTO	$+1			; [2] WAISTE TIME
	GOTO	$+1			; [2] WAISTE TIME
	CLRWDT                          ; [1] RESET WATCHDOG TIMER
	DECFSZ  CNT2,1                  ; [1]
	GOTO    DL3                     ; [2] CNT0 X 8 us [ CNT0 X Te ]

SAMPLE3
	BTFSC   PORTA,RFIN              ; [2] INPUT LOW?  THIRD SAMPLE
	GOTO    RMT0                    ; [0] NO--RECEIVE ERROR

	CALL    TST_RTCC                ; [11] CHECK RTCC

	DECFSZ  CNT1,1                  ; [1] LAST BIT?
	GOTO    RCV8                    ; [2] ... NO, GET NEXT BIT
					; TOTAL = 14 CYCLES

	GOTO    RMT21			; [2] ... YES, ALL BITS RECEIVED

RMT_0
	BSF     CNT1,4                  ; [1] HEADER ERROR--FORCE COUNTER > 11

RMT0					; [1] HERE IF NOT ALL BITS RECEIVED OK
	DECF	CNT1,1			; [1] COMPENSATE FOR ROTATE BEFORE DL3

; ***** JUMP TO HERE IF NOT ALL 66 BITS RECEIVED OK *****

RMT01					
	CALL    TST_RTCC                ; [11] CHECK RTCC

	MOVLW   11D                     ; TEST FOR NTQ106 TRANSMISSION
	SUBWF   CNT1,W                  ; IF CARRY FLAG SET (RX NOT OK)

	BTFSC   STATUS,CARRY		; CARRY SET IF FORMAT INVALID
	RETLW   0                       ; HERE IF NOT ALL BITS RECEIVED OK
	BSF     FLAGS,NTQ106            ; INDICATE NTQ106 TX RECEIVED

; ***** ROTATE FOR ANOTHER 6 TIME TO LINE-UP CSR *****

RMT21
	MOVLW	6H			; ADDITIONAL 6 BIT ROTATION REQUIRED
	ADDWF	CNT1,1			; ADD TO WHAT LEFT IN COUNTER

RMT22
	CLRC
	CALL    ROT_SHIFT               ; COMPLETE 64-BIT SHIFT
	DECFSZ  CNT1,1                  ; COMPLETE 64-BIT SHIFT
	GOTO    RMT22

	BTFSS	FLAGS,NTQ106		; TEST FOR NTQ106 TRANSMISSION
	GOTO	RMT1
	CLRF    SER_0                   ; ... YES, THEN CLEAR UPPER BYTE OF SN
	CLRF	CSR8

RMT1	
	BCF	FLAGS1,BAT_LOW		; CLEAR VLOW BIT
	BTFSC	CSR8,0			; TEST VLOW BIT IN TRANSMISSION
	BSF	FLAGS1,BAT_LOW		; INDICATE TX BATERY LOW BIT SET
RMT11
;	BSF	PORTA,LED		; VALID TRANSMISSION FORMAT, LED ON
	NOP
	  
RMT3
	MOVLW	0FH			; FORCE OPEN BUTTON CODES TO ZERO
	ANDWF	SER_0,1

RMT4	CLRC				; VALID SERIAL NUMBER => VALID TX
 	RETLW   E_OK                    ; RETURN WITH 1

;**************************************************************************
;
; FUNCTION     	: DECRYPT ()	      			
;
; DESCRIPTION  	: DECRYPTS 32 BIT [HOP1:HOP4] USING [CSR0:CSR7]
;
; PAGE		: 0 ( NOTE : MUST BE LOWER HALF OF PAGE )
;
;**************************************************************************
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
        BTFSC	STATUS,ZERO     ; LAST 48 LOOPS RESTORE THE KEY
        GOTO    ROTATE_KEY      ; LAST 48 LOOPS RESTORE THE KEY

        ; THE LOOKUP TABLE IS COMPRESSED INTO IN 4 BYTES TO SAVE SPACE
        ; USE THE 3 LOW INDEX BITS TO MAKE UP AN 8-BIT BIT MASK
        ; USE THE 2 HIGH INDEX BITS TO LOOK UP THE VALUE IN THE TABLE
        ; USE THE BIT MASK TO ISOLATE THE CORRECT BIT IN THE BYTE
        ; PART OF THE REASON FOR THIS SCHEME IS BECAUSE NORMAL TABLE LOOKUP
        ; REQUIRES AN ADDITIONAL STACK LEVEL

        CLRC                    ; CLEAR CARRY (FOR THE LEFT SHIFT)
       
        MOVLW   1               ; INITIALISE MASK = 1
        BTFSC   HOP3,3       	; SHIFT MASK 4X IF BIT 2 SET
        MOVLW   10000B          ; SHIFT MASK 4X IF BIT 2 SET
        MOVWF   MASK            ; INITIALISE MASK = 1

        BTFSS   HOP2,0       	; SHIFT MASK ANOTHER 2X IF BIT 1 SET
        GOTO    $+3
        RLF     MASK,F
        RLF     MASK,F            

        BTFSC   HOP1,0       	; SHIFT MASK ANOTHER 1X IF BIT 0 SET
        RLF     MASK,F

        ; MASK HAS NOW BEEN SHIFTED 0-7 TIMES ACCORDING TO BITS 2:1:0

        MOVLW   0               ; TABLE INDEX = 0
        BTFSC   HOP4,1
        IORLW   2               ; IF BIT 3 SET ADD 2 TO THE TABLE INDEX
        BTFSC   HOP4,6
        IORLW   4               ; IF BIT 4 SET ADD 4 TO THE TABLE INDEX

        ADDWF   PC,F            ; ADD THE INDEX TO THE PROGRAM COUNTER
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

        ANDWF   MASK,F          ; ISOLATE THE CORRECT BIT BY ANDING WITH MASK
        MOVLW   0               ; COPY THE BIT TO BIT 7
        BTFSS	STATUS,ZERO     ; COPY THE BIT TO BIT 7
        MOVLW   10000000B       ; COPY THE BIT TO BIT 7

        XORWF   HOP2,W    	; ONLY INTERESTED IN BIT HOP2,7
        XORWF   HOP4,W    	; ONLY INTERESTED IN BIT HOP4,7
        XORWF   KEY1,W		; ONLY INTERESTED IN BIT KEYREG1,7

        MOVWF   MASK            ; STORE W TEMPORARILY (WE NEED BIT 7)
        RLF     MASK,F          ; LEFT ROTATE MASK TO GET BIT 7 INTO THE CARRY

        RLF     HOP1,F         	; SHIFT IN THE NEW BIT
        RLF     HOP2,F
        RLF     HOP3,F
        RLF     HOP4,F

ROTATE_KEY

        CLRC			; CLEAR CARRY
        BTFSC   KEY7,7       	; SET CARRY IF LEFTMOST BIT SET
        SETC                    ; SET CARRY IF LEFTMOST BIT SET

        RLF     KEY0,F         	; LEFT-ROTATE THE 64-BIT KEY 
        RLF     KEY1,F
        RLF     KEY2,F
        RLF     KEY3,F
        RLF     KEY4,F
        RLF     KEY5,F
        RLF     KEY6,F
        RLF     KEY7,F         

        DECFSZ  CNT0,F        	; INNER LOOP 48 TIMES
        GOTO    DECRYPT_INNER   ; INNER LOOP 48 TIMES

	CALL	TST_RTCC
        DECFSZ  CNT1,F         	; OUTER LOOP 12 TIMES (11 + 1 TO RESTORE KEY)
        GOTO    DECRYPT_OUTER   ; OUTER LOOP 12 TIMES (11 + 1 TO RESTORE KEY)

        RETLW   0               ; RETURN 

;**************************************************************************
;
; FUNCTION     	: TST_RTCC ()	      			
;
; DESCRIPTION  	: TEST RTCC COUNTER AND UPDATE OUTPUT IF REQUIRED
;
; PAGE		: 0
;
;**************************************************************************

TST_RTCC1
	CLRWDT				; RESET WATCHDOG TIMER
	MOVFW	STATUS
	XORWF	RTCC,W
	ANDLW	080H

	BTFSS	STATUS,ZERO
	GOTO	TST_RTCC2		; TEST FOR 32MS TIMEOUT	ON RTCC MSB
	RETLW	0H			; ... DO QUICK RETURN TO RECEIVE ROUTINE

; **** INCREASE 16 BIT CLOCK TIMER *******
TST_RTCC2
	BCF	STATUS,OVF
	MOVFW	RTCC
	ANDLW	080H
	IORWF	STATUS,F

	INCF	CNT_LW,F		; INCREASE 16 COUNTER
	BTFSC	STATUS,ZERO		; INCREASE UPPER BYTE IF ZERO ( OVERFLOW )
	INCF	CNT_HI,F

	BSF	FSR,5			; SELECT RAM BANK 1
	INCF	CNT1_LW,F		; INCREASE REPEAT DEBOUNCE TIMER
	INCF	CNT2_LW,F		; INCREASE 2 SECOND PANIC TIMER
	BCF	FSR,5			; SELECT RAM BANK 0

	MOVLW	RDCFG			; UPDATE TRI-STATE REGISTER FOR PORTA
	TRIS 	PORTA
	MOVLW	TRISB			; UPDATE TRI-STATE REGISTER FOR PORTB
	TRIS 	PORTB
	MOVLW	TRISC			; UPDATE TRI-STATE REGISTER FOR PORTC
	TRIS 	PORTC

	
; *********** UPDATE LED IF REQUIRED ********
TST_LED 
        BTFSS   FLAGS,LFLASH
        GOTO    TST_PLIGHT

        BTFSS   CNT_LW,4		
        GOTO    TST_LED1

	BSF	PORTB,LED		; LED HIGH FOR 524MS			
	GOTO	TST_PLIGHT
TST_LED1
	BCF	PORTB,LED		; LED LOW FOR 524MS

; *********** UPDATE PLIGHT IF REQUIRED ********
TST_PLIGHT

        BTFSS   FLAGS,PFLASH
        GOTO    TST_30

        BTFSS   CNT_LW,4
        GOTO    TST_PLIGHT1

	BSF	PORTB,PLIGHT		; PLIGHT HIGH FOR 524MS
	GOTO	TST_30

TST_PLIGHT1
	BCF	PORTB,PLIGHT		; PLIGHT LOW FOR 524MS

 ; ********* TEST FOR 30 S LEARN TIMEOUT *************
TST_30	BTFSC   FLAGS,NORMAL		; TIMEOUT USE ONLY WITH LEARN
        GOTO    TST_RPT

        BTFSS   CNT_HI,2
        GOTO    TST_RPT			; TEST FOR LEARN TIMEOUT

	GOTO	WIPE_TX			; IF LEARN TIMEMOUT ABORT

 ; ********* TEST REPEAT TIMEOUT *************

TST_RPT 
	BSF	FSR,5			; SELECT RAM BANK 1

        BTFSS   CNT1_LW,4
        GOTO    TST_PANIC		; REPEAT TIMEMOUT OF 0.5 SEC

	BCF	FSR,5
	BCF	FLAGS,RPT

 ; ********* TEST PANIC TIMEOUT *************

TST_PANIC
	BCF	FSR,5

        BTFSS   FLAGS,RPT
        GOTO    TST_END

	BSF	FSR,5
	MOVLW	48D			; PANIC TIME OF 2 SEC
	SUBWF	CNT2_LW,W
       	BTFSS 	STATUS,CARRY
       	GOTO  	TST_END
	BCF	FSR,5			; SELECT RAM BANK 0
	BCF	FLAGS,RPT
	BSF	STATUS,PA1		; SELECT PAGE #2
	GOTO	ALARM

TST_END	
	BCF	FSR,5			; SELECT RAM BANK 0
	RETLW	0H

;**************************************************************************
;
; FUNCTION     	: TST_LEARN ()	      			
;

; DESCRIPTION  	: TEST AND HANDLE LEARN BUTTON
;
; PAGE		: 0
;
;**************************************************************************
TST_LEARN1
	CLRWDT				; RESET WATCHDOG TIMER
	BTFSS	PORTC,LEARN		; CHECK FOR LEARN BUTTON PRESSED
	RETLW	0			; ... IF NOT RETURN
        BTFSC   FLAGS,PASS2
        GOTO    TST_LEARN7    		; ALREADY IN LEARN
	
TST_LEARN2
	MOVLW	ALARMS			; CHECK IF IN ALARM STATE
	XORWF	RAMS,W
	BTFSC  	STATUS,ZERO		; ... NO,  CONTINUE
       	RETLW	0			; ... YES, RETURN

	CLRF	CNT_HI			; RESET EVENT COUNTER 
	CLRF	CNT_LW
	BCF	FLAGS,LFLASH		; CLEAR LED FLASH MODE

TST_LEARN3
	MOVLW	080H			; CHANGE LED STATE
	XORWF	PORTB,F			; USED TO FLASH LED AT 25KhZ
	CALL	TST_RTCC	   	; CALL RTCC UPDATE ROUTINE

        BTFSC   CNT_HI,0
        GOTO    TST_LEARN4		; TEST FOR ERASE TIMEMOUT ( 8.2 SEC )

        BTFSS   PORTC,LEARN
        GOTO    TST_LEARN5		; WAIT FOR LEARN BUTTON LIFT

	GOTO	TST_LEARN3		; ... IF NOT WAIT FOR LEARN KEY LIFT

TST_LEARN4
	BSF	STATUS,PA0		; SELECT PAGE #1
	GOTO	ERASE			; ERASE ALL LEARNED TRANSMITTERS

TST_LEARN5

        BTFSC   FLAGS,PASS1
        GOTO    TST_LEARN7		; ALREADY IN LEARN

	MOVLW	2
	SUBWF	CNT_LW,W

       	BTFSC 	STATUS,CARRY
       	GOTO  	TST_LEARN6		; TEST IF LEARN PRESS LONGER THAN 64 MS

	MOVLW	ARMEDS			; CHECK IF IN ARMED STATE
	XORWF	RAMS,W
	BTFSC  	STATUS,ZERO		; ... NO,  CONTINUE
	BSF	FLAGS,LFLASH		; RESET FLASH FLAG

  	BCF	PORTB,LED
	RETLW	0			; ... IF NOT ABORT LEARN

TST_LEARN6
	BSF	FLAGS,PASS1		; INDICATE FIRST STATE OF LEARN
	BCF	FLAGS,NORMAL		; INDICATE FIRST STATE OF LEARN
	BCF	FLAGS,PASS2
	BCF	FLAGS1,S_RSTR		; FLAGS MUST NOT BE RESTORED

TST_LEARN7
	BSF	PORTB,LED		; LED ON TO INDICATE LEARN ACTIVATED
	RETLW	0H

;**************************************************************************
;
; FUNCTION     	: SENDC ()	      			
;

; DESCRIPTION  	: SEND EEPROM COMMAND 
;
; PAGE		: 0
;
;**************************************************************************
SENDC1
	CLRWDT				; RESET WATCHDOG TIMER

        BCF     PORTA,CS                ; RESET CS STATE
        BCF     PORTA,CLK               ; RESET CLK STATE
        BCF     PORTA,DIO               ; RESET DIO STATE

        MOVLW   WRCFG
        TRIS    PORTA                   ; DIO = OUTPUT
        GOTO    $+1                     ; WAIT FOR OUTPUTS TO SETTLE
        BSF     PORTA,CS                ; SELECT EEPROM
        SETC                            ; START BIT = 1
        MOVLW   9D                 	; START BIT + 8 DATA BITS
	MOVWF	CNT1

SENDC2
        BTFSS	STATUS,CARRY            ; TEST BIT
        BCF     PORTA,DIO               ; WRITE TO DIO
        BTFSC	STATUS,CARRY            ; TEST BIT
        BSF     PORTA,DIO               ; WRITE TO DIO
        GOTO    $+1                     ; WAIT 2 US
        RLF     OUTBYT,F                ; GET NEXT BIT INTO CARRY
        BSF     PORTA,CLK               ; CLOCK HIGH
        GOTO    $+1                     ; WAIT 2 US
        GOTO    $+1                     ; WAIT 2 US
        BCF     PORTA,CLK               ; CLOCK LOW
	DECFSZ	CNT1,F			; LOOP COUNTER
        GOTO	SENDC2
        BCF     PORTA,DIO               ; AVOID CONTENTION WITH READ
        RETLW   0

;**************************************************************************
;
; FUNCTION     	: EEWRITE ()	      			
;

; DESCRIPTION  	: ENCRYPT AND WRITE 16 BIT VALUE TO EEPROM 
;
; PAGE		: 0
;
;**************************************************************************
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
        XORWF   TMP2,F			 
        CALL    ROTR                    ; ROTATE RIGHT 16 BIT WORD
	DECFSZ	CNT1,F
	GOTO	FNC2

; ******* EEPROM WRITE ENABLE ******************
WRITE0  
	MOVLW	30H			; WRITE ENABLE COMMAND
	MOVWF   OUTBYT               	
        CALL    SENDC			; SEND COMMAND TO EEPROM
        BCF     PORTA,CS                ; END COMMAND, DESELECT

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
        BCF     PORTA,DIO		; CLEAR DATA BIT
        BTFSC   TMP1,7			; ... ELSE 
        BSF     PORTA,DIO               ; SET DATA BIT
        GOTO    $+1                     ; WAIT 2 US
        RLF     TMP2,F                  ; SHIFT LO BYTE
        BSF     PORTA,CLK               ; CLOCK HIGH
        GOTO    $+1                     ; WAIT 2 US
        RLF     TMP1,F                  ; SHIFT HI BYTE
        BCF     PORTA,CLK               ; CLOCK LOW
	DECFSZ	CNT1,F
        GOTO	WRITE2             	; LOOP COUNTER
        BCF     PORTA,CS                ; END OF WRITE COMMAND, DESELECT

        MOVLW   RDCFG
        TRIS    PORTA                   ; DIO = INPUT
        BSF     PORTA,CS                ; CS HIGH TO WAIT FOR ACK
	CLRF	RTCC

WRITE5  
        BTFSC   RTCC,7			; CHECK FOR TIMOUT
	GOTO	RESET			; START OVER
	CLRWDT				; RESET WATCHDOG TIMER
        BTFSS   PORTA,DIO		; CHECK FOR ACK RISING EDGE
        GOTO    WRITE5			; LOOP BACK

WRITE6  BCF     PORTA,CS                ; END OF ACK

; ******* EEPROM WRITE DISABLE ****************
        MOVLW   000H             	; WRITE DISABLE COMMAND
	MOVWF	OUTBYT
        CALL    SENDC
        BCF     PORTA,CS                ; END OF DISABLE COMMAND, DESELECT

	INCF	ADDRESS,F		; POINT TO NEXT EEPROM ADDRESS ( BY DEFAULT )
	RETLW	0H

;**************************************************************************
;
; FUNCTION     	: LEARN_OK ()
;
; DESCRIPTION  	: LED ON FOR 1 SEK [ INDICATE LEARN SUCCESSFUL ]
;
; PAGE		: 0
;
;**************************************************************************

LEARN_OK
	CLRF	CNT_LW			; CLEAR COUNTER
  	BSF	PORTB,LED 		; LED ON FOR 1 SEC

LEARN_OK2
	CALL	TST_RTCC		; UPDATE COUNTER
        BTFSS   CNT_LW,5		; TEST FOR 1 SEC TIMEOUT
        GOTO    LEARN_OK2		; LOOP BACK
  	BCF	PORTB,LED		; LED OFF
	CLRF	CNT_LW
LEARN_OK3
	CALL	TST_RTCC		; UPDATE COUNTER		
	BTFSS	CNT_LW,4		; TEST FOR 0.5S TIMEOUT
	GOTO	LEARN_OK3		; LOOP BACK

LEARN_END
	BSF	FLAGS,NORMAL		; SELECT NORMAL MODE	
	BCF	FLAGS,PASS1		; CLEAR LEARN MODE
	BCF	FLAGS,PASS2		; CLEAR LEARN MODE

	BSF	FLAGS1,S_RSTR		; RESTORE FLAGS
	 
	BSF	STATUS,PA0		; CONTINUE ON PAGE 1
	GOTO	M_LOOP			; RETURN TO MAIN LOOP

;**************************************************************************
;
; FUNCTION     	: WIPE_TX ()  
;
; DESCRIPTION  	: WIPE CURRENT TX SERIAL NUMBER IN EEPROM
;
; PAGE		: 0
;
;**************************************************************************
WIPE_TX	
	MOVLW	LRN_PTR			; POINT LEARN POINTER
	MOVWF	ADDRESS
	CALL	EEREAD			; READ LEARN POINTER WORD
 
        BTFSS   TMP1,0			; BUSY LEARNING?
        GOTO    LEARN_NOK    		; .. NO, BYPASS TX WIPE

	SWAPF	TMP2,W			; RECOVER PREVIOUS TX NUMBER
	ANDLW	07H			; MASK ONLY LOWER 3 BITS

	CLRF	TMP1			; RESET SELFLEARN POINTER 
	MOVWF	TXNUM			; ... TO CURRENT TXNUM
	MOVWF	TMP2

	MOVLW	LRN_PTR			; WRITE LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_WRITE0		; UPDATE EEPROM

WIPE_TX1
	BSF	STATUS,PA0		; CALL TO PAGE 1
	CALL	TX_LOOKUP		; TO GET BASE ADDRESS OF TX
	BCF	STATUS,PA0		; RETURN TO PAGE 0
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS
	CLRF	TMP1			; SET VALUE TO ZERO
	CLRF	TMP2
	CALL	EE_WRITE0		; CLEAR LOWER 16 BITS
	CLRF	TMP1			; SET VALUE TO ZERO
	CLRF	TMP2
	CALL	EE_WRITE0		; CLEAR UPPER 16 BITS

;**************************************************************************
;
; FUNCTION     	: LEARN_NOK ()
;
; DESCRIPTION  	: LED ON FOR 0.1 SEC [ INDICATE LEARN SUCCESSFUL ]
;
; PAGE		: 0
;
;**************************************************************************

LEARN_NOK
	BSF	FLAGS1,S_RSTR		; RESTORE FLAGS
	BCF	FLAGS,PASS1
	BCF	FLAGS,PASS2
	BSF	FLAGS,NORMAL		; SELECT NORMAL MODE
	BCF	FLAGS,RESYNC		; RESET RESYNC FLAG

	CLRF	CNT_LW			; CLEAR COUNTER
  	BSF	PORTB,LED 		; LED ON FOR 0.1 SEC

LEARN_NOK2
	CALL	TST_RTCC		; UPDATE COUNTER
	
        BTFSS   CNT_LW,2		; CHECK FOR 100MS TIMEOUT
        GOTO    LEARN_NOK2
  	BCF	PORTB,LED		; LED OFF

	CLRF	CNT_LW
LEARN_NOK3
	CALL	TST_RTCC		; UPDATE COUNTER		
	BTFSS	CNT_LW,4		; TEST FOR 0.5S TIMEOUT
	GOTO	LEARN_NOK3		; LOOP BACK

	BTFSS	FLAGS1,ENTRY		
	GOTO	M_LOOP0			; RETURN TO MAIN LOOP
	BSF	STATUS,PA0		; GOTO PAGE 1
	GOTO	MAIN			; RETURN TO STATUS READ

;**************************************************************************
; PAGE 1:
;**************************************************************************
	ORG	200H

;**************************************************************************
; CALLS TO FIRST PAGE
;**************************************************************************

RESET1	BCF	STATUS,PA0		; SELECT PAGE #0
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

;**************************************************************************
;
; FUNCTION     	: TX_LOOKUP ()	      			
;
; DESCRIPTION  	: TRANSMITTER MEMORY LOOKUP TABLE
;
; PAGE		: 1	( NOTE : MUST BE LOWER HALF OF PAGE )
;
;**************************************************************************
TX_LOOKUP
	CALL	TX_LOOKUP2		; GET VALUE FROM LOOKUP TABLE BELOW
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

;**************************************************************************
;
; FUNCTION     	: BUT_LOOKUP ()	      			
;
; DESCRIPTION  	: TRANSMITTER BUTTON LOOKUP TABLE
;
; PAGE		: 1	( NOTE : MUST BE LOWER HALF OF PAGE )
;
;**************************************************************************
BUT_LOOKUP
	MOVFW	TXNUM			; GET CURRENT TRANSMITTER
	ADDWF	PC,1
	RETLW	0AH			; TX0 BUTTON CODE ADDRESS
	RETLW	0BH			; TX1 BUTTON CODE ADDRESS
	RETLW	0CH			; TX2 BUTTON CODE ADDRESS
	RETLW	0DH			; TX3 BUTTON CODE ADDRESS
	RETLW	0EH			; TX4 BUTTON CODE ADDRESS
	RETLW	0FH			; TX5 BUTTON CODE ADDRESS

;**************************************************************************
;
; FUNCTION     	: KEYGEN ()	      			
;
; DESCRIPTION  	: GENERATE A KEY USING MASTER KEY ( ADDR 40H IN ROM )
;
; PAGE		: 1
;
;**************************************************************************
KEYGEN
	MOVLW	KEY7			; POINT TO FIRST KEY BYTE
	MOVWF	FSR

	MOVLW	(MAS_KEY-KEYBASE+7)	; GET TABLE MSB OFFSET FOR MASTER KEY
	MOVWF	CNT1

	MOVLW	8H			; INDICATE 8 BYTE TO READ FROM LOOKUP TABLE
	MOVWF	CNT0			; BYTE COUNTER

KEYGEN2
	BCF	STATUS,PA0		; SELECT PAGE #0
	MOVFW	CNT1
	CALL	KEY_LOOKUP		; GET BYTE FROM LOOKUP TABLE
	MOVWF	IND			; STORE BYTE IN KEY BYTE
	DECF	FSR,F			; POINT TO NEXT ENTRY IN CIRCULAR BUFFER
	DECF	CNT1,F			; POINT TO NEXT ENTRY IN KEY LOOKUP TABLE
	BSF	STATUS,PA0		; RE-SELECT PAGE #1
	DECFSZ	CNT0,F			; ALL BYTES READ
	GOTO	KEYGEN2			; ... NO THEN READ NEXT BYTE
	MOVFW	KEY0			; SWAP KEY1 AND KEY0 
	MOVWF	OUTBYT			; NOTE : THIS MUST BE DONE BECAUSE THE TMP1 & TMP2
	MOVFW	KEY1			;        ( KEY0 & KEY1 ) REGISTERS IS ALSO USED 
	MOVWF	KEY0			; 	 DURING DECRYPTION ( KEYGEN )
	MOVFW	OUTBYT
	MOVWF	KEY1

	BCF	STATUS,PA0		; SELECT PAGE #0
	CALL	DECRYPT 		; DECRYPT 32 BIT USING MASTER KEY
	BSF	STATUS,PA0		; RE-SELECT PAGE #1
	
	MOVFW	HOP2			; GET LOWER 16 BIT OF DECRYPTED WORD
	MOVWF	TMP1			
	MOVFW	HOP1
	MOVWF	TMP2
	CALL	EE_WRITE1		; ... AND WRITE TO EEPROM 
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

	MOVFW	HOP4			; GET UPPER 16 BIT OF DECRYPTED WORD
	MOVWF	TMP1
	MOVFW	HOP3
	MOVWF	TMP2
	CALL	EE_WRITE1		; ... AND WRITE TO EEPROM
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

	BTFSC	ADDRESS,1		; TEST IF FIRST 32 BIT OF KEY GENERATED
	GOTO	S_SEED2			; ... IF SO GENERATE SECOND 32 BITS
	GOTO	CALC_END		; ... ELSE KEYGEN COMPLETE

;**************************************************************************
;
; FUNCTION     	: CALC_KEY ()	      			
;
; DESCRIPTION  	: CALCULATE NEW KEY FROM RECEIVED SERIAL NUMBER
;
; PAGE		: 1
;
;**************************************************************************
CALC_KEY
	BSF	FSR,5
	MOVFW	HOP1			; STORE 32 BIT HOPCODE IN THE EXTENDED TEMP BUFFER
	MOVWF	ETMP1			
	MOVFW	HOP2
	MOVWF	ETMP2
	MOVFW	HOP3
	MOVWF	ETMP3
	MOVFW	HOP4
	MOVWF	ETMP4
	BCF	FSR,5

	CALL	TX_LOOKUP		; GET TRANSMITTER BASE ADDRESS
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS

	MOVFW	SER_2			; GET LOWER 16 BIT OF SERIAL NUMBER
	MOVWF	TMP1
	MOVFW	SER_3
	MOVWF	TMP2
	CALL	EE_WRITE1		; ... AND WRITE TO EEPROM
	BSF	STATUS,PA0		; RE-SELECT PAGE #1
	
	MOVFW	SER_0			; GET UPPER 16 BIT OF SERIAL NUMBER
	MOVWF	TMP1
	MOVFW	SER_1
	MOVWF	TMP2
	CALL	EE_WRITE1		; ... AND WRITE TO EEPROM
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

S_SEED1	
	MOVLW	20H			; PATCH IF TRANSMITTER IS A HCS360 / HCS300
	BTFSC	FLAGS,NTQ106		
	MOVLW	2BH			; PATCH IF TRANSMITTER IS A NTQ106 / NTQ105
	IORWF	SER_0,W
	MOVWF	DAT1

	MOVFW	SER_1			; GET SERIAL NUMBER FROM RECEIVER BUFFER
	MOVWF	DAT2
	MOVFW	SER_2
	MOVWF	DAT3
	MOVFW	SER_3
	MOVWF	DAT4
	GOTO	KEYGEN			; GENERATE FIRST 32 KEY BITS

S_SEED2	
	CALL	TX_LOOKUP		; GET TRANSMITTER BASE ADDRESS
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS
	CALL	EE_READ1		; READ LOWER 16 BITS OF SERIAL NUMBER FROM EEPROM
	BSF	STATUS,PA0		; SELECT PAGE #1
	MOVFW	TMP1
	MOVWF	DAT3
	MOVFW	TMP2
	MOVWF	DAT4

	INCF	ADDRESS,F			
	CALL	EE_READ1		; READ UPPER 16 BITS OF SERIAL NUMBER FROM EEPROM
	BSF	STATUS,PA0		; SELECT PAGE #1
	MOVLW	60H			; PATCH IF TRANSMITTER IS A HCS360 / HCS300
	BTFSC	FLAGS,NTQ106		
	MOVLW	65H			; PATCH IF TRANSMITTER IS A NTQ106 / NTQ105
	IORWF	TMP1,W
	MOVWF	DAT1
	MOVFW	TMP2			
	MOVWF	DAT2

	INCF	ADDRESS,F		; POINT TO UPPER 32 BITS OF KEY
	INCF	ADDRESS,F
	INCF	ADDRESS,F
	GOTO	KEYGEN			; GENERATE SECOND 32 KEY BITS

CALC_END
	BSF	FSR,5
	MOVFW	ETMP1			; RECOVER 32 BIT HOPCODE FROM EXTENDED BUFFER
	MOVWF	HOP1
	MOVFW	ETMP2
	MOVWF	HOP2
	MOVFW	ETMP3
	MOVWF	HOP3
	MOVFW	ETMP4
	MOVWF	HOP4
	BCF	FSR,5

	CLRF	CNT_HI			; RESET EVENT CLOCK
	CLRF	CNT_LW
	GOTO	M_HOP

;**************************************************************************
;
; FUNCTION     	: ERASE ()
;
; DESCRIPTION  	: ERASE ALL TRANSMITTERS
;
; PAGE		: 1
;
;**************************************************************************
ERASE         
	BSF	FLAGS1,S_RSTR		; FLAGS MUST BE RESTORED
	BSF	PORTB,LED		; SET LED ON
	
	MOVLW	1H			; POINT TO LEARN POINTER ADDRESS
	MOVWF	ADDRESS
	CALL	EE_CLEAR1		; 
	BSF	STATUS,PA0		; SELECT PAGE 1

	CLRF	TXNUM			; POINT TO FIRST TRANSMITTER POSISTION IN EEPROM
ERASE2
	CALL	TX_LOOKUP		; GET TX BASE ADRESS
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS

	CALL    EE_CLEAR1	        ; CLEAR LOWER 16 BITS OF SERIAL NUMBER
	BSF	STATUS,PA0		; SELECT PAGE 1
	CALL    EE_CLEAR1 	        ; CLEAR UPPER 16 BITS OF SERIAL NUMBER
	BSF	STATUS,PA0		; SELECT PAGE 1

	INCF	TXNUM,F			; POINT TO NEXT EEPROM INDEX
	MOVLW	6H			; TEST FOR LAST POSITION
	SUBWF	TXNUM,W
	BTFSS	STATUS,CARRY  		; IF NOT UPDATE NEXT ENTRY
	GOTO	ERASE2
  	BCF	PORTB,LED		; LED OFF TO INDICATE ERASE ALL COMPLETE

M_ERASE3
	CLRWDT				; RESET WATCHDOG TIMER
	BTFSC	PORTC,LEARN		; WAIT FOR BUTTON LIFT
	GOTO	M_ERASE3	 
	GOTO	M_LOOP			; RETURN TO MAIN PROGRAM FLOW

;**************************************************************************
;
; FUNCTION     	: READ_KEY ()	      			
;
; DESCRIPTION  	: READ 64 BIT KEY FROM EEPROM [CSR0:CSR7] 
;
; PAGE		: 1
;
;**************************************************************************
READ_KEY
	MOVLW	3H			; POINT TO MSB OF KEY
	ADDWF	ADDRESS,1	

	MOVLW	KEY7			; POINT TO LSB OF 64 BIT SHIFT REGISTER
	MOVWF	FSR	
	MOVLW	3H			; READ 3 x 16BIT VALUES FROM EEPROM
	MOVWF	CNT2

READ_KEY2
	CALL	EE_READ1		; READ LOWER 16 BITS
	BSF	STATUS,PA0		; SELECT PAGE #1
	MOVFW	TMP1			; GET UPPER 8 BITS
	MOVWF	IND			; STORE FIRST 8 BITS IN 64 BIT SHIFT REGISTER
	DECF	FSR,F			; POINT TO NEXT BYTE IN SHIFT REGISTER
	MOVFW	TMP2			; GET LOWER 8 BITS
	MOVWF	IND			; STORE SECOND 8 BITS IN 64 BIT SHIFT REGISTER
	DECF	FSR,F			; POINT TO NEXT BYTE IN SHIFT REGISTER
	DECF	ADDRESS			; POINT TO NEXT EEPROM ADDRESS
	DECFSZ	CNT2,F			; ALL THREE 16-BIT WORDS READ
	GOTO	READ_KEY2		; ... IF NOT GET NEXT 

	CALL	EE_READ1		; READ LOWER 16 BITS
	BSF	STATUS,PA0		; SELECT PAGE #1
	GOTO	M_DEC			; RETURN TO MAIN PROGRAM LOOP

;**************************************************************************
;
; FUNCTION     	: MAIN ()	      			
;
; DESCRIPTION  	: MAIN PROGRAM ROUTINE
;
; PAGE		: 1
;
;**************************************************************************

RESET_P1
	CLRF	FSR			; POINT TO RAM PAGE 0		

	CLRF	PORTA			; RESET PORTA
	CLRF	PORTB			; RESET PORTB
	CLRF	PORTC			; RESET PORTC

	MOVLW	TRISA			; UPDATE TRI-STATE REGISTER FOR PORTA
	TRIS	PORTA
	MOVLW	TRISB			; UPDATE TRI-STATE REGISTER FOR PORTB
	TRIS 	PORTB
	MOVLW	TRISC			; UPDATE TRI-STATE REGISTER FOR PORTC
	TRIS 	PORTC

	CLRF	FLAGS			; RESET FLAGS
	CLRF	FLAGS1			; RESET FLAGS

	BSF	FLAGS1,ENTRY		; SET ENTRY FLAG

MAIN
	BSF	FLAGS,NORMAL		; INDICATE NORMAL PROGRAM FLOW
	BCF	FLAGS,PASS1
	BCF	FLAGS,PASS2

	MOVLW	LRN_PTR			; POINT LEARN POINTER
	MOVWF	ADDRESS		     
	CALL	EE_READ1		; READ LEARN POINTER WORD
	BSF	STATUS,PA0		; SELECT PAGE #1

        BTFSS   TMP1,0
        GOTO    MAIN2			; UPPER BIT OF SELFLEARN NIBBLE MUST BE ZERO

	SWAPF	TMP2,W			; RECOVER PREVIOUS TX NUMBER
	ANDLW	07H			; MASK ONLY LOWER 3 BITS

	CLRF	TMP1			; RESET SELFLEARN POINTER 
	MOVWF	TXNUM			; ... TO CURRENT TXNUM
	MOVWF	TMP2

	MOVLW	LRN_PTR			; WRITE LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_WRITE1		; UPDATE EEPROM
	BCF	STATUS,PA0
	GOTO	WIPE_TX1 		; WIPE TRANSMITTER ( SELFLEARN UNSUCCESFUL )

MAIN2

	BCF	FLAGS1,ENTRY		; CLEAR ENTRY FLAG	
	

MAIN3	
	MOVLW	SSTATUS			; POINT STATUS
	MOVWF	ADDRESS
	CALL	EE_READ1		; READ STATUS
	BSF	STATUS,PA0		; SELECT PAGE #1

	MOVLW	X2			; CHECK FOR VALID STATUS WRITE
	XORWF	TMP2,W
	BTFSC	STATUS,ZERO
	GOTO	MAIN4			; VALID STATUS  

	; HERE IF STATUS NOT VALID

	MOVLW	BSTATUS			; POINT TO BACKUP COPY
	MOVWF	ADDRESS
	CALL	EE_READ1
	BSF	STATUS,PA0		; READ BACKUP STATUS COPY

	MOVLW	X1
	XORWF	TMP2,W			; CHECK FOR VALID WRITE
	BTFSC	STATUS,ZERO
	GOTO	MAIN4			; VALID BACKUP STATUS

	; HERE IF BACKUP ALSO CORRUPTED

	BCF	STATUS,PA0		; GOTO ARMED STATE
	BSF	STATUS,PA1
	GOTO	ARMED			; 

MAIN4
	MOVLW	DRIVES
	XORWF	TMP1,W
       	BTFSS  	STATUS,ZERO
       	GOTO  	MAIN5
	BCF	STATUS,PA0
	BSF	STATUS,PA1
	GOTO	DRIVE

MAIN5
	MOVLW	ALARMS
	XORWF	TMP1,W
	BTFSS  	STATUS,ZERO
       	GOTO  	MAIN6
	BCF	STATUS,PA0
	BSF	STATUS,PA1
	GOTO	ALARM

MAIN6
	MOVLW	IMMOBS
	XORWF	TMP1,W
	BTFSS  	STATUS,ZERO
       	GOTO  	MAIN7
	BCF	STATUS,PA0
	BSF	STATUS,PA1
	GOTO	IMMOB

MAIN7
	BCF	STATUS,PA0
	BSF	STATUS,PA1
	GOTO	ARMED
	
M_CHECK	
	BCF	STATUS,PA0		; CLEAR PAGE BIT #0
	CALL	TST_LEARN		; TEST & HANDLE LEARN BUTTON
	CALL	RECEIVE			; RECEIVE TRANSMISSION 
	BSF	STATUS,PA0		; SET PAGE BIT #0

       	BTFSS 	STATUS,CARRY
       	GOTO  	M_ZERO
M_LOOP
	BCF	STATUS,PA0
	BSF	STATUS,PA1	
	MOVLW	2
	ADDWF  	STACK,W
	BSF	STATUS,CARRY
       	MOVWF	PC

M_ZERO	
  	MOVLW	0FH			; MAXIMUM SERIAL NUMBER IS 28 BITS
	ANDWF	SER_0,1

	MOVFW	SER_0			; CHECK SERIAL NUMBER NOT EQUAL TO ZERO
	IORWF	SER_1,W
	IORWF	SER_2,W
	IORWF	SER_3,W
	BTFSC	STATUS,ZERO
	GOTO	M_LOOP			; ... IF ZERO WAIT FOR NEXT TRANSMISSION

        BTFSS   FLAGS,PASS2		; IF ON SECOND LEARNING PASS TXNUM IS LEARNING POSITION
	CLRF	TXNUM			; ... ELSE POINT TO FIRST TRANSMITTER

; ******* COMPARE LOWER WORD OF SERIAL NUMBER ********
M_SERIAL
	CALL	TX_LOOKUP		; GET TX BASE ADDRESS
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS
	CALL	EE_READ1		; READ LOWER 16-BITS OF SERIAL NUMBER FROM EEPROM
	BSF	STATUS,PA0		; SELECT PAGE #1
  
	MOVFW	TMP1			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_2,W
	BTFSS	STATUS,ZERO  		; ... IF NOT EQUAL DO ERROR
	GOTO	M_SER_ERR
	MOVFW	TMP2			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_3,W
	BTFSS	STATUS,ZERO 		; ... IF NOT EQUAL DO ERROR
	GOTO	M_SER_ERR
	
; ******* COMPARE UPPER WORD OF SERIAL NUMBER ********
M_SERIAL2
	INCF	ADDRESS,F		; POINT TO NEXT ENTRY 
	CALL	EE_READ1		; READ UPPER 16-BITS OF SERIAL NUMBER FROM EEPROM
	BSF	STATUS,PA0		; SELECT PAGE #1

	MOVFW	TMP1			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_0,W
	BTFSS	STATUS,ZERO 		; ... IF NOT EQUAL DO ERROR
	GOTO	M_SER_ERR

	MOVFW	TMP2			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_1,W
	BTFSS	STATUS,ZERO 		; ... IF NOT EQUAL DO ERROR
	GOTO	M_SER_ERR
	
; ************* TEST IF LEARN ACTIVE ****************
M_PASS	
        BTFSC   FLAGS,PASS1
        GOTO    CALC_KEY		; TEST IF ON FIRST PASS OF LEARN
	GOTO	M_HOP			; TEST FOR NORMAL PROGRAM FLOW

; ******** SERIAL NUMBER COMPARE ERROR FOUND ***********
M_SER_ERR

; **** SEARCH NEXT POSITION FOR SERIAL NUMBER *****
M_NEXT	INCF	TXNUM,F			; POINT TO NEXT TRANSMITTER POSITION
	MOVLW	6H			; TEST FOR LAST POSITION
	SUBWF	TXNUM,W
	BTFSS	STATUS,CARRY	   	; ... IF NOT GET NEXT ENTRY
	GOTO	M_SERIAL

; **** SERIAL NUMBER NOT FOUND ( ONLY IN NORMAL / PASS1 ) **********

        BTFSC   FLAGS,PASS1
        GOTO    M_NF			; TEST IF ON FIRST PASS OF SELFLEARN
        BTFSS   FLAGS,PASS2
        GOTO    M_LOOP			; CHECK IF IN SECOND STATE OF LEARN
	GOTO	MAIN

; *** IF SERIAL NOT IN MAP READ SELFLEARN POINTER ***
M_NF	MOVLW	LRN_PTR			; POINT TO LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_READ1		; READ LEARN POINTER FROM EEPROM
	BSF	STATUS,PA0		; SELECT PAGE #1

	MOVLW	07H			; MASK TXNUM FROM POINTER
	ANDWF	TMP2,W
	MOVWF	TXNUM

	BTFSS	TXNUM,2			; TXNUM < 4 IS VALID
	GOTO	CALC_KEY		; ... YES, GENERATE DECRYPTION KEY

	BTFSC	TXNUM,1			; TXNUM > 5 IS INVALID
	CLRF	TXNUM			; ... LEARN POSITION SET TO ZERO
  	GOTO	CALC_KEY		; LEARN CURRENT RECEIVED TRANSMITTER

; ********** DECRYPT HOPCODE *********************
M_HOP	
	CALL	TX_LOOKUP		; LOOK UP TRANSMITTER BASE ADDRESS
	BSF	ADDRESS,2		; ADD 4 TO BASE ADDRESS

	GOTO	READ_KEY		; READ 64 BIT DECODER KEY ( CALL "READ_KEY")
M_DEC	
	BCF	STATUS,PA0		; SELECT PAGE #0
	CALL	DECRYPT			; DECRYPT HOPCODE 
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

        BTFSS   FLAGS,PASS1
        GOTO    M_DIS			; TEST IF ON FIRST PASS OF SELFLEARN

; ********* UPDATE BUTTON CODE AND DISCR VALUE AFTER SELFLEARN **********
M_SL_UPDATE
	MOVLW	LRN_PTR			; POINT LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_READ1		; READ LEARN POINTER FROM EEPROM
	BSF	STATUS,PA0		; SELECT PAGE #1

	MOVLW	1H			; INDICATE LEARN ACTIVE IN EEPROM
	MOVWF	TMP1			

	MOVLW	0FH			; MASK LEARN POINTER
	ANDWF	TMP2,1
	MOVLW	6H			; TEST FOR INVALID LEARN POINTER
	SUBWF	TMP2,W			; TEST FOR INVALID LEARN POINTER
	BTFSC	STATUS,CARRY  		; TEST FOR INVALID LEARN POINTER
	CLRF	TMP2			; ... IF INVALID POINT TO FIRST POSITION

	SWAPF	TXNUM,W			; COPY TXNUM INTO UPPER NIBBLE
	IORWF	TMP2,1

	CALL	EE_WRITE1		; UPDATE LEARN POINTER IN EEPROM
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

	CALL	BUT_LOOKUP		; GET BUTTON CODE BASE ADDRESS
	MOVWF	ADDRESS
	
	MOVFW	FUNC			; GET CURRENT RX BUTTON CODE
	MOVWF	TMP1
	MOVFW	CODE			; GET CURRENT RX DISCR CODE
	MOVWF	TMP2

	CALL	EE_WRITE1		; ... AND WRITE BUTTON & DISCR CODES TO EEPROM
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

	MOVFW	CNTR_HI			; STORE ONE RX COUNTER 
	MOVWF	TMP1
	MOVFW	CNTR_LW
	MOVWF	TMP2

	CALL	TX_LOOKUP		; POINT TO LSB WORD OF SERIAL NUMBER
	CALL	EE_WRITE1		; WRITE ONE 16-BIT COUNTER TO EEPROM
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

  	BCF	PORTB,LED		; LED OFF TO INDICATE FIRST VALID TRANSMISSION RECEIVED
	BSF	FLAGS,PASS2		; INDICATE PASS2 OF LEARN NOW ACTIVE
	BCF	FLAGS,PASS1		; INDICATE PASS2 OF LEARN NOW ACTIVE
	BCF	FLAGS,NORMAL		; CLEAR NORMAL MODE
	GOTO	M_RESYNC		; FORCE A COUNTER RESYNC

; ********* TEST DICRIMINATION VALUE *************
M_DIS
	CALL	BUT_LOOKUP		; POINT TO BUTTON CODE ADDRESS
	MOVWF	ADDRESS			; STORE VALUE IN ADDRESS REGISTER
	CALL	EE_READ1
	BSF	STATUS,PA0		; SELECT PAGE #1

        BTFSS   FLAGS,PASS2
        GOTO    M_DIS2			; CHECK IF IN SECOND PASS OF LEARN
	MOVFW	TMP1			; CHECK DISC VALUE
	XORWF	FUNC,W
	ANDLW	0F0H			; MASK BUTTON CODES
	BTFSC 	STATUS,ZERO 
	GOTO  	M_DIS2			; IF EQUAL CONTINUE
	GOTO	MAIN

M_DIS2
	MOVFW	TMP2			; CHECK DISCRIMINATION VALUE 
	XORWF	CODE,W
	BTFSC	STATUS,ZERO		; IF EQUAL CONTINUE
	GOTO	M_CNT

	BCF	FLAGS,RESYNC		; RESET RESYNC FLAG

        BTFSS   FLAGS,PASS2
        GOTO    M_LOOP	      		; TEST IF IN SECOND PASS OF LEARN 
	GOTO	MAIN

; *************** CHECK COUNTERS VALID ************
M_CNT
	BTFSS	FLAGS,RESYNC		; TEST RESYNC BIT
	GOTO	M_CNT1			; ... IF NOT GET COUNTERS FROM EEPROM

	MOVLW	TMPCNT
	MOVWF	ADDRESS
	CALL	EE_READ1
	BSF	STATUS,PA0		; SELECT PAGE #1
	GOTO	M_SUB			; SUBSTRACT FROM CURRENT COUNTER

M_CNT1
	CALL	TX_LOOKUP		; POINT LOWER 16 BIT COUNTER
	CALL	EE_READ1		; READ LOWER 16 BIT COUNTER FROM EEPROM
	BSF	STATUS,PA0		; SELECT PAGE #1

	MOVFW	TMP1			; TEMPORY STORE FIRST 16-BIT COUNTER
	MOVWF	TMP3
	MOVFW	TMP2
	MOVWF	TMP4

	INCF	ADDRESS,F		; POINT TO UPPER 16-BIT COUNTER
	CALL	EE_READ1		; READ UPPER 16-BIT COUNTER FROM EEPROM
	BSF	STATUS,PA0		; SELECT PAGE #1

	MOVFW	TMP1			; COMPARE UPPER BYTES OF EEPROM COUNTER
	XORWF	TMP3,W
	BTFSS	STATUS,ZERO  		; ... IF EQUAL COMPARE LOWER
	GOTO	M_CNT3			; ... IF NOT EQUAL FORCE RESYNC

	MOVFW	TMP2			; COMPARE LOWER BYTES OF EEPROM COUNTER
	XORWF	TMP4,W
	BTFSC	STATUS,ZERO 		; ... IF NOT EQUAL FORCE RESYNC
	GOTO	M_SUB			; ... ELSE SUBSTRACT FROM RECEIVED COUNTER VALUE

M_CNT3	GOTO	M_RESYNC		; FORCE RESYNC ( EEPROM COUNTERS INVALID )

; ************ CHECK COUNTER WINDOWS ***********
M_SUB
	MOVFW	TMP2			; 16 BIT COUNTER SUBSTRACTION
	SUBWF	CNTR_LW,W
	MOVWF	TMP2			
	BTFSS	STATUS,CARRY		; SKIP IF NO BORROW
	INCF	TMP1,F			; ... ELSE INCR HI BYTE
	MOVFW	TMP1
	SUBWF	CNTR_HI,W
	MOVWF	TMP1

	MOVFW	TMP1			; CHECK FOR REPEATED CODES [ COUNTER INC = 0 ]
	IORWF	TMP2,W

	BTFSS  	STATUS,ZERO 
	GOTO  	M_CHECK0		; ... IF NOT EQUAL CONTINUE

	BSF	FSR,5			; SELECT BANK 1
	CLRF	CNT1_LW			; RESET REPEAT DEBOUNCE TIMER
	BCF	FSR,5			; SELECT BANK 0

	GOTO	M_LOOP

M_CHECK0
	BTFSS	FLAGS,RESYNC		; TEST IF RESYNC ACTIVE
	GOTO	M_CHECK1		; ... IF NOT CHECK FOR COUNTER VALID

	BCF	FLAGS,RESYNC		; RESET RESYNC FLAG
	MOVFW	TMP1			; TEST IF IN 4 WINDOW ( UPPER BYTE )
	BTFSS	STATUS,ZERO 		; ....ELSE  ABORT
	GOTO	M_CNT_FAIL
	MOVLW	0FCH			; TEST IF IN 4 WINDOW ( LOWER BYTE )
	ANDWF	TMP2,W
	BTFSC	STATUS,ZERO 		; ... IF NOT EQUAL COUNTER INVALID
	GOTO	M_UPDATE		; ... ELSE COUNTER VALID, UPDATE EEPROM COUNTERS

M_CNT_FAIL
        BTFSS   FLAGS,PASS2
        GOTO    M_LOOP			; TEST IF ON SECOND PASS OF LEARN
	GOTO	MAIN

M_CHECK1
	BTFSC	TMP1,7			; TEST IF IN DARK REGION ( > 7FFF )
	GOTO	M_LOOP			; ... IF SO IGNORE TRANSMISSION

	MOVFW	TMP1			; TEST FOR RESYNC REQUIRED
	BTFSS	STATUS,ZERO 
	GOTO	M_RESYNC		; DIFFERENCE > 256, FORCE RESYNC

	MOVFW	TMP2			; 16 BIT COUNTER ZERO
	BTFSC	STATUS,ZERO 		; 
	GOTO	M_LOOP			; COUNTERS EQUAL, IGNORE TRANSMISSION

M_CHECK2
	MOVLW	0F0H			; TEST IF IN 16 WINDOW
	ANDWF	TMP2,W
	BTFSC	STATUS,ZERO 		; ... IF NOT VALID FORCE COUNTER RESYNC
	GOTO	M_UPDATE		; ... ELSE UPDATE EEPROM COUNTERS

M_RESYNC
	BSF	FLAGS,RESYNC		; INDICATE RESYNC REQUIRED
	MOVFW	CNTR_HI			; STORE CURRENT RECEIVED 16-BIT COUNTER
	MOVWF	TMP1
	MOVFW	CNTR_LW
	MOVWF	TMP2
	MOVLW	TMPCNT
	MOVWF	ADDRESS
	CALL	EE_WRITE1		; WRITE TEMPORARY COUNTER
	BSF	STATUS,PA0		; RE-SELECT PAGE #1
	GOTO	M_LOOP			; WAIT FOR NEXT TRANSMISSION

; ************ UPDATE EEPROM COUNTER ***********
M_UPDATE

	CALL	TX_LOOKUP		; GET CURRENT TX BASE ADDRESS
	MOVFW	CNTR_HI			; STORE FIRST 16-BIT RECEIVE COUNTER
	MOVWF	TMP1
	MOVFW	CNTR_LW
	MOVWF	TMP2
	CALL	EE_WRITE1		; WRITE LSB WORD OF SERIAL NUMBER TO EEPROM
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

	MOVFW	CNTR_HI			; STORE SECOND 16-BIT RECEIVED COUNTER
	MOVWF	TMP1
	MOVFW	CNTR_LW
	MOVWF	TMP2
	CALL	EE_WRITE1		; WRITE MSB WORD OF SERIAL NUMBER TO EEPROM
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

        BTFSC   FLAGS,NORMAL
        GOTO    M_BUT			; TEST FOR NORMAL PROGRAM FLOW

        BTFSC   FLAGS,PASS1
        GOTO    M_LOOP			; TEST FIRST PASS

; ********** MAYBE UPDATE LEARN POINTER AFTER VALID SELFLEARN *********
M_PTR
       	MOVLW	LRN_PTR			; POINT TO LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_READ1		; READ LEARN POINTER FROM EEPROM
	BSF	STATUS,PA0		; SELECT PAGE #1

	MOVFW	TMP2			; MASK LEARN POINTER
	ANDLW	07H			; ... STORE RESULT IN W REGISTER
	MOVWF	TMP2			; ... AND TMP2 REGISTER

	XORWF	TXNUM,W			; LEARNING EXISTING OR NEW TRANSMITTER
	BTFSC	STATUS,ZERO 		; ... TXNUM EQUAL LEARN POINTER FOR NEW TRANSMITTER
	INCF	TMP2,F			; ... IF NEW TRANSMITTER INCREMENT LEARN POINTER

	MOVLW	6H			; TEST FOR LAST POSITION
	SUBWF	TMP2,W			; TEST FOR LAST POSITION
	BTFSC	STATUS,CARRY 		; TEST FOR LAST POSITION
	CLRF	TMP2			; ... IF LAST POSITION POINT TO FIRST POSITION
	CLRF	TMP1			; ALWAYS CLEAR UPPER BYTE OF LEARN POINTER

       	MOVLW	LRN_PTR			; POINT TO LEARN POINTER
	MOVWF	ADDRESS
	CALL	EE_WRITE1		; WRITE LEARN POINTER TO EEPROM
	BSF	STATUS,PA0		; RE-SELECT PAGE #1

	BCF	STATUS,PA0		; SELECT PAGE #0
	GOTO	LEARN_OK		; THEN INDICATE LEARN SUCCESSFUL

M_BUT	
	BCF	STATUS,PA0		; CLEAR PAGE BIT #0
	BSF	STATUS,PA1		; SET PAGE BIT #1
	GOTO	M_TEST

;**************************************************************************
; PAGE 2:
;**************************************************************************
	ORG	400H

;**************************************************************************
; CALLS TO PAGE 0
;**************************************************************************

EE_WRITE2
	BCF	STATUS,PA1		; SELECT PAGE #0
	GOTO	EEWRITE			; CALL EEPROM WRITE ROUTINE

;**************************************************************************
;
; FUNCTION        : WAIT ()
;
; DESCRIPTION     : WAIT FOR CNT1 TIMES 1 MS
;			CNT2 = OSC/[4*6*1000]  [ 1MS ]
;
; PAGE		: 2
;
;**************************************************************************

WAIT50
	MOVLW	50D			; DELAY COUNTER FOR 50 MS
	MOVWF	CNT1
	GOTO	WAIT

WAIT250
	MOVLW	250D			; DELAY COUNTER FOR 250 MS
	MOVWF	CNT1
WAIT
	MOVLW	200D			; DELAY COUNTER FOR 1 MS
	MOVWF	CNT2
WAIT1
	NOP				; [1] WASTE TIME
	CLRWDT				; [1]
	DECFSZ	CNT2,F			; [1]
	GOTO	WAIT1			; [2]

	DECFSZ	CNT1,F			; [1]
	GOTO	WAIT			; [2]
	RETLW	0

;**************************************************************************
;
; FUNCTION     	: ARMED ()	      			
;
; DESCRIPTION  	: ARMED STATE, CHECK TRIGGER INPUTS AND REMOTE
;
; PAGE		: 2
;
;**************************************************************************

ARMED   
	BSF	PORTB,SIREN		; CHIRP SIREN 50 MS
	BSF	PORTB,PLIGHT		; FLASH PARKING LIGHT 50 MS
	CALL	WAIT50
	BCF	PORTB,SIREN		; SIREN OFF
	BCF	PORTB,PLIGHT		; PARKING LIGHT OFF

	BSF	PORTB,LOCK		; LOCK DOORS 500 MS
	CALL	WAIT250
	CALL	WAIT250
	BCF	PORTB,LOCK		; LOCK DOORS 500 MS

ARMED3
	BSF	FSR,5			; SELECT BANK 0
	MOVLW	25			; COMPENSATE FOR DOOR LOCK TIME
	MOVWF	CNT2_LW
	BCF	FSR,5			; SELECT BANK 0

	BSF	FLAGS,LFLASH		; SET LED FLASH MODE
	BCF	FLAGS,PFLASH		; CLEAR PLIGHT FLASH MODE
	BCF	PORTB,SIREN		; SIREN OFF
	BCF	PORTB,IMMO		; DISABLE START

	MOVLW	BSTATUS			; POINT TO BACKUP STATUS
	MOVWF	ADDRESS
	MOVLW	ARMEDS
	MOVWF	TMP1
	MOVLW	X1
	MOVWF	TMP2
	CALL	EE_WRITE2		; UPDATE STATUS
	BSF	STATUS,PA1		; SELECT PAGE #2

	MOVLW	SSTATUS			; POINT STATUS
	MOVWF	ADDRESS
	MOVLW	ARMEDS
	MOVWF	TMP1
	MOVLW	X2
	MOVWF	TMP2
	CALL	EE_WRITE2		; UPDATE STATUS
	BSF	STATUS,PA1		; SELECT PAGE #2

	MOVLW	ARMEDS
	MOVWF	RAMS			; UPDATE RAM STATE

ARMED4	
	BTFSS	FLAGS1,S_RSTR		; WAS THERE A UNSUCCESSFUL LEARN
	GOTO	ARMED5			; NO, CONTINUE

 	BSF	FLAGS,LFLASH		; SET LED FLASH MODE
	BCF	FLAGS1,S_RSTR		; RESET LEARN TIMEOUT FLAG

ARMED5

        BTFSC   PORTC,DOOR
        GOTO    ALARM			; CHECK IF DOOR OPEN

        BTFSC   PORTC,TRIG
        GOTO    ALARM			; CHECK IF SHOCK SENSOR TRIGGERED

        BTFSC   PORTC,IGN
        GOTO    ALARM			; CHECK IF IGNITION TAMPER

	MOVF  	PC,W
       	MOVWF	STACK
	GOTO	REMOTE			; CALL RF CHECK ROUTINE

	BTFSC	STATUS,CARRY
	GOTO	ARMED4			; CHECK IF TRANSMISSION VALID
	MOVLW	01H
	XORWF	FUNC,W

	BTFSC 	STATUS,ZERO		; IF FUNCTION 1 CODE
       	GOTO  	DRIVE			; GOTO DRIVE MODE
	GOTO	ARMED4			; ELSE STAY IN ARMED MODE

;**************************************************************************
;
; FUNCTION     	: DRIVE ()	      			
;
; DESCRIPTION  	: DRIVE STATE, UNLOCK DOORS, CHIRP SIREN 2 TIMES, 
;		  ENABLE START
;
; PAGE		: 2
;
;**************************************************************************

DRIVE
	BSF	PORTB,SIREN		; CHIRP SIREN 50 MS
	BSF	PORTB,PLIGHT		; FLASH PARKING LIGHT 50 MS
	CALL	WAIT50
	BCF	PORTB,SIREN		; SIREN OFF
	BCF	PORTB,PLIGHT		; PARKING LIGHT OFF

	BSF	PORTB,UNLOCK		; UNLOCK DOORS 500 MS
	CALL	WAIT250
	CALL	WAIT250
	BCF	PORTB,UNLOCK		; UNLOCK DOORS 500 MS
	
	BSF	PORTB,SIREN		; CHIRP SIREN 50 MS
	BSF	PORTB,PLIGHT		; FLASH PARKING LIGHT 50 MS
	CALL	WAIT50
	BCF	PORTB,SIREN		; SIREN OFF
	BCF	PORTB,PLIGHT		; PARKING LIGHT OFF

	BSF	FSR,5			; SELECT BANK 0
	MOVLW	25D			; COMPENSATE FOR DOOR UNLOCK TIME
	MOVWF	CNT2_LW
	BCF	FSR,5			; SELECT BANK 0

DRIVE4
	BCF	FLAGS,LFLASH		; CLEAR LED FLASH MODE
	BCF	FLAGS,PFLASH		; CLEAR PLIGHT FLASH MODE
	BSF	PORTB,IMMO		; ENABLE START
  	BCF	PORTB,LED		; LED OFF

	MOVLW	BSTATUS			; POINT TO BACKUP STATUS
	MOVWF	ADDRESS
	MOVLW	DRIVES
	MOVWF	TMP1
	MOVLW	X1
	MOVWF	TMP2
	CALL	EE_WRITE2		; UPDATE STATUS
	BSF	STATUS,PA1		; SELECT PAGE #2

	MOVLW	SSTATUS			; POINT STATUS
	MOVWF	ADDRESS
	MOVLW	DRIVES
	MOVWF	TMP1
	MOVLW	X2
	MOVWF	TMP2
	CALL	EE_WRITE2		; UPDATE STATUS
	BSF	STATUS,PA1		; SELECT PAGE #2

	MOVLW	DRIVES
	MOVWF	RAMS			; UPDATE RAM STATE

DRIVE5
	CLRF	CNT_HI			; RESET RTCC CLOCK
	CLRF	CNT_LW			

DRIVE6	
	BTFSS	FLAGS1,S_RSTR		; WAS THERE A UNSUCCESSFUL LEARN
	GOTO	DRIVE61			; NO, CONTINUE

 	BCF	PORTB,LED		; SET LED FLASH MODE
	BCF	FLAGS1,S_RSTR		; RESET LEARN TIMEOUT FLAG

DRIVE61

        BTFSC   PORTC,IGN
        GOTO    DRIVE7			; CHECK IF IGNITION ON

        BTFSC   CNT_HI,2        
        GOTO    IMMOB			; TEST FOR IMMOBILIZE TIMEOUT 30S

	MOVF  	PC,W
       	MOVWF	STACK
	GOTO	REMOTE			; CALL RECEIVE ROUTINE

	BTFSC	STATUS,CARRY
	GOTO	DRIVE6			; CHECK IF TRANSMISSION VALID

	MOVLW	01H
	XORWF	FUNC,W

	BTFSC 	STATUS,ZERO		; FUNCTION = 1? 
       	GOTO  	ARMED			; ... YES, GOTO ARMED MODE
	GOTO	DRIVE6			; ... NO, STAY IN DRIVE MODE

DRIVE7

	BTFSS	FLAGS1,S_RSTR		; WAS THERE A UNSUCCESSFUL LEARN
	GOTO	DRIVE71			; NO, CONTINUE

 	BCF	PORTB,LED		; SET LED FLASH MODE
	BCF	FLAGS1,S_RSTR		; RESET LEARN TIMEOUT FLAG

DRIVE71

        BTFSS   PORTC,IGN
        GOTO    DRIVE5			; CHECK IF IGNITION OFF

	MOVF  	PC,W
       	MOVWF	STACK
	GOTO	REMOTE			; CHECK FOR VALID TRANSMISSIONS

	BTFSC	STATUS,CARRY
	GOTO	DRIVE7			; CHECK IF TRANSMISSION VALID

	MOVLW	01H
	XORWF	FUNC,W

	BTFSS  	STATUS,ZERO 		; FUNCTION 1 CODE?
	GOTO  	DRIVE7			; ... NO, STAY IN DRIVE

DRIVE8					; ... YES REDO OUTPUTS
	BSF	PORTB,IMMO		; AND WAIT FOR IGN = OFF
  	BCF	PORTB,LED
	GOTO	DRIVE7

;**************************************************************************
;
; FUNCTION     	: IMMOB ()	      			
;
; DESCRIPTION  	: IMMOB STATE - DISABLE START
;
; PAGE		: 2
;
;**************************************************************************

IMMOB

  	BSF	PORTB,LED		; LED ON
	BCF	PORTB,PLIGHT		; PLIGHT OFF
	BCF	PORTB,IMMO		; DISABLE START

IMMOB1

	MOVLW	BSTATUS			; POINT TO BACKUP STATUS
	MOVWF	ADDRESS
	MOVLW	IMMOBS
	MOVWF	TMP1
	MOVLW	X1
	MOVWF	TMP2
	CALL	EE_WRITE2		; UPDATE STATUS
	BSF	STATUS,PA1		; SELECT PAGE #2

	MOVLW	SSTATUS			; POINT STATUS
	MOVWF	ADDRESS
	MOVLW	IMMOBS
	MOVWF	TMP1
	MOVLW	X2
	MOVWF	TMP2
	CALL	EE_WRITE2		; UPDATE STATUS
	BSF	STATUS,PA1		; SELECT PAGE #2

	MOVLW	IMMOBS
	MOVWF	RAMS			; UPDATE RAM STATE

IMMOB2

	BTFSS	FLAGS1,S_RSTR		; WAS THERE A UNSUCCESSFUL LEARN
	GOTO	IMMOB3			; NO, CONTINUE

 	BSF	PORTB,LED		; SET LED ON
	BCF	FLAGS1,S_RSTR		; RESET LEARN TIMEOUT FLAG

IMMOB3
	MOVF  	PC,W
       	MOVWF	STACK
	GOTO	REMOTE			; RF CHECK ROUTINE

	BTFSC	STATUS,CARRY
	GOTO	IMMOB2			; CHECK IF TRANSMISSION VALID
	MOVLW	01H
	XORWF	FUNC,W

	BTFSS  	STATUS,ZERO		; FUNCTION 1 CODE?
       	GOTO  	IMMOB2			; ... NO, STAY IN IMMOB MODE

        BTFSC   PORTC,IGN		; IGN ON?		
        GOTO    DRIVE4			; ... YES, GOTO DRIVE MODE

	GOTO	ARMED			; ... NO , GOTO ARMED MODE	


;**************************************************************************
;
; FUNCTION     	: ALARM ()	      			
;
; DESCRIPTION  	: ALARM STATE - SWITCH SIREN ON, FLASH PARKING LIGHTS
;
; PAGE		: 2
;
;**************************************************************************

ALARM
	BSF	PORTB,SIREN		; SIREN ON
	BSF	FLAGS,PFLASH		; SET PLIGHT FLASH MODE
	BSF	FLAGS,LFLASH		; SET LED FLASH MODE
	CLRF	CNT_HI			; RESET RTCC CLOCK
	CLRF	CNT_LW			
	BCF	PORTB,IMMO		; DISABLE START

ALARM1

	MOVLW	BSTATUS			; POINT TO BACKUP STATUS
	MOVWF	ADDRESS
	MOVLW	ALARMS
	MOVWF	TMP1
	MOVLW	X1
	MOVWF	TMP2
	CALL	EE_WRITE2		; UPDATE STATUS
	BSF	STATUS,PA1		; SELECT PAGE #2

	MOVLW	SSTATUS			; POINT STATUS
	MOVWF	ADDRESS
	MOVLW	ALARMS
	MOVWF	TMP1
	MOVLW	X2
	MOVWF	TMP2
	CALL	EE_WRITE2		; UPDATE STATUS
	BSF	STATUS,PA1		; SELECT PAGE #2

	MOVLW	ALARMS
	MOVWF	RAMS			; UPDATE RAM STATE

ALARM2	
	BCF	PORTB,IMMO		; DISABLE START

        BTFSC   CNT_HI,2
        GOTO    ARMED3			; TEST FOR ALARM TIMEOUT

	MOVF  	PC,W
       	MOVWF	STACK
	GOTO	REMOTE			; CALL RF CHECK ROUTINE

	BTFSC	STATUS,CARRY
	GOTO	ALARM2			; CHECK IF TRANSMISSION VALID
	MOVLW	01H
	XORWF	FUNC,W

	BTFSS  	STATUS,ZERO		; FUNCTION 1 CODE?
	GOTO  	ALARM2			; ... NO, STAY IN ALARM MODE	
	GOTO	DRIVE			; ... YES, GOTO DRIVE MODE	

;**************************************************************************
;
; FUNCTION        : REMOTE ()
;
; DESCRIPTION     : CHECK RF FOR VALID CODE
;
; NOTE	****	  : CALLS TO THIS ROUTINE CAN ONLY BE MADE FROM THE LOWER
;		    HALF OF THE PAGE
;
; PAGE		  : 2
;
;**************************************************************************

REMOTE  
	BSF	STATUS,PA0		; SELECT PAGE #1
	BCF	STATUS,PA1		; SELECT PAGE #1
	GOTO	M_CHECK			; MAIN RF CHECK ROUTINE
					
; ************ TEST RECEIVED BUTTON CODE ***********
M_TEST		

; AT THIS POINT CODE HAS BEEN DECRYPTED
; DISCRIMINATION VALUE IS VALID
; COUNTERS ARE VALID						
; FUNCTION CODE MUST BE INTERPRETED

	SWAPF	FUNC,F			; GET FUNCTION CODE BITS IN LOWER NIBBLE  : XXXX 111X
	BCF	FUNC,4			; CLEAR BIT 4 FOR RIGHT RORATE 		  : XXX0 111X		
	RRF	FUNC,F			; RIGHT ROTATE TO GET INTO LOWER 3 BITS	  : XXXX 0111	
	BTFSC	STATUS,CARRY		; CHECK IF CARRY OUT : S3 WAS SET
	BSF	FUNC,3			; SET BIT 3 TO INDICATE S3 WAS SET

M_TEST1	
	BSF	FLAGS,RPT		; SET REPEATED CODE FLAG
	BSF	FSR,5			; SELECT BANK 0
	CLRF	CNT1_LW			; RESET DEBOUNCE TIMER
	CLRF	CNT2_LW			; RESET 2 SEC PANIC TIMER
	BCF	FSR,5			; SELECT BANK 0

	MOVLW	0FH			; MASK FUNCTION BITS
	ANDWF	FUNC,F			

	MOVLW	02H			; TEST FOR TRUNK RELEASE
	XORWF	FUNC,W			; FUNC = 2

	BTFSS  	STATUS,ZERO 
	GOTO  	M_TEST2

	BSF	PORTB,TRUNK		; DO TRUNK RELEASE
	CALL	WAIT250
	CALL	WAIT250
	BCF	PORTB,TRUNK
	BSF	FSR,5			; SELECT BANK 0
	MOVLW	10			; COMPENSATE FOR TRUNK RELEASE TIME
	MOVWF	CNT2_LW
	BCF	FSR,5			; SELECT BANK 0

M_TEST2
	MOVLW	ALARMS			; DONT TEST FOR CAR
	XORWF	RAMS,W			; FINDER IN ALARM STATE
	BTFSC	STATUS,ZERO
	GOTO	M_TEST3

	MOVLW	03H			; TEST FOR CAR FINDER
	XORWF	FUNC,W			; FUNC = 3

	BTFSS  	STATUS,ZERO 	   
	GOTO  	M_TEST3		   

	BSF	PORTB,SIREN		; CHIRP SIREN 50 MS
	CALL	WAIT50
	BCF	PORTB,SIREN		; SIREN OFF

M_TEST3
	MOVLW	2			; CALCULATE RETURN ADDRESS
	ADDWF  	STACK,W
	CLRC				; SET VALID RECEPTION FLAG
       	MOVWF	PC			; RETURN TO CALLER		

;**************************************************************************
; END OF FILE : SECSYS14.ASM
;**************************************************************************
	ORG	7FFH			; RESET VECTOR
	GOTO	RESET
	END
