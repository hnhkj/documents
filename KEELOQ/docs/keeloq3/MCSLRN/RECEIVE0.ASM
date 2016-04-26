;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; FILENAME 	: RECEIVE.ASM
; DESCRIPTION   : RECEIVE ROUTINE FOR KEELOQ PWM TRANSMITTERS
; CLOCK SPEED	: 4 MHz
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; REGISTERS USED
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; THE FOLLOWING REGISTERS NEEDS TO BE DEFINED BY THE MAIN FILE:
;
; 	FLAGS				; FLAG REGISTER
;	CNT0    			; LOOP COUNTERS
;	CNT1    	
;	CNT2    		
; 	TMP_CNT
;	CSR0       			; 66 BIT RECEIVE SHIFT REGISTER
;	CSR1    
;	CSR2    
;	CSR3    
;	CSR4    
;	CSR5    
;	CSR6    
;	CSR7    
;	CSR8
;	
; THE CALLING PROGRAM ALSO NEEDS TO INCLUDE A SUBROUTINE CALLED ROT_SHIFT
; WHICH ROTATE THE 66 BIT RECEPTION BUFFER
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; PORT AND PIN DEFINITIONS	
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
RFPORT	EQU	PORTA
RFPIN	EQU	RFIN

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; COMPILER DEFINES 
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
NBITS   EQU     66      		; MAXIMUM TRANSMISSION BIT LENGTH
MINBITS	EQU 	56			; MIN NR OF BITS-MS BITS OF SER IGNORED
MIN     EQU     560			; MINIMUM HEADER LENGTH [ๆS]

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; FLAG REGISTER BIT DEFINITIONS
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
BITIN	EQU	0H			; TEMPORY STORAGE FOR RF INCOMING BIT 
BAT_LOW	EQU	1H			; ENCODER BATTERY LOW INDICATOR
NTQ106	EQU	5H			; INDICATE NTQ106 TRANSMISSION RECEIVED

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;
; FUNCTION      : RECEIVE ()
;
; DESCRIPTION   : RECEIVE ROUTINE FOR KEELOQ PWM TRANSMITTERS
;
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

RECEIVE

;******** WAIT FOR HEADER AND CALIBRATE *******************

	BCF     FLAGS,NTQ106            ; RESET NTQ106 TRANSMISSION FLAG
	BTFSS   RFPORT,RFPIN		; INPUT LOW?
	GOTO    RMT_0                   ; YES - RECEIVE ERROR

	MOVLW   10                      ; 10 ms TIMER
	MOVWF   CNT1
RCV0
	MOVLW   200
	MOVWF   CNT0
RCV1
	BTFSS   RFPORT,RFPIN		; [2] INPUT HIGH?
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
	BTFSC   RFPORT,RFPIN		; [2][2] INPUT HIGH?
	GOTO    RCV6                    ; [0][0] YES--END CALIBRATION
	INCF	CNT0,1			; [1] INCREMENT 16BIT COUNTER	
	SKPNZ	      			; [2]
	INCF	CNT1,1			; [0]
	CLRWDT				; [1] RESET WATCH DOG TIMER
	NOP				; [1]

RCV4
	BTFSS	CNT1,3			; [1] TOO LONG?
	GOTO	RCV3  			; [2] NO--LOOP BACK
	GOTO	RMT_0 			; [0] YES--ERROR
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

RCV9					
	MOVFW	CNT0                  	; [1] and CSR processing
	MOVWF   CNT2			; [1] Refer to explanation above

RCV10
	BTFSC   RFPORT,RFPIN            ; [2] Wait for rising edge
	GOTO    RCV11                   ; [0] Edge found--Process
	CLRWDT                          ; [1] Clear watchdog Timer
	BTFSC   RFPORT,RFPIN            ; [2] Wait for Next rising edge
	GOTO    RCV11                   ; [0] Edge found--Process
	DECFSZ  CNT2,1                  ; [1] Decrement Timeout counter
	GOTO    RCV10                  ; [2] Loop Back
					; TOTAL = 8
					; RFIN CHECKED EVERY 4uS ON AVERAGE

	DECFSZ	TMP_CNT,1		; [1] ALL Te PERIODS
	GOTO	RCV9			; [2] ... NO, THEN WAIT FOR NEXT ONE
	GOTO    RMT01                   ; [0] ... YES, [0] TIMEOUT--no edge found

RCV11					
	MOVLW	3H			; [1]  SEE NOTE BELOW
	SUBWF	CNT0,W			; [1]
	MOVWF	CNT2		    	; [1]

;*************************************************************************
; 2   SETUP OF TEMP LOOP COUNTER  ( ONLY ONCE )
; 2   SETUP TE LOOP COUNTER       ( MAX 4 )
; 3   DECREMENT TEMP LOOP COUNTER ( MAX 4 )
; 4   IS THE AVERAGE PLAY BETWEEN EDGE AND EDJE BEING DETECTED IN RCV9
; 2    JUMP OUT OF RCV10 TO RCV11
; 3   FOR RCV11
; TOTAL 10 INSTRUCTIONS BETWEEN EDGE AND ENTERING DL1
; THEREFORE SUBTRACT 10/4 = 2.5 => 3 DL1 LOOPS TO COMPENSATE FOR 
;*************************************************************************

