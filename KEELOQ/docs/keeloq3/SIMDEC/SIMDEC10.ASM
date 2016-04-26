;------------------------------------------------------------------------------
;  MICROCHIP KEELOQ CODE HOPPING SIMPLE DECODER
;
;------------------------------------------------------------------------------
;  LEGAL NOTICE
;
;  The information contained in this document is proprietary and 
;  confidential information of Microchip Technology Inc.  Therefore all 
;  parties are required to sign a non-disclosure agreement before 
;  receiving this document.
;------------------------------------------------------------------------------

;===========================================================================
; SIMPLE DECODER WITH ONE STEP LEARN AND SINGLE KEY
;===========================================================================
;
;PROGRAM INFORMATION:	FILE:	SIMDEC10.ASM	
;			DATE:	08/15/96 
;			VER.:	1.0
;			CKSM:	XXXXH - FUSES:RC,WDT=ON,CP=ON
;			ASM.: 	MPASM VERSION 1.40 USED
;			INCL:	NONE
;			TABS:   8
;===========================================================================
; CONFIGURATION CONTROL:
; 
; DATE		VERSION	LINE	CHANGES
; 08/14/96	1.0		FIRST VERSION
;===========================================================================
;	LIST P=16C54,R=DEC
;===========================================================================
;******USER DEFINITIONS******
MAX_USERS	EQU	15
; This is the maximum number of transmitters that the system is able to 
; learn (1 to 15).  
;===========================================================================

; GENERAL PURPOSE REGISTERS

IND	EQU	00H		; INDIRECT ADDRESS REGISTER
RTCC	EQU	01H		; REAL TIME COUNTER CLOCK
PC	EQU	02H		; PROGRAM COUNTER
STATUS	EQU	03H             ; STATUS REGISTER
FSR	EQU	04H		; FILE SELECT REGISTER
PORTA   EQU     05H		; PORT A
PORTB   EQU     06H		; PORT B

; USER DEFINED REGISTER

FLAGS	EQU	07H		; USER FLAG REGISTER
ADDRESS	EQU	08H		; ADDRESS REGISTER
TXNUM	EQU	09H		; CURRENT TX
OUTBYT	EQU	0AH		; GENERAL DATA REGISTER
MASK	EQU	OUTBYT		; MASK REGISTER USED IN DECRYPTION
TMP_CNT	EQU	OUTBYT		; TEMPORARY COUNTER

; COUNTER REGISTERS

CNT0    EQU     0BH		; LOOP COUNTERS
CNT1    EQU	0CH		
CNT2    EQU     0DH		

CNT_HI	EQU	0EH		; 16 BIT CLOCK COUNTER
CNT_LW	EQU	0FH		

; CIRCULAR BUFFER REGISTER

CSR0    EQU     10H            	; 64 BIT RECEIVE SHIFT REGISTER
CSR1    EQU     11H            
CSR2    EQU     12H            
CSR3    EQU     13H            
CSR4    EQU     14H            	
CSR5    EQU     15H            
CSR6    EQU     16H            
CSR7    EQU     17H            

; TEMP REGISTERS
TMP1	EQU	18H		; TEMP REGISTER FOR READ AND WRITE
TMP2	EQU	19H		; TEMP REGISTER FOR READ AND WRITE
REG	EQU	1AH		; NOT USED
REG1	EQU	1BH		; NOT USED

KEY0	EQU	1CH		; 64 BIT KEY SHIFT REGISTER
KEY1	EQU	1DH
KEY2	EQU	1EH
KEY3	EQU	1FH
KEY4	EQU	CNT2
KEY5	EQU	CSR5
KEY6	EQU	CSR6
KEY7	EQU	CSR7

; ***** USER REGISTER RE-MAPPINGS ***************

HOP1	EQU	CSR0		; 32 BIT HOPCODE REGISTER
HOP2	EQU	CSR1
HOP3	EQU	CSR2
HOP4	EQU	CSR3

; RECEIVED TRANSMISSION OPEN 32 BITS 

SER_0	EQU	CSR7		; 28 BIT SERIAL NUMBER
SER_1	EQU	CSR6
SER_2	EQU	CSR5
SER_3	EQU	CSR4

; RECEIVED TRANSMISSION ENCRYPTED 32 BITS 

FUNC	EQU	CSR3		; BUTTON CODE & USER BIT FUNCTION BYTE
CODE1	EQU	CSR2		; DISCRIMINATION VALUE
CNTR_HI	EQU	CSR1		; 16 BIT RX COUNTER HIGH BYTE
CNTR_LW	EQU	CSR0		; 16 BIT RX COUNTER LOW BYTE

; ********* EEPROM MEMORY *******
LRNPTR	EQU	01H		; LEARN POINTER

; ********* PORTA BIT DEFINITIONS *******

RES0	EQU	0H		; RESERVED PIN
RFIN	EQU	1H		; RF INPUT
LRN	EQU	2H		; LEARN BUTTON
LED	EQU	3H		; LEARN INDICATOR LED OUTPUT - VALID SIGNAL

; ********* PORTB BIT DEFINITIONS *******

S0	EQU	0H		; S0 OUTPUT
S1	EQU	1H		; S1 OUTPUT
S2	EQU	2H		; S2 OUTPUT
S3	EQU	3H		; S3 OUTPUT

DIO	EQU	4H		; EEPROM DATA LINE
CLK	EQU	5H		; EEPROM SERIAL CLOCK
CS	EQU	6H		; EEPROM CHIP SELECT
RES1	EQU	7H		; RESERVED PIN

; ********* COMPILER DEFINES ******************
NBITS   EQU     64      	; MAXIMUM TRANSMISSION BIT LENGTH
MIN     EQU     560            	; TRANSMISSION HEADER MINIMUM LENGTH [ÊS]
TRISA	EQU	0111B		; PORTA: TRI-STATE VALUE
WRCFG	EQU	00000000B	; PORTB: EEPROM WRITE TRI-STATE VALUE
RDCFG	EQU	00010000B	; PORTB: EEPROM READ TRI-STATE VALUE

;****** FLAGS DEFINITIONS **************
BITIN	EQU	0H		; RF BIT VALUE 
LRNF	EQU	1H		; LEARN FLAG
SEC_CNT	EQU	2H		; SECOND COUNTER IS BEING CHECKED
RELEARN	EQU	3H		; RELEARNING A TRANSMITTER

;****** STATUS REGISTER BIT DEFINITIONS *****************
C       EQU       0		; CARRY
DC      EQU       1		; DIGIT CARRY
Z       EQU       2		; ZERO
PD      EQU       3		; POWER DOWN
TO      EQU       4		; TIMEOUT
PA0     EQU       5		; NOT USED
PA1     EQU       6		; NOT USED 

;===========================================================================
; PAGE 0: 
;===========================================================================
	ORG 00H

;===========================================================================
;
; FUNCTION     : RESET ()	      			
;
; DESCRIPTION  : PROGRAM RESET ROUTINE
;
;===========================================================================

RESET	
	MOVLW	000111B			; SETUP RTCC PRESCALER
	OPTION

	CLRF	PORTA			; RESET PORTA
	CLRF	PORTB			; RESET PORTB

	MOVLW	TRISA			; SETUP PORTA
	TRIS	PORTA
	MOVLW	WRCFG			; SETUP PORTB
	TRIS 	PORTB

	CLRF	FLAGS			; RESET FLAGS

	GOTO	M_LOOP			; GOTO MAIN PROGRAM LOOP

;===========================================================================
;
; FUNCTION     	: ROT_SHIFT()	      			
;
; DESCRIPTION  	: RIGHT ROTATE 64 BIT RECEIVE SHIFT REGISTER
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================

ROT_SHIFT
        RRF     CSR7,F
        RRF     CSR6,F
        RRF     CSR5,F                     
        RRF     CSR4,F                     
        RRF     CSR3,F                     
        RRF     CSR2,F                     
        RRF     CSR1,F                    
        RRF     CSR0,F                    
	RETLW	0