DL1
	CLRWDT                          ; [1] RESET WATCHDOG TIMER
	DECFSZ  CNT2,1                  ; [1] [2, IF SKIP]
	GOTO    DL1                     ; [2] CNT0 X 4 us

SAMPLE1
	BTFSS   RFPORT,RFPIN		; [2] INPUT HIGH?  FIRST SAMPLE
	GOTO    RMT01                   ; [0] NO--ERROR

	MOVF    CNT0,W                  ; [1] CALIBRATION COUNTER
	MOVWF   CNT2                    ; [1] (NOMINALLY 75 FOR 300 us PULSE)
	DECF    CNT2,1			; [1] SUBTRACT 2 FROM FINAL CALIB COUNTER 
	GOTO	$+1			; [2] TO COMPENATE FOR THIS
	NOP				; [1]
					; TOTAL = 8 => 1 LOOP COUNTER
DL2
	CLRWDT                          ; [1] RESET WATCHDOG TIMER
	GOTO	$+1			; [2] WAISTE TIME
	GOTO	$+1			; [2] WAISTE TIME
	DECFSZ  CNT2,1			; [1]
	GOTO    DL2                     ; [2] CNT0 X 8 us [ CNT0 x Te ]

SAMPLE2
	BCF     FLAGS,BITIN             ; [1]   CLEAR BIT POSITION
	BTFSS   RFPORT,RFPIN		; [1.5] LEAVE 0 IF LINE HIGH
	BSF     FLAGS,BITIN             ; [0.5] MAKE 1 IF LINE LOW
					; SUB TOTAL = 3 CYCLES

	CALL    ROT_SHIFT               ; [11]+[2] CSR SHIFT + CALL
	BCF	CSR8,7			; [1]
	BTFSC   FLAGS,BITIN		; [1.5]
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
; SUBTRACT 24/8 = 3 TO COMPENSATE FOR UPDATEING CSR, AND OTHER PROCESSING 
; AFTER DATA SAMPLE IS TAKEN.
;*************************************************************************

DL3
	GOTO	$+1		    	; [2] WASTE TIME
	GOTO	$+1		    	; [2] WASTE TIME
	CLRWDT                      	; [1] RESET WATCHDOG TIMER
	DECFSZ  CNT2,1              	; [1]
	GOTO    DL3                 	; [2] CNT0 X 8 us [ CNT0 X Te ]

SAMPLE3
	BTFSC   RFPORT,RFPIN        	; [2] INPUT LOW?  THIRD SAMPLE
	GOTO    RMT0                	; [0] NO--RECEIVE ERROR

	CALL    TST_RTCC            	; [11] CHECK RTCC

	DECFSZ  CNT1,1              	; [1] LAST BIT?
	GOTO    RCV8                	; [2] ... NO, GET NEXT BIT
				    	; TOTAL = 14 CYCLES

	GOTO    RMT21		    	; [2] ... YES, ALL BITS RECEIVED

RMT_0
	BSF     CNT1,4              	; [1] HEADER ERROR--FORCE COUNTER > 11

RMT0				    	; [1] HERE IF NOT ALL BITS RECEIVED OK
	DECF	CNT1,1		    	; [1] COMPENSATE FOR ROTATE BEFORE DL3

; ***** JUMP TO HERE IF NOT ALL BITS RECEIVED OK *****

RMT01					
	CALL    TST_RTCC            	; [11] CHECK RTCC

	MOVLW   11			; TEST FOR MIN NR BITS TO BE RECEIVED
	SUBWF   CNT1,W              	; IF CARRY FLAG SET (RX NOT OK)

	BTFSC   STATUS,C	    	; CARRY SET IF FORMAT INVALID
	RETLW   0                   	; HERE IF NOT ALL BITS RECEIVED OK
	BSF     FLAGS,NTQ106        	; INDICATE NTQ106 TX RECEIVED

; ***** ROTATE CSR ANOTHER 5 TIMES TO LINE-UP CSR *****

RMT21
	MOVLW	6		    	; ADDITIONAL ROTATION REQUIRED
	ADDWF	CNT1,1		    	; ADD TO WHAT LEFT IN COUNTER

RMT22
	CLRC
	CALL    ROT_SHIFT           	; ROTATE COMPLETE CSR
	DECFSZ  CNT1,1
	GOTO    RMT22

	BTFSS	FLAGS,NTQ106	    	; TEST FOR NTQ106 TRANSMISSION
	GOTO	RMT1
	CLRF    SER_0               	; ... YES, THEN CLEAR UPPER BYTE OF SN
	CLRF	CSR8

RMT1	
	BCF	FLAGS,BAT_LOW	    	; CLEAR VLOW BIT
	BTFSC	CSR8,0		    	; TEST VLOW BIT IN TRANSMISSION
	BSF	FLAGS,BAT_LOW	    	; INDICATE TX BATERY LOW BIT SET
RMT11
	BSF	PORTA,LED	    	; VALID TRANSMISSION FORMAT, LED ON
	  
RMT3
	MOVLW	0FH		    	; FORCE OPEN BUTTON CODES TO ZERO
	ANDWF	SER_0,1		    

RMT4 	CLRC			    	; VALID SERIAL NUMBER => VALID TX
 	RETLW   0                   	; RETURN WITH 0

;*************************************************************************
; End of file : RECEIVE.ASM
;*************************************************************************