;===========================================================================
;
; FUNCTION     	: TX_LOOKUP ()	      			
;
; DESCRIPTION  	: TRANSMITTER ADDRESS CALCULATION
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================

TX_LOOKUP
	MOVF	TXNUM,W			; USE TRANSMITTER NUMBER TO CALCULATE 
	MOVWF	ADDRESS			; ADDRESS OF TRANSMITER BLOCK
	CLRC				; MULTIPLY BY 4 
	RLF	ADDRESS,F
	RLF	ADDRESS,F
	MOVLW	04H			; AND ADD 4
	ADDWF	ADDRESS,F
	RETLW	0			; RETURN

;===========================================================================
;
; FUNCTION     	: TST_RTCC ()	      			
;
; DESCRIPTION  	: UPDATE RTCC COUNTER 
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================
TST_RTCC
	CLRWDT				; RESET WATCHDOG TIMER
	MOVLW	TRISA			; UPDATE TRI-STATE REGISTER FOR PORTA
	TRIS	PORTA

	BTFSS	RTCC,7			; TEST FOR 32MS TIMEOUT	ON RTCC MSB
	RETLW	0			; ... DO QUICK RETURN TO RECEIVE ROUTINE

; **** INCREASE 16 BIT CLOCK TIMER *******

	BCF	RTCC,7			; CLEAR MSB OF RTCC
	INCF	CNT_LW,F		; INCREASE 16 COUNTER
	SKPNZ				; INCREASE UPPER BYTE IF ZERO ( OVERFLOW )
	INCF	CNT_HI,F
	RETLW	0

;===========================================================================
;
; FUNCTION     	: TST_TIMER()	      			
;
; DESCRIPTION  	: TEST 32MS TIMER AND UPDATE OUTPUTS IF REQUIRED
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================

TST_TIMER
; ***** TEST FOR 500 MS TIMEMOUT ON OUTPUTS **********
	BTFSS	CNT_LW,4		; TEST FOR 500 MS TIMEOUT
	GOTO	TST_30			; ... IF NOT TEST 30S TIMEOUT

	MOVLW	070h;07FH;+++++0F0H
	ANDWF	PORTB,F			; DOWN ALL PULSE OUTPUTS 

 ; ********* TEST FOR 30 S LEARN TIMEOUT *************
TST_30	BTFSS	FLAGS,LRNF
	GOTO	TST_END
	
	BTFSC	CNT_HI,2		; TEST FOR LEARN TIMEOUT
	GOTO	RESET			; ... IF LEARN TIMEMOUT FORCE SOFT RESET 

TST_END	
	RETLW	0H

;===========================================================================
;
; FUNCTION     	: SENDC ()	      			
;
; DESCRIPTION  	: SEND EEPROM COMMAND 
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================

SENDC
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
        RLF     OUTBYT,F                ; GET NEXT BIT INTO CARRY
        BSF     PORTB,CLK               ; CLOCK HIGH
        GOTO    $+1                     ; WAIT 2 US
        GOTO    $+1                     ; WAIT 2 US
        BCF     PORTB,CLK               ; CLOCK LOW
	DECFSZ	CNT1,F			; LOOP COUNTER
        GOTO	SENDC2
        BCF     PORTB,DIO               ; AVOID CONTENTION WITH READ
        RETLW   0

;===========================================================================
;
; FUNCTION     	: EEWRITE ()	      			
;
; DESCRIPTION  	: WRITE 16 BIT VALUE TO EEPROM 
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================

EEWRITE

; ******* EEPROM WRITE ENABLE ******************

WRITE0  MOVLW	30H			; WRITE ENABLE COMMAND
	MOVWF   OUTBYT               	
        CALL    SENDC			; SEND COMMAND TO EEPROM
        BCF     PORTB,CS                ; END COMMAND, DESELECT

; ******** WRITE 16-BIT WORD TO EEPROM *********

WRITE1  MOVFW   ADDRESS			; GET EEPROM ADDRESS
	MOVWF	OUTBYT
        BSF     OUTBYT,6		; WRITE COMMAND
        CALL    SENDC                   ; SEND COMMAND TO EEPROM

	MOVLW	16D			; 16 DATA BITS
        MOVWF   CNT1	                

WRITE2
        BTFSS   TMP1,7			; TEST MSB OF 16 BIT WORD
        BCF     PORTB,DIO		; SET DATA BIT
        BTFSC   TMP1,7			; ... ELSE 
        BSF     PORTB,DIO               ; CLEAR DATA BIT
        GOTO    $+1                     ; WAIT 2 US
        RLF     TMP2,F                  ; SHIFT LO BYTE
        BSF     PORTB,CLK               ; CLOCK HIGH
        GOTO    $+1                     ; WAIT 2 US
        RLF     TMP1,F                  ; SHIFT HI BYTE
        BCF     PORTB,CLK               ; CLOCK LOW
	DECFSZ	CNT1,F
        GOTO	WRITE2             	; LOOP COUNTER

WAITACK
       	BCF     PORTB,CS                ; END OF WRITE COMMAND, DESELECT

        MOVLW   RDCFG
        TRIS    PORTB                   ; DIO = INPUT
        BSF     PORTB,CS		; CS HIGH TO WAIT FOR ACK
WRITE5 	
	BTFSC	PORTB,DIO		; CHECK FOR ACK
	GOTO	WRITE6			; WDT RESET ON NO ACK
	GOTO	WRITE5

WRITE6  BCF     PORTB,CS                ; END OF ACK

; ******* EEPROM WRITE DISABLE ****************
        MOVLW   000H             	; WRITE DISABLE COMMAND
	MOVWF	OUTBYT
        CALL    SENDC
        BCF     PORTB,CS                ; END OF DISABLE COMMAND, DESELECT

	INCF	ADDRESS,F    		; POINT TO NEXT EEPROM ADDRESS ( BY DEFAULT )
	RETLW	0H

;===========================================================================
;
; FUNCTION     	: EEREAD ()	      			
;
; DESCRIPTION  	: READ 16 BIT VALUE FROM EEPROM 
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================

EEREAD
        MOVFW   ADDRESS
        MOVWF	OUTBYT
        BSF     OUTBYT,7                ; COMMAND = READ
        CALL    SENDC                   ; SEND COMMAND
        MOVLW   RDCFG
        TRIS    PORTB                   ; DIO = INPUT
	MOVLW   16D                	; 16 BITS TO READ
	MOVWF	CNT1

READ0   BSF     PORTB,CLK               ; CLOCK HIGH
        RLF     TMP2,F                  ; SHIFT LO BYTE
        BCF     TMP2,0                  ; ASSUME BIT WILL BE 1
        BTFSC   PORTB,DIO               ; READ DIO LINE
        BSF     TMP2,0                  ; COPY BIT TO REGISTER
        BCF     PORTB,CLK               ; CLOCK LOW
        RLF     TMP1,F                  ; SHIFT HI BYTE
        DECFSZ  CNT1,F			; LOOP COUNTER
	GOTO	READ0
        BCF     PORTB,CS                ; END READ CYCLE

	RETLW	0H

;===========================================================================
;
; FUNCTION     	: DECRYPT ()	      			
;
; DESCRIPTION  	: DECRYPTS 32 BIT [HOP1:HOP4] USING [CSR0:CSR7]
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================


; THE KEY USED IS A FIXED KEY WHICH IS NOT SERIAL NUMBER DEPENDANT
; THE USER MUST CHOOSE A KEY AND CHANGE THE CODE HERE TO REFLECT THAT KEY

DECRYPT
	MOVLW	0EFH		; LOAD FIXED 64 BIT KEY LSB		
	MOVWF	KEY0
	MOVLW	0CDH
	MOVWF	KEY1
	MOVLW	0ABH
	MOVWF	KEY2
	MOVLW	089H
	MOVWF	KEY3
	MOVLW	067H
	MOVWF	KEY4
	MOVLW	045H
	MOVWF	KEY5
	MOVLW	023H
	MOVWF	KEY6
	MOVLW	001H		; LOAD FIXED 64 BIT KEY MSB
	MOVWF	KEY7

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
        SKPZ                    ; COPY THE BIT TO BIT 7
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

        DECFSZ  CNT0,F         	; INNER LOOP 48 TIMES
        GOTO    DECRYPT_INNER   ; INNER LOOP 48 TIMES

        DECFSZ  CNT1,F         	; OUTER LOOP 12 TIMES (11 + 1 TO RESTORE KEY)
        GOTO    DECRYPT_OUTER   ; OUTER LOOP 12 TIMES (11 + 1 TO RESTORE KEY)

        RETLW   0               ; RETURN 

;===========================================================================
;
; FUNCTION     	: LOAD_CNT_VALS()	      			
;
; DESCRIPTION  	: LOAD COUNTERS INTO WRITE BUFFERS
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================

LOAD_CNT_VALS
	MOVFW	CNTR_HI			; LOAD MSB OF COUNTER
	MOVWF	TMP1
	MOVFW	CNTR_LW			; LOAD LSB OF COUNTER
	MOVWF	TMP2
	RETLW	0

;===========================================================================
;
; FUNCTION     	: RECEIVE()	      			
;
; DESCRIPTION  	: RECEPTION ROUTINE FOR PWM TRANSMISSIONS
;
; NOTE		: THIS ROUTINE MUST BE IN THE LOWER HALF OF THE PAGE
;
;===========================================================================

RECEIVE

;******** WAIT FOR HEADER AND CALIBRATE *******************

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
	BTFSS   STATUS,C		; [2] NEGATIVE?
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
	GOTO	$+1			; [2] WASTE TIME
	GOTO	$+1			; [2] WASTE TIME
	DECFSZ  CNT2,1			; [1]
	GOTO    DL2                     ; [2] CNT0 X 8 us [ CNT0 x Te ]

SAMPLE2
	BCF     FLAGS,BITIN             ; [1]   CLEAR BIT POSITION
	BTFSS   PORTA,RFIN              ; [1.5] LEAVE 0 IF LINE HIGH
	BSF     FLAGS,BITIN             ; [0.5] MAKE 1 IF LINE LOW
					; SUB TOTAL = 3 CYCLES

	CALL    ROT_SHIFT               ; [11]+[2] CSR SHIFT + CALL
	BCF	CSR7,7			; [1]
	BTFSC   FLAGS,BITIN		; [1.5]
	BSF     CSR7,7			; [0.5]
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
	GOTO	$+1			; [2] WASTE TIME
	GOTO	$+1			; [2] WASTE TIME
	CLRWDT                          ; [1] RESET WATCHDOG TIMER
	DECFSZ  CNT2,1                  ; [1]
	GOTO    DL3                     ; [2] CNT0 X 8 us [ CNT0 X Te ]

SAMPLE3
	BTFSC   PORTA,RFIN              ; [2] INPUT LOW?  THIRD SAMPLE
	GOTO    RMT0                    ; [0] NO--RECEIVE ERROR

	CALL    TST_RTCC                ; [11] CHECK RTCC

	DECFSZ  CNT1,1                  ; [1] LAST BIT?
	GOTO    RCV8                    ; [2] ... NO, GET NEXT BIT
	GOTO	RMT1		     	; TOTAL = 14 CYCLES


RMT_0
RMT0	
RMT01	BSF	STATUS,C		; INVALID TRANSMISSION
	RETLW	1			; RETURN

RMT1	BSF	PORTA,LED		; VALID TRANSMISSION FORMAT, LED ON
	MOVLW	0FH			; FORCE OPEN BUTTON CODES TO ZERO
	ANDWF	SER_0,1
	CLRC				; VALID SERIAL NUMBER => VALID TX
 	RETLW   0                    	; RETURN 

;===========================================================================
;
; FUNCTION     	: M_LOOP ()	      			
;
; DESCRIPTION  	: MAIN PROGRAM ROUTINE
;
;===========================================================================

M_LOOP	BCF	PORTA,LED		 
	BTFSS	PORTA,LRN		
	GOTO	LEARN		 	; TEST & HANDLE LEARN BUTTON
	CALL	TST_RTCC		; UPDATE TIMER 
	CALL	TST_TIMER		; HANDLE TIMER - UPDATE OUTPUTS
	CALL	RECEIVE			; RECEIVE TRANSMISSION 
	BC	M_LOOP			; CHECK IF TRANSMISSION VALID

M_SEARCH
	CLRF	TXNUM			; TEST FIRST POSITION
; ******* COMPARE LOWER WORD OF SERIAL NUMBER ********
M_SERIAL
	CALL	TX_LOOKUP		; GET TX BASE ADDRESS
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS
	CALL	EEREAD			; READ LOWER 16-BITS OF SER# FROM EEPROM
  		    
	MOVFW	TMP1			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_2,W
	BNZ	M_NEXT			; IF NOT EQUAL CHECK NEXT
	MOVFW	TMP2			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_3,W
	BNZ	M_NEXT			; IF NOT EQUAL CHECK NEXT
	
; ******* COMPARE UPPER WORD OF SERIAL NUMBER ********
M_SERIAL2
	INCF	ADDRESS,F		; POINT TO NEXT ENTRY 
	CALL	EEREAD			; READ UPPER 16-BITS OF SER# FROM EEPROM

	MOVFW	TMP1			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_0,W
	BNZ	M_NEXT			; IF NOT EQUAL CHECK NEXT

	MOVFW	TMP2			; COMPARE RX AND EEPROM VALUES
	XORWF	SER_1,W
	BNZ	M_NEXT			; IF NOT EQUAL CHECK NEXT

	BTFSS	FLAGS,LRNF		; LEARN MODE
	GOTO	M_HOP			; FOUND TRANSMITTER - DECRYPT

	BSF	FLAGS,RELEARN		; SET RELEARN FLAG
	GOTO	LEARN_F			; FOUND TRANSMITTER - LEARN
		
; **** SEARCH NEXT POSITION FOR SERIAL NUMBER *****
M_NEXT	INCF	TXNUM,F			; POINT TO NEXT TRANSMITTER POSITION
	MOVLW	MAX_USERS		; TEST FOR LAST POSITION
	SUBWF	TXNUM,W			
	BTFSS	STATUS,C		; NOT FOUND IN MAP
	GOTO	M_SERIAL		; TRY NEXT POSITION
M_NF
	BTFSS	FLAGS,LRNF		; LEARN MODE
	GOTO	M_LOOP			; NO... INVALID SERIAL NUMBER 
	GOTO	LEARN_NF		; NEW TRANSMITTER - USE POINTER FOR LEARN

; ********** DECRYPT HOPCODE *********************
M_HOP	
	CALL	DECRYPT			; DECRYPT HOPCODE 

; ********* TEST DICRIMINATION VALUE *************
M_DIS	MOVFW	SER_3			; SERIAL NUBER LSB MUST BE EQUAL
	XORWF	CODE1,W			; TO DISCRIMINATION VALUE
	BNZ	M_LOOP

; *************** CHECK COUNTERS VALID ************
	BCF	FLAGS,SEC_CNT		; CHECK FIRST COUNTER
M_CNT	CALL	TX_LOOKUP		; POINT LOWER 16 BIT COUNTER
	BTFSC	FLAGS,SEC_CNT		; IF SECOND COUNTER IS USED
	INCF	ADDRESS,F		; INCREMENT ADDRESS
	CALL	EEREAD			; READ LOWER 16 BIT COUNTER FROM EEPROM

; ************ CHECK COUNTER WINDOWS ***********
M_SUB
	MOVFW	TMP2			; 16 BIT COUNTER SUBSTRACTION
	SUBWF	CNTR_LW,W
	MOVWF	TMP2			
	SKPC				; SKIP IF NO BORROW
	INCF	TMP1,F			; ... ELSE INCR HI BYTE
	MOVFW	TMP1
	SUBWF	CNTR_HI,W
	MOVWF	TMP1

	BCF	TMP1,0			; MAKE ACCEPTED WINDOW 512

M_CHECK0
	MOVFW	TMP1			; TEST IF IN WINDOW ( UPPER BYTE )
	BTFSC	STATUS,Z
	GOTO	M_CHECK2		; GO AND CHECK LOWER BYTE

	BTFSC	FLAGS,SEC_CNT		; IF SECOND COUNTER
	GOTO	M_LOOP			; ERROR - GOTO MAIN LOOP		

	BSF	FLAGS,SEC_CNT		; SET FLAG FOR SECOND COUNTER CHECK
	GOTO	M_CNT			; AND CHECK IT

M_CHECK2
	MOVFW	TMP2			; CHECK LOWER BYTE
	BZ	M_TZERO			; IF REPEAT - RESET TIMEOUT COUNTER

; ************ UPDATE EEPROM COUNTER ***********
M_UPDATE
	CALL	TX_LOOKUP		; GET CURRENT TX BASE ADDRESS
	CALL	LOAD_CNT_VALS		; LOAD COUNTER VALUES
	CALL	EEWRITE			; UPDATE FIRST COUNTER
	CALL	LOAD_CNT_VALS		; LOAD COUNTER VALUES	
	CALL	EEWRITE			; UPDATE SECOND COUNTER

; ******** UPDATE OUTPUT WITH CURRENT BUTTON CODE ********

M_OUTPUT 
	MOVLW	0F0H			; MASK ONLY BUTTON CODES
	ANDWF	FUNC,1
	SWAPF	FUNC,1			; GET BUTTON CODE FROM FUNC BYTE
	
	BTFSC	FUNC,0			; CHANGE BUTTON TO S-OUTPUT FORMAT
	BSF	FUNC,4			; [ S2 S1 S0 S3 ]
	CLRC				
	RRF	FUNC,W			
	
M_OUTPUT1
	IORLW	B'10000000'		;+++++
	MOVWF	PORTB			; UPDATE PORT WITH FUNCTION CODE
	
M_TZERO CLRF	CNT_HI			; RESET RTCC CLOCK
	CLRF	CNT_LW			

M_END	
	GOTO	M_LOOP			; WAIT FOR NEXT TRANMISSION

;===========================================================================
;
; FUNCTION     	: LEARN ()	      			
;
; DESCRIPTION  	: LEARN ROUTINE
;
;===========================================================================

LEARN
	CLRF	CNT_LW			; RESET TIMER
	CLRF	CNT_HI
	
	
LEARN1	BSF	PORTA,LED		; LED ON
	CALL	TST_RTCC		; UPDATE TIMER
	BTFSC	PORTA,LRN		; TEST FOR BUTTON RELEASE		
	GOTO	LEARN2			; ENTER LEARN MODE
	BTFSS	CNT_HI,0		; TEST FOR ERASE ALL
	GOTO	LEARN1			; LOOP BACK

; ******* EEPROM ERASE ALL ******************

	BCF	PORTA,LED
ERASE_ALL
	CLRWDT				; CLEAR WATCHDOG TIMER
	BTFSS	PORTA,LRN		; WAIT FOR BUTTON RELEASE
	GOTO	ERASE_ALL		; LOOP BACK

  	MOVLW	30H			; ERASE ENABLE COMMAND
	MOVWF   OUTBYT               	
        CALL    SENDC			; SEND COMMAND TO EEPROM
  	MOVLW	20H			; ERASE ALL COMMAND
	MOVWF   OUTBYT               	
        CALL    SENDC			; SEND COMMAND TO EEPROM
	CALL	WAITACK			; WAIT FOR ERASE ACK
	GOTO	RESET			; START OVER
	
LEARN2
	BCF	PORTA,LED		; CLEAR LED
	BSF	FLAGS,LRNF		; SET LEARN FLAG

LEARN3
	CALL	TST_RTCC		; UPDATE TIMER
	CALL	TST_TIMER		; CHECK FOR LEARN TIMEOUT
	CALL	RECEIVE			; RECEIVE TRANSMISSION 
	BC	LEARN3			; CHECK IF TRANSMISSION VALID
 	GOTO	M_SEARCH		; CHECK IF SERIAL NUMBER IS IN MAP

LEARN_NF

; *** IF SERIAL NOT IN MAP READ SELFLEARN POINTER ***

	MOVLW	LRNPTR			; POINT TO LEARN POINTER
	MOVWF	ADDRESS
	CALL	EEREAD			; READ LEARN POINTER FROM EEPROM

	MOVF	TMP2,W			; CHECK LOWER BYTE
	MOVLW	0H			; LOAD 0 DEFAULT
	BTFSC	STATUS,Z		; IF LOWER != 0 LEARN ON 0
	MOVF	TMP1,W			; ELSE LEARN ON TMP1 VALUE
	MOVWF	TXNUM			; LOAD TXNUM

LEARN_F
	CALL	TX_LOOKUP
	BSF	ADDRESS,1		; ADD 2 TO BASE ADDRESS
	MOVFW	SER_2			; GET LOWER 16 BIT OF SERIAL NUMBER
	MOVWF	TMP1
	MOVFW	SER_3
	MOVWF	TMP2
	CALL	EEWRITE			; ... AND WRITE TO EEPROM
	
	MOVFW	SER_0			; GET UPPER 16 BIT OF SERIAL NUMBER
	MOVWF	TMP1
	MOVFW	SER_1
	MOVWF	TMP2
	CALL	EEWRITE			; ... AND WRITE TO EEPROM

; *** DECRYPT HOP CODE ***

LEARN_DEC
	CALL	DECRYPT			; DECRYPTION ROUTINE

; *** CHECK DISCRIMINATION VALUE ***

LEARN_CHK
	MOVFW	SER_3			; CHECK LOWER BYTE OF SERIAL NUMBER
	XORWF	CODE1,W			; AGAINST DISCRIMINATION VALUE
	BZ	LEARN_UP		; UPDATE LEARN POINTER
	GOTO	CANCEL_LEARN		; ERROR CANCEL LEARN MODE

; ********* UPDATE LEARN POINTER **********
LEARN_UP
	CALL	TX_LOOKUP		; GET CURRENT TX BASE ADDRESS
	CALL	LOAD_CNT_VALS
	CALL	EEWRITE			; WRITE LSB WORD OF COUNTER TO EEPROM

	BTFSC	FLAGS,RELEARN		; IF RELEARN
	GOTO	BYPASS_POINTER_WRITE	; DONT UPDATE POINTER

	INCF	TXNUM,F			; INCREMENT LEARN POINTER	       
	MOVLW	MAX_USERS     		; ALLOW 0 .. MAX_USERS - 1
	SUBWF	TXNUM,W			
	MOVLW	0H			; IF MAX WRAP TO 0
	BTFSS	STATUS,C
	MOVF	TXNUM,W			; ELSE USE TXNUM
	MOVWF	TMP1			; FOR WRITE OPERATION

	CLRF	TMP2			; CLEAR LOWER BYTE
	
	MOVLW	LRNPTR			; POINT TO LEARN POINTER
	MOVWF	ADDRESS
	CALL	EEWRITE			; UPDATE LEARN POINTER IN EEPROM

BYPASS_POINTER_WRITE

	BSF	PORTA,LED		; LED ON TO INDICATE VALID LEARN

	CLRF	CNT_LW			; CLEAR COUNTER LOW BYTE

SUCCESS
	CALL	TST_RTCC		; INDICATE SUCCESSFUL LEARN
	BTFSS	CNT_LW,4		; LED ON FOR 0.5 SEC
	GOTO	SUCCESS			; LOOP BACK

CANCEL_LEARN
	BCF	FLAGS,LRNF		; CLEAR LEARN FLAG
	BCF	FLAGS,RELEARN		; CLEAR RELEARN FLAG
	GOTO	M_LOOP			; RETURN TO MAIN LOOP - LED OFF

;===========================================================================
; END OF FILE : SIMDEC10.ASM
;===========================================================================

	ORG	1FFH
	GOTO	RESET
	END


