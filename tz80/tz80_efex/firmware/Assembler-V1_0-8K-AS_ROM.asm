; EfexMon By M.PEKER v1.0b
; 	ported to RetroAssembler by E. Kocalar
;
; ROM START: $0000
; ROM END  : $1FFF
;
; RAM START: $8000
; RAM END  : $FFFF
;
; STACK	   : $F800
;
; SYSTEM VARIABLES:
;		$F900-$F910
;	 	$FF00-$FFFF

; I/O:
; UART8251:  00H
; BAUDRATE: 19200 KBS


;-------------------------------------------------
;Z80 DISASSEMBLER LISTING
;Label  Instruction
;-------------------------------------------------

	.TARGET "Z80"

	; Comma separated 0xAA format for arduino code.
	.setting "OutputFileType", "TXT"
	.setting "OutputTxtAddressFormatFirst", "#### 0x{0:X02} ####\n"
	.setting "OutputTxtAddressFormatNext", " "
	.setting "OutputTxtValueFormat", "0x{0:X02}"
	.setting "OutputTxtValueSeparator", ","
	.setting "OutputTxtLineSeparator", ",\n"


;VERSION HISTORY 

;AFTER DDCB COMMANDS EXCLUDED
;FILL ADDED, DISASSEMBLER NOTFOUNT RESULT IMPROVED
;ASSEMBLER HAVE LIMITED BACKSPACE
;HEX INPUT IMPROVED


;INTLIN1 TURNED INTO SUBROUTINE
;S-AVE, L-OAD, E-DIT,R-UN,M-OVE COMMANDS ADDED
;EFEX INLINE ASSEMBLER V.087 - 06.APR.2017

;SYSTEM VARIABLES:
;3F60-3F6F  :COMMAND INPUT BUFFER			;COMINBUF
;3FA0-3FA1  :COMMAND LINE LENGHT TO BE TRANSLATED	;LINELENGHT
;3F80-3F90  :CODE BUFFER-----				;CODEBUF
;3FA2-3FA3  :MNEMONIC TABLE FFINDED INDEX ADRESS	;TABFINDAD
;3FA4-3FA5  :ASSEMBLY ADRESS				;ASADR
;3FA6-3FA7  :ASSEMBLY ADRES + CODES TO WRITE MEMORY	;ASADCODE
;3FB0	    :OPERAND BYTE COUNT				;OPBYTECNT
;3FB2	    : # OR $ OR NULL				;DIYEZDOLAR
;3F42       :# CONTENT (DATA)				;DATAINP
;3F43-3F44  :$ CONTENT (ADRESS)				;ADRSINP
;3FB3-3FB4  :CODE BUF. LENGHT				;CODEBUFLEN
;
;
;ASSEMBLER VARIABLES FOR ROM:
COMINBUF 	.EQU $FF60    ;10H CHAR LENGHT
CODEBUF 	.EQU $FF80	;10H CHAR LENGHT
LINELENGHT 	.EQU $FFA0	;2 BYTE
TABFINDAD 	.EQU $FFA2	;2 BYTE
ASADR 		.EQU $FFA4		;2 BYTE
ASADCODE 	.EQU $FFA6	;2 BYTE
OPBYTECNT 	.EQU $FFB0	;1 BYTE
DIYEZDOLAR 	.EQU $FFB2	;1 BYTE
DATAINP 	.EQU $FF42	;1 BYTE
ADRSINP 	.EQU $FF43	;2 BYTE
CODEBUFLEN 	.EQU $FFB3	;2 BYTE

KEYINBUF 	.EQU $FF20	;4 BYTE
KEYINRES 	.EQU $FF40	;4 BYTE
	
;HEX RECORD VARIABLES FOR ROM
HEXLDREG 	.EQU $FF4B	;2 BYTE
LOADSTADR 	.EQU $FF50	;2 BYTE
SAVECHCK 	.EQU $FF34	;2 BYTE
LOWNIBBLE 	.EQU $FF32	;1 BYTE
HIGHNIBBLE 	.EQU $FF33	;1 BYTE
;EDIT ADRESS
EDITADR 	.EQU $F906
;INTERRUPT (IM1, 0038) ADRESS POINTER
INTADRS 	.EQU $F908  ;INT ADRESS POINTER
;INTADRES +2: 090A : NMI POINTER
;STACK POINTER;
STACKPOINT 	.EQU $F7FD	;2 BYTE ; UNCOMMENT THIS TO RUN IN ROM

	

;-------------------------------------------------
;4 mhz clock,1834 uart clock (DIVIDE BY 16),  8k rom, 8k ram
;PORT 00:UART data, port 01 control/status
;PORT 08:8255    08 input,  09 and 0A output
;
		.org $0000    ;CHANGE 0000 RO RUN IN ROM!
		
		LD SP,STACKPOINT  ; STACK AT THE END OF  RAM
		LD HL,MA_IN	  ;DEFAULT INTERUPT ROUTINE IS MA_IN PROGRAM
		LD (INTADRS),HL
		IM 1
		EI
		;DI		;DEFAULT: INTERRUPTS DISABLED
	
	
;		JP GREET       ; TURN TO COMMENT TO RUN IN ROM


;----------------INIT-8251----------------------------------


INIT8255:
		; LD A,$90
		; OUT ($0B),A
INIT8251:	

		; LD A,$40            
		; OUT ($01),A  
		; NOP
		; NOP  
		; LD A,$40            
		; OUT ($01),A
		; NOP
		; NOP  
					
		; LD A,$40            
		; OUT ($01),A  ; WORST CASE INIT
		; NOP
		; NOP
		
		
		
		; LD A,$40            
		; OUT ($01),A  		; RESET 8251
		; NOP
		; NOP

		LD A,$4D            ; ERTURK changed from 4E to 4D
		OUT ($01),A      	 ; 8-N-1  CLK/1  4EH FOR /16, 4D FOR /1  (MODE )
		NOP
		NOP    
		LD A,$37            
		OUT ($01),A      	 ; RESET ALL ERROR FLAGS AND ENABLE RXRDY,TXRDY (COMMAND)

		JP GREET
;-----------------------------------------------------------------------------------
;   UNCOMMENT THIS TO RUN IN ROM

		; ERTURK
		.storage $0038-*,$00	; zero until interrupt

		.ORG $0038               ;CHANGEABLE INTERRUPT SUBROUTINE
		LD HL,(INTADRS)
		JP (HL)
	
;-------------------------------------------------------------------------------------
	
;TXD ROUTINE sends contents of A REGISTER  to serial out pin 
;19200 BAUD, 8-N-1


TXD:    PUSH AF
LOPTX: 	IN A,($01)
		AND $01     ;TXRDY?
		JP Z, LOPTX
		POP AF
		OUT ($00),A
		RET
	
;----------------------------------------------------------------------------------
;RXD ROUTINE receives 1 bayt from serial  to A REGISTER 
;19200 BAUD, 8-N-1

RXD:    
		LD A,$37
		OUT ($01),A ;ENABLE TX AND RX AND CLEAR ERR BITS
	
LOPTR: 	IN A,($01)
		AND $02     ;TXRDY?
		JP Z, LOPTR
		IN A,($00)   ;RECEIVE CHAR
		RET
	
	
;-----------------------------------------------------------------------------------
;   UNCOMMENT THIS TO RUN IN ROM

		; ERTURK
		.storage $0066-*,$00	; zero until interrupt

		.ORG $0066               ;CHANGEABLE NMI INTERRUPT SUBROUTINE
		LD HL,(INTADRS+2)
		JP (HL)
	
;-------------------------------------------------------------------------------------	
	
	
	
		
;----------------GREETING MESSAGE----------------------


GREET:
			 ;GREETING  MSG
		LD HL,TABLE
		LD B,57   ; DECIMAL IF NOT H AT THE END
		CALL PRINT
	

;------------------------MAIN PROGRAM---------------------

MA_IN  	CALL PROMPT
		CALL RXD
		CP 'S'
		CALL Z, SAVEX		;SAVE IHEX FILE
		CP 'L'
		JP Z,LOADERZ		;LOAD IHEX FILE
		CP 'A'
		JP Z,ASSEMBLE		;ASSEMBLER
		CP 'G'
		JP Z,RUN_ADR		;GO TO ADRESS
		CP 'E'
		JP Z,EDIT		;EDIT ADRESS
		CP 'M'
		JP Z, MOVE		;MOVE MEMORY BLOCKS
		CP 'H'
		JP Z, HELP		;HELP SUBROUTINE
		CP 'W'
		JP Z, GREET 		;RESTART
		CP 'U'
		JP Z, USEFUL		;USEFUL ROUTINES
		CP 'D'
		JP Z, DISASSEMBLER
		CP 'F'
		JP Z, FILL
		CP 'X'
		JP Z, HEXDUMP		;DUMP MEMORY CONTENT

		LD A, $0A
		CALL TXD
		LD A, $0D
		CALL TXD
		JP MA_IN		;MAIN LOOP OF MONITOR PROGRAM
	
PROMPT:	LD HL,TABLE6
		LD B,6   ; DECIMAL IF NOT H AT THE END
		CALL PRINT
		RET


	

;----------------HELP-------------------------
HELP:	             ;HELP MSG
		LD HL,TABLE21
		LD BC,110   ; DECIMAL IF NOT H AT THE END
DIS21:	LD A,(HL)
		CALL TXD
		INC HL
		DEC BC
		LD A,B
		OR C
		JR NZ,DIS21
		
		
		JP MA_IN
	

	
;-------------------USEFUL ROUTINES-----------
USEFUL:	             ;HELP MSG


		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD
		
		
		; LD HL,TABLEH9
		; LD B,23
		; CALL PRINT
	
			
		LD HL,TABLE22
		LD B,14   
		CALL PRINT
	
	
		


HELP1:	LD HL,TXD
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
		
		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD
		


		LD HL,TABLEH1
		LD B,14
		CALL PRINT
				

		
		LD HL,RXD
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
		
		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD
			
		LD HL,TABLEH2
		LD B,14	
		
		CALL PRINT

	
		LD HL,BYTEIN2
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
		
		LD HL,TABLEH3
		LD B,15
		CALL PRINT
		
		LD HL,TABLEH4
		LD B,14
		CALL PRINT
		
		LD HL,BYTEIN1
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT

		LD HL,TABLEH5
		LD B,10
		CALL PRINT
		
		LD HL,TABLEH6
		LD B,14
		CALL PRINT
		
		LD HL,HEXOUT
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
		
		LD HL,TABLEH7
		LD B,12
		CALL PRINT	
		
		LD HL,TABLEH8
		LD B,14
		CALL PRINT
	
		LD HL,MA_IN
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
		
		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD
	
	
	
		LD HL,TABLEH10
		LD B,14
		CALL PRINT
		
		LD HL,DE_LAY
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT

		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD
	
	
		JP MA_IN
	
	
;--------------DELAY 500MS---------------	
DE_LAY:	
		PUSH DE
		LD DE,$0010		; WAS $8000.  TOO SLOW FOR RETROSHIELD
DISDELAY:
		DEC DE
		LD A,D
		OR E
		JR NZ,DISDELAY
		POP DE
		RET
;--------------------------------------		
	
;---------PRINT SUBROUTINE-------------

	
PRINT:	LD A,(HL)
		CALL TXD
		INC HL
		DJNZ PRINT
		RET
;--------------------------------------	

	

;-------------HEXDUMP--------------------------
;HEXDUMP OF INPUTTED MEMORY- +FFH

HEXDUMP:
		LD A,'X'
		CALL TXD
		LD A,'-'
		CALL TXD 
		LD A, '$'
		CALL TXD
		LD A, '?'
		CALL TXD
		LD A, $08
		CALL TXD ; DISPLAY 4 CHAR INPUT PROMPT
		
	
	
;       LD HL, KEYINBUF
;		LD B,4
;DISX1:	CALL RXD
;		CP $1B
;		JP Z, MA_IN
;		LD (HL), A
;		INC HL
;		CALL TXD
;		DJNZ DISX1	;INPUT 4 CHAR
;		CALL INTLINR	;EXTRACT ADRESS

		CALL BYTEIN2	;4 CHAR INPUT, RESULT IN (ADRSINP)
	
	
		LD HL,(ADRSINP) 	
DONGUY:	LD DE,$000F		;SHOW 16 LINES
DONGUX:	
		LD A,$0D		;ENTER
		CALL TXD 
		LD A,$0A
		CALL TXD

		LD A,H 			;PRINT ADRESS AND :
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
		LD A,':'
		CALL TXD
		LD A,' '
		CALL TXD 
		LD A,' '
		CALL TXD 
	
		LD B,8		;FIRST 8 BYTE
DUMBP:	LD A,(HL)
		CALL HEXOUT
		LD A,' '
		CALL TXD 
		INC HL
		DJNZ DUMBP
		
		LD A,' '
		CALL TXD
		LD A,' '
		CALL TXD
		LD A,' '
		CALL TXD
			
		LD B,8		;SECOND 8 BYTE
DUMBP2:	LD A,(HL)
		CALL HEXOUT
		LD A,' '
		CALL TXD 
		INC HL
		DJNZ DUMBP2

		DEC DE
		LD A,D
		OR E
		JP NZ, DONGUX
	
CIKIS:	CALL RXD
		CP $1B
		JP Z,MA_IN		;ESC : EXIT TO MAIN MENU
		CP $0D
		JP Z,DONGUY		;ENTER OR SPACE CONT. TO LISTING
		CP $20
		JP Z,DONGUY
		JP CIKIS
	


;---------------efex-ASSEMBLER---v0.87beta-STARTS HERE---------------
;                                                                    |
;                      A  S  S  E  M  B  L  E  R                     |
;                                                                    |
;                       BACKSPACE WORKS IN TEXT                      |
;                     NO BACKSPACE AFTER # OR $                      |
;                         SYNTAX CHECK ADDED                         |
;                                                                    |
;--------------------------------------------------------------------
;INPUT ASSEMBLER ADRESS-------

ASSEMBLE:
		LD A,0		
		LD (OPBYTECNT),A	;OPERAND BYTE COUNT RESET
		LD A,0
		LD (DIYEZDOLAR),A	;#,$,NULL RESET AS NULL

ASS_ADR:
		LD A,'A'       ;ASSEMBLY START ADRESS
		CALL TXD
		LD A,'-'
		CALL TXD 
		LD A, '$'
		CALL TXD
		LD A, '?'
		CALL TXD
		LD A, $08
		CALL TXD ; DISPLAY 4 CHAR INPUT PROMPT
	
		CALL BYTEIN2
	
		LD HL, (ADRSINP)
		LD (ASADR),HL
		
		
		LD HL,TABLE_AS ;ASSEMBLER MESSAGE
		LD B,14   
		CALL PRINT
		
	
		LD A, $0D
		CALL TXD
		LD A, $0A
		CALL TXD
		
	
;---------------main assembler loop start here------------	
	
AS_DON:	LD A, $0A
		CALL TXD
AS_DON2:
		LD A, $0D
		CALL TXD
	
		LD HL,(ASADR)	;ASSEMBLY ADRESS
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
	
		LD A, ' '
		CALL TXD
		LD A, ' '
		CALL TXD
	
	


	
		LD BC,$0001
		LD (LINELENGHT),BC;     ;CLEAR LENGHT REG

		CALL CLRBUF         ;CLEAR INPUT BUFFERS
		LD HL,COMINBUF
		LD B,$0F
DIS32:	CALL RXD
		CP $0D
		JP Z,BITTI         ;ENTER BASILDIYSA BITIR
		CP $1B
		JP Z,MA_IN         ;ESC BASILDIYSA CIK
		CP $08
		JP Z,HATALI
	
	
		CALL TXD         ;PRINT CHAR

		CP '#'
		CALL Z,BYTEINP1
		CP '$'
		CALL Z,BYTEINP2
		LD (HL),A
		INC HL
		DJNZ DIS32  ;GET COMMAND TO BUFFER 16 CHAR  LENGHT, TILL CR
	
	
HATALI:	LD A,$08
		CALL TXD
		LD A,' '
		CALL TXD
		LD A,$08
		CALL TXD
		DEC HL
		INC B
		JP DIS32
	
;       ---------------------------	
BITTI: 	LD A,$0F         
		SUB B
		LD (LINELENGHT), A   	;SAVE INPUT REGISTER LENGHT TO BC
								;TO LINELENGHT-3FA1 AND EXIT FROM INPUT
								;ALL CODE TAKEN INTO INPUT REG., LENGHT IN LINELENGHT-3FA1H
		LD A,$00
		LD (LINELENGHT + 1), A    
		
		
		JP INTERPRET	;JUMP TO INTERPRETER
	

	
;--------LINE INPUT FINISHED HERE----- 
;------------------------------------------------------------------------
;            	                                                            |
;	RESULT: Mnemonic string in COMINBUF (INPUT BUFFER)                      |
;           Mnemonic lenght in LINELENGHT  (for use Register BC)            |
;           if operand=$: result in ADRSINP-FF43H FF44h                     |
;	        if operand=#: result in DATAINP-FF42                            |
;		                                                                    |
;-------------------------------------------------------------------------	
	
		 
;---------------INTERPRETER STARTS HERE--------------------------
;Interpreter translates input buffer mnemonics to machine code
;
;            SYSTEM VARIABLES OF INTERPRETER
;
;
;FF60-FF6F  :COMMAND INPUT BUFFER
;FFA0-FFA1  :COMMAND LINE LENGHT TO BE TRANSLATED
;FF80-FF90  :CODE BUFFER----
;FFA2-FFA3  :MNEMONIC TABLE FFINDED INDEX ADRESS
;FFA4-FFA5  :ASSEMBLY ADRESS
;FFA6-FFA7  :ASSEMBLY ADRES + CODES TO WRITE MEMORY
;FFB0	    :OPERAND BYTE COUNT
;FFB2	    : # OR $ OR NULL
;FF42       :# CONTENT (DATA)
;FF43-FF44  :$ CONTENT (ADRESS)
;FFB3-FFB4  :CODE BUF. LENGHT	

INTERPRET:		;ASSEMBLER INTERPRETER
		CALL FINDCOM	;FIND MNEMONIC FROM TABLE
	
		LD A,' '
		CALL TXD
		LD A,' '
		CALL TXD
		
	
	
		LD DE,CODEBUF	;CODE BUFFER
		LD HL,(TABFINDAD) 	;MNEMONIC ADRESS FROM TABLE (HOLDS BYTE COUNT AT THE MOMENT)
			
		
		LD A,(HL)	;OPERAND COUNT
		LD B,A
		LD C,0 	; CODE COUNT RESET

	
		INC HL		;HL AT FIRST OPERAND ADRESS(COMMAND)
DISIN:	LD A,(HL) 	;TAKE COMMAND 
		LD (DE),A	;WRITE TO CODE BUFFER
		INC HL
		INC DE
		INC C
		DJNZ DISIN
		
		LD A,(DIYEZDOLAR)
		CP '#'
		CALL Z, DIYEZ1
		CP '$'
		CALL Z, DOLLAR1
		
		LD A,C
		LD (CODEBUFLEN),A    ;CODE LENGHT
		

		LD A,(DIYEZDOLAR)  	;JUST OUTPUT COMPOSER TO GOOD VIEW
		CP 0
		JP NZ, UZUN
		LD A,' '
		CALL TXD	
		LD A,' '
		CALL TXD
		LD A,$09
		CALL TXD

UZUN:	LD A,' '
		CALL TXD
		LD A,$09
		CALL TXD

	
		
	
	
	
	
		LD HL,CODEBUF
		LD B,C
		LD A,' '
		CALL TXD 
		LD A,':'
		CALL TXD 
		
ISTEBU:	LD A,(HL)
		CALL HEXOUT
		LD A,' '
		CALL TXD
		INC HL
		DJNZ ISTEBU
		
	
	
;------LINE ASSEMLY COMPLETED HERE 

		LD HL,(ASADR)    
		LD (ASADCODE),HL	
		LD B,0
		ADD HL,BC
		LD (ASADR),HL
		
	
	
	
YAZIM:	LD A,(CODEBUFLEN)   	;;WRITE ASSEMBLY LINE CODES FROM CODE BUFFER TO MEMORY
		LD B,A		;CODE LENGHT

	
		LD HL,(ASADCODE)  ; ASSEMBLY LINE START ADRESS
		LD DE,CODEBUF	;CODE BUFFER START ADRESS
DISYAZ:	LD A,(DE)
		LD (HL),A
		INC HL
		INC DE
		DJNZ DISYAZ    ;WRITE ASSEMBLY LINE CODES TO MEMORY
	
	
	
	
		JP AS_DON	;GO TO NEXT ASSEMBLY LINE
		;JP MA_IN
	
DIYEZ1: 	
		LD A,(DATAINP)	;CHANGE # CHAR TO OPERAND BYTE
		LD (DE),A
		INC DE
		INC C
		RET
	
DOLLAR1:
	
		LD A,(ADRSINP)   ;CHANGE $ CHAR TO DOUBLE OPERAND BYTE
		LD (DE),A
		INC DE
		INC C
		LD A,(ADRSINP+1)
		LD (DE),A
		INC DE
		INC C
		RET
	
	
	


BYTEINP1:
		LD (DIYEZDOLAR),A
		CALL BYTEIN1 ;AFTER#
		RET
	
BYTEINP2:
		LD (DIYEZDOLAR),A
		CALL BYTEIN2 ;AFTER$
		RET



CLRBUF:	LD HL,COMINBUF
		LD B,$0F
DIS30:	LD A,$00
		LD (HL),A
		INC HL
		DJNZ DIS30  ;CLEAR INPUT BUFFER
	
	
		LD HL,CODEBUF
		LD B,$0F
DISCB:	LD A,$00
		LD (HL),A
		INC HL
		DJNZ DISCB  ;CLEAR CODE BUFFER
	
		LD A,0
		LD (LINELENGHT),A	;CLEAR ALL COUNTER BUFFERS
		LD (LINELENGHT+1),A
		LD (OPBYTECNT),A
		LD (DIYEZDOLAR),A
		LD (CODEBUFLEN),A
		LD (CODEBUFLEN+1),A
	
	
		RET
	
	

TABLE_AS:
		.byte $0A,$0D
		.byte "Assembler:"
		.byte $0A,$0D
	

; THIS ROUTINE INSPIRED FROM NAIVE STRING MATCHING ALGORITHM!!

FINDCOM:		;SEARCH UTIL OF INTERPRETER 
		PUSH AF
		PUSH HL
		PUSH DE
		PUSH BC 

		LD HL,TABLECOD   ;SEARCH AND FIND MNEMONIC TABLE ADRESS INDEX
		LD (TABFINDAD),HL
LOOPF:	LD HL,(TABFINDAD)
		LD DE, COMINBUF
		LD BC,(LINELENGHT)
		
LOOPC:	LD A,(DE)
		CP (HL)
		JP NZ, NOTFOUND
		INC HL
		INC DE
		DEC BC
		LD A, B
		OR C
		JP NZ,LOOPC
	
		JP FOUND
	
NOTFOUND:		;IF STRING NOT FOUND INCREASE TABLE SEARCH ADRESS
		LD HL,(TABFINDAD)	;THIS IS NAIVE STRING MATCHING ALGORITHM
		INC HL
	     ;THIS CODE ADDED FOR TABLE END CONTROL	

		PUSH HL			;;TABLE END CONTROL FOR SYNTAX ERROR
		PUSH DE
	
		LD HL,CODEND
		LD DE,(TABFINDAD)
		OR A     ;CLEAR CARRY FLAG
		SBC HL,DE
		JP Z,ENDCONTROL
	
		POP DE
		POP HL

	
	
		;THIS CODE ADDED FOR TABLE END CONTROL	
		LD (TABFINDAD),HL
		JP LOOPF       ;IF NOT CONTINUE SEARCH
	

FOUND:	LD (TABFINDAD),HL     ;FINDED ADRESS IN TABLE
		POP BC
		POP DE
		POP HL
		POP AF
		RET
	
ENDCONTROL:		
		LD A,$0D
		CALL TXD
		LD A,$0A
		CALL TXD
		LD B,14
		LD HL,ERROR
DISERR:	LD A,(HL)
		CALL TXD
		INC HL
		DJNZ DISERR
		POP DE
		POP HL
	
		JP AS_DON
	
ERROR:	.byte "Syntax "
		.byte "error !"
	
;--INTERPRETER ENDED

;---------efex-ASSEMBLER FINISHED HERE--------------------------------------



;-----------------efex DISASSEMBLER-START-HERE----------------------------------
;
;FFC0H :TOTBYTECNT   ;TOTAL BYTE COUNT OF LINE
;FFC2H :DISCODELEN   ;TABLE FINDED COMMAND BYTE LENGHT 1,2,3,OR 4..
;FFC4H :DISTOTLEN    ;COMMAND TOTAL LENGHT WITH OPERAND
;FFC6H :NULDOLNUM    ;IF THE OPERAND NULL, BYTE OR WORD(1 BYTE-2 BYTE) # OR DOLLAR
;FFD0H :DISADDR	     ;DISSASEMBLING ADRESS
;FFD2H :DISFINDAD    ;DISASEMBLER FINDED CODE ADRESS
;FFD4  :MNESTAD	     ;MNEMONIC START ADRESS IN TABLE 
;FFD6  :MNENDAD	     ;MNEMONIC END ADRESS IN TABLE
;FFDAH :MNELEN       ;MNEMONIC LENGHT
;F900H :NEXTCODE     ;NEXT CODE START ADRESS IN DISSASEMBLE SECTOR !!!!FFDC CALISMADI!!!!
;F902H :SECTORC      ;DISASEMBLING  LINE COUNT
;FFD8H :OPERAND      ;# OR $ OPERAND IN COMMAND LINE
;FFE0H :OPCNT        ;OPERAND COUNT (#,$ : 0,1 OR 2)
;3F80-3F90  :CODEBUF         ;CODE BUFFER-----				

DISASSEMBLER:

TOTBYTECNT 	.EQU $FFC0
DISADDR 	.EQU $FFD0
DISFINDAD 	.EQU $FFD2
DISCODELEN 	.EQU $FFC2
DISTOTLEN 	.EQU $FFC4
MNESTAD 	.EQU $FFD4
MNENDAD 	.EQU $FFD6
OPERAND 	.EQU $FFD8
MNELEN 		.EQU $FFDA
NEXTCODE 	.EQU $F900
SECTORC 	.EQU $F902
OPCNT 		.EQU $FFE0


	
	
		LD HL,TABLE_DS ;DISASSEMBLER MESSAGE
		LD B,24   
DISDS:	LD A,(HL)
		CALL TXD
		INC HL
		DJNZ DISDS
		JP CONTDS
	
TABLE_DS:
		.byte $0A,$0D
		.byte "Disassembly "
		.byte "listing:"
		.byte $0A,$0D
	
	
CONTDS:
		LD A,0
		LD (LINELENGHT),A	;CLEAR ALL COUNTER BUFFERS
		LD (LINELENGHT+1),A
		LD (OPBYTECNT),A
		LD (DIYEZDOLAR),A
		LD (CODEBUFLEN),A
		LD (CODEBUFLEN+1),A
		LD (TOTBYTECNT),A
		LD (DISCODELEN),A
		LD (OPCNT),A
		LD (NEXTCODE),A
		LD (NEXTCODE +1),A
	
;---Disasembling adress input---
ASKDIS: LD A,'D'
		CALL TXD
		LD A,'-'
		CALL TXD 
		LD A, '$'
		CALL TXD
		LD A, '?'
		CALL TXD
		LD A, $08
		CALL TXD ; DISPLAY 4 CHAR INPUT PROMPT
	
		CALL BYTEIN2
	
		LD HL,(ADRSINP) ; 3F43 STORES RESULT ADRESS
		LD A, ':'
		CALL TXD
		
		LD HL,(ADRSINP)   ;GIRILEN ADRESS
		LD (NEXTCODE),HL	;NEXTCODE IS INCREASE LOOP ADRESS FOR DISASSEMBLER
;----------ADRESS INPUT COMPLETED HERE---

DONDISZ:
		LD A,16			;16 LINES SHOWING PER PROCESS
		LD (SECTORC),A
		
DONDISY:
		LD A,0
		LD (LINELENGHT),A	;CLEAR ALL COUNTER BUFFERS
		LD (LINELENGHT+1),A
		LD (OPBYTECNT),A
		LD (DIYEZDOLAR),A
		LD (CODEBUFLEN),A
		LD (CODEBUFLEN+1),A
		LD (TOTBYTECNT),A
		LD (DISCODELEN),A
		LD (OPCNT),A
		

DONDISX:
		LD HL,(NEXTCODE)				;MAIN LOOP FOR DISASEMBLY LINES
		LD (DISADDR),HL        
												
		LD HL,1
		LD (LINELENGHT),HL
		LD HL,TABLECOD
		LD DE,(DISADDR)
			
DONDIS:	LD A,(DE)
		CP $ED
		JP Z,AFTER		;IF AFTER ED,CB,DD,FD COMMANDS 
		CP $CB
		JP Z,AFTER
		CP $DD
		JP Z,AFTER
		CP $FD
		JP Z,AFTER

		CP (HL)
		JP Z,CHECKINDEX     ;JP Z,FOUNDDIS
		INC HL
DVM1:	JP DONDIS
	
	
CHECKINDEX:      ;CHECK IF $FF AFTER CODE?
		INC HL 
		LD A,$FF
		CP (HL)
		JP NZ,DVM1 ;NO INDEX--->CONT TO SEARC
		DEC HL     ;INDEX FOUND, DEC HL TO COMMAND'S ADRESS
		JP FOUNDDIS
		
	;----AFTER DD DE,EE,FB,.. COMMANDS PROCESS START HERE---
AFTER: 

		LD HL,AFTERCOD   ;SEARCH AND FIND MNEMONIC TABLE ADRESS INDEX
		LD (TABFINDAD),HL
LOOPFD:	LD HL,(TABFINDAD)
		LD DE, (DISADDR)
		LD BC,2         ;(LINELENGHT)
		
LOOPCD:	LD A,(DE)
		CP (HL)
		JP NZ, NOTFOUNDD
		INC HL
		INC DE
		DEC BC
		LD A, B
		OR C
		JP NZ,LOOPCD
	
		JP FOUNDD
	
NOTFOUNDD:		;IF STRING NOT FOUND INCREASE TABLE SEARCH ADRESS
		LD HL,(TABFINDAD)	;THIS IS NAIVE STRING MATCHING ALGORITHM
		INC HL
		
     ;THIS CODE ADDED FOR TABLE END CONTROL	

		PUSH HL			;;TABLE END CONTROL FOR SYNTAX ERROR
		PUSH DE
		
		LD HL,CODEND
		LD DE,(TABFINDAD)
		OR A     ;CLEAR CARRY FLAG
		SBC HL,DE
		JP Z,ENDCONTROLD
		
		POP DE
		POP HL

	
	
	     ;THIS CODE ADDED FOR TABLE END CONTROL	
	
		LD (TABFINDAD),HL
		JP LOOPFD       ;IF NOT CONTINUE SEARCH
		
ENDCONTROLD:		;UNKNOWN CODE ROUTINE; PRINT *** AND GOTO NEXT ADRESS

		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD

		LD HL,(DISADDR)
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
		LD A,' '
		CALL TXD
		LD A,' '
		CALL TXD		
		LD A,'*'
		CALL TXD
		LD A,'*'
		CALL TXD
		LD A,'*'
		CALL TXD

	
		INC HL
		INC HL
		LD (NEXTCODE),HL
		JP DONDISX
	

	

FOUNDD:	LD HL,(TABFINDAD)
	
		LD (DISFINDAD),HL

	
	
	

;------AFTER DD DE EE FB.. COMMANDS PROCESS END HERE

	
FOUNDDIS:		;ANYWAY (AFTER OR SINGLE) COMMAND FOUND	
		;LD  HL,(TABFINDAD)

		LD  (DISFINDAD),HL

		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD
		

		LD HL,(DISFINDAD) 	;FINDED CODE FIRST BYTE
		DEC HL
		LD A,(HL)
		LD (DISCODELEN),A   	;CODE BYTE LENGHT
		DEC HL
		LD (MNENDAD),HL		;MNEMONIC END ADRESS
		
DIS45:	DEC HL
		LD A,(HL)
		CP '_'
		JR NZ, DIS45
		INC HL
		LD (MNESTAD),HL		;MNEMONIC START ADRESS IN TABLE
		LD A,(DISCODELEN)
		LD B,A
		LD HL,(DISADDR)
DIS51:	INC HL
		DJNZ DIS51
		
	
						;HL HOLDS OPERAND FIRST BYTE HERE
		LD (OPERAND),HL	 ;OPERAND1: IF #; FIRST BYTE, IF $; LOW AND HIGH BYTES IN ORDER
		
		
	
DISPROC:		;WRITES DISASEMBLED CODE TO CODE BUFFER

		LD A,$0D
		CALL TXD
		LD A,$0D
		CALL TXD
		
		; BURADA MNEMONIC LENGHT IN HESAPLANMASI GEREKIYOR
		LD HL,(MNESTAD)
		LD D,H
		LD E,L
		LD HL,(MNENDAD)
		OR A
		SBC HL,DE
		LD (MNELEN),HL
		
		LD A,(MNELEN)	;AT LAST ITS 1 BYTE AND STORED IN L
		

		LD HL,(DISADDR)
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
		LD A,' '
		CALL TXD
		LD A,' '
		CALL TXD
			
		
	
		LD A,(MNELEN)	;AT LAST ITS 1 BYTE AND STORED IN L
		LD HL,(MNESTAD)
		LD B,A	;(MNELEN)
		INC B
DIS46:	LD A,(HL)
		CP '#'
		JP Z,DISDIYEZ
		CP '$'
		JP Z,DISDOLAR
		CALL TXD
DIS50:	INC HL
		DJNZ DIS46
		

	


		LD HL,(NEXTCODE)
		LD A,(DISCODELEN) ;CODE LENGHT
		LD B,A
		LD A,(OPCNT)	;OPERAND COUND
		ADD A,B
		LD DE,0
		LD E,A
		ADD HL,DE
		LD (NEXTCODE),HL
		
	
	
		LD A,(SECTORC)
		DEC A
		JP Z,DONE    	;JP Z,MA_IN
		LD (SECTORC),A

		JP DONDISY
		;JP MA_IN		;EXIT POINT FROM DISASSEMBLER
	
DONE:	CALL RXD
		CP $1B
		JP Z,MA_IN
		JP DONDISZ
		JP DONE	

		
	
DISDIYEZ:
		LD A,1
		LD (OPCNT),A
		LD A,'#'
		CALL TXD
		PUSH HL
		LD HL,(OPERAND)
		LD A,(HL)
		CALL HEXOUT
		POP HL
		JP DIS50
	
DISDOLAR:
		LD A,2
		LD (OPCNT),A
		LD A,'$'
		CALL TXD
		PUSH HL
		LD HL,(OPERAND)
		INC HL
		LD A,(HL)
		CALL HEXOUT
		DEC HL
		LD A,(HL)
		CALL HEXOUT
		POP HL
		JP DIS50
	
				

;--------------DISASSEMBLER FINISHED HERE
	


;------------------------------------MOVE---------------------------------

MOVE: 		


		CALL MOVE_SR     ;HL HOLDS SOURCE
		PUSH HL
		CALL MOVE_DT     ;DE HOLDS TARGET
		PUSH DE
		CALL MOVE_LNT    ;BC HOLDS LENGHT
	
		POP DE
		POP HL
		
	
LOP15:	LD A,(HL)      ;BLOCK COPY SUBROUTINE
		LD (DE),A
		INC HL
		INC DE
		DEC BC
		LD A,B
		OR C
		JP NZ, LOP15
	
		LD HL, TABLE14   ;MOVE COMPLETE MSG
		LD B,19   
		CALL PRINT

	
		JP MA_IN
	
	
MOVE_SR:
		LD HL,TBLMVSR	;  DISPLAY 4 CHAR INPUT PROMPT
		LD B,17
		CALL PRINT
		CALL BYTEIN2
		LD HL,(ADRSINP) ;HL HOLDS SOURCE ADRESS
		RET


MOVE_DT:
		LD HL,TBLMVDT
		LD B,18
		CALL PRINT
		CALL BYTEIN2	;2 BYTE INPUT
		LD HL, (ADRSINP)
		EX DE,HL     ;DE HOLDS TARGET ADRESS
		RET
	
	
MOVE_LNT:
		LD HL,TBLMVLN
		LD B,12
		CALL PRINT
		CALL BYTEIN2	;2 BYTE INPUT
		LD HL, (ADRSINP)  
		LD B,H
		LD C,L          ;BC HOLDS BLOCK LENGHT 
		RET

TBLMVSR:
		.byte $0A,$0D
		.byte "Move Source "
		.byte "$?",$08

	
TBLMVDT:
		.byte 020,$20
		.byte "Destination  "
		.byte "$?",$08
	
TBLMVLN:
		.byte 020,$20
		.byte "Lenght "
		.byte "$?",$08

TABLE14:
		.byte $0A,$0D 
		.byte "Move "
		.byte "complete !"
		.byte $0A,$0D
	

;--------------MOVE END

;------------------------------------FILL---------------------------------

FILL: 		


		CALL FILL_SR     ;HL HOLDS START ADR
		PUSH HL
		CALL FILL_DT     ;DE HOLDS LENGHT
		PUSH DE
		CALL FILL_BYTE
			
		POP DE
		POP HL
	
	
LOP15F:	LD A,C	;FILL SUBROUTINE
		LD (HL),A      
		INC HL
		DEC DE
		LD A,D
		OR E
		JP NZ, LOP15F
	
		LD HL, TABLE14F   ;MOVE COMPLETE MSG
		LD B,19   
		CALL PRINT

	
		JP MA_IN
	
	
FILL_SR:
		LD HL,TBLFLSR	;  DISPLAY 4 CHAR INPUT PROMPT
		LD B,17
		CALL PRINT
		CALL BYTEIN2
		LD HL,(ADRSINP) ;HL HOLDS SOURCE ADRESS
		RET


FILL_DT:
		LD HL,TBLFLDT
		LD B,18
		CALL PRINT
		CALL BYTEIN2	;2 BYTE INPUT
		LD HL, (ADRSINP)
		EX DE,HL     ;DE HOLDS TARGET ADRESS
		RET
	
FILL_BYTE:
		LD HL,TBLFLBY
		LD B,18
		CALL PRINT
		CALL BYTEIN1	;1 BYTE INPUT
		LD A, (DATAINP) ;C HOLDS VALUE TO FILL WITH
		LD C,A
		RET


TBLFLSR:
		.byte $0A,$0D      ;
		.byte "Start adr. :"
		.byte "$?",$08

	
TBLFLDT:
		.byte 020,$20     ;
		.byte "Lenght       "
		.byte "$?",$08
	
TBLFLBY:
		.byte 020,$20     ;
		.byte "Fill with    "
		.byte "#?",$08
	


TABLE14F:
		.byte $0A,$0D 
		.byte "Fill "
		.byte "complete !"
		.byte $0A,$0D
	

;--------------FILL END


	
;-----------------SAVE-----------------------
;HL: START ADRESS, DE:END ADRESS TO SAVE	

SAVEX: 		


		CALL SAVE_ADR1
		PUSH HL
		
		CALL SAVE_ADR2
		POP HL
		
       	CALL INTSAVE
       	JP MA_IN
	

SAVE_ADR1:
		LD HL,TBLSV1
		LD B,11
		CALL PRINT

		CALL BYTEIN2
		LD HL,(ADRSINP)
		RET

SAVE_ADR2:
		LD HL,TBLSV2
		LD B,11
		CALL PRINT
		
		CALL BYTEIN2
		LD DE,0
		LD HL, (ADRSINP)
		EX DE,HL     ;DE HOLDS END ADRESS
		RET
	
TBLSV1:	.byte $0A,$0D
		.byte "S-Start "
		.byte "$?",$08
	
TBLSV2:	.byte $0A,$0D
		.byte "S-End   "
		.byte "$?",$08
	
;-------------save end----------------

;------------------INPUT--------------------------------
;INPUT DONT CHANGES ANY REGISTER!!!
;1 BYTE RESULT AT: DATAINP
;2 BYTE RESULT AT: ADRSINP-3F44H


BYTEIN2:
		PUSH AF
		PUSH HL
		PUSH BC
		PUSH DE 
		LD HL, KEYINBUF  ;4 CHAR ADRESS INPUT
		LD B,4
DIS25:	CALL RXD
		CP $1B
		JP Z, MA_IN
		JP CHECKHEX    ;CHECK IF A VALID HEX CHAR
HEXCON2:
		LD (HL), A
		INC HL
		CALL TXD  ;PRINT NIBBLE
		DJNZ DIS25  ;GET 4 NIBBLE FROM KEYINBUF TO 3F23H
		CALL INTLINR  ;  
		LD HL,(KEYINRES)
		LD (ADRSINP),HL ; TWO BYTES ADRESS AT 3F43(High), AND 3F44(Low)
		POP DE 
		POP BC
		POP HL
		POP AF
		RET
		
	
BYTEIN1:
		PUSH AF
		PUSH HL
		PUSH BC
		PUSH DE
		LD HL, KEYINBUF + 2 ;2 CHAR DATA INPUT
		LD B,2
DIS26:	CALL RXD
		CP $1B
		JP Z, MA_IN
		JP CHECKHEX2
	
HEXCON3:

		LD (HL), A
		INC HL
		CALL TXD   ;PRINT NIBBLE
		DJNZ DIS26
		CALL INLIN2  
		LD A,(KEYINRES)
		LD (DATAINP),A ;1 BYTE INPUT: RESULT IN 3F42

		POP DE 
		POP BC
		POP HL
		POP AF
		RET
	
	
;---------------------------------	
;-------------------------1 BYTE CHECK IF HEX------	
CHECKHEX2:	;CHECK IF INPUT IS A REAL HEX VALUE FOR 1 BYTE INPUT
		PUSH HL
		PUSH AF
		PUSH BC
		LD HL, TABLEX   ;HEX CHAR TABLE
		LD B,16
DONHEXX2:
		CP (HL)
		JP Z,OKHEX2	;FINDED A VALID HEX CHAR, RETURN TO CONTINUE
		INC HL
		DJNZ DONHEXX2
	
NOTHEX2: POP BC
		POP AF
		POP HL
		JP DIS26
		
	
OKHEX2:
		POP BC
		POP AF
		POP HL
		JP HEXCON3	;CONTINUE TO WRITE INPUT PROCESS
;--1 BYTE CHECK FINISHED
	
CHECKHEX:	;CHECK IF INPUT IS A REAL HEX VALUE FOR 2 BYTE INPUT
		PUSH HL
		PUSH AF
		PUSH BC
		LD HL, TABLEX   ;HEX CHAR TABLE
		LD B,16
DONHEXX:
		CP (HL)
		JP Z,OKHEX	;FINDED A VALID HEX CHAR, RETURN TO CONTINUE
		INC HL
		DJNZ DONHEXX
	
NOTHEX: POP BC
		POP AF
		POP HL
		JP DIS25
	
	
OKHEX: 	POP BC
		POP AF
		POP HL
		JP HEXCON2	;CONTINUE TO WRITE INPUT PROCESS
;--2 BYTE CHECK FINISHED
	
	
	
	
;--------------------EDIT------------------------------
	
EDIT:  	LD HL,TABLEDIT 	;EDIT MESSAGE
		LD B,14
		CALL PRINT
	
		
	
		CALL BYTEIN2   ;GET ADRESS TO EDIT
		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD
		LD HL,(ADRSINP)
		LD (EDITADR),HL

DONEDIT:
		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD
		LD A,'E'
		CALL TXD
		LD A,'-'
		CALL TXD


	
		LD HL,(EDITADR)	;PRINT INPUT ADRESS
		LD A,H
		CALL HEXOUT 	
		LD A,L
		CALL HEXOUT
	
		LD A,':'
		CALL TXD
		LD A,' '
		CALL TXD
	
		LD A,(HL)
		CALL HEXOUT  	;PRINT EDITING ADRESS CONTENT
	 
		LD A,$08
		CALL TXD
		LD A,$08
		CALL TXD	;CURSOR 2 CHAR BACK
	

	
		CALL BYTEIN1
		CALL DE_LAY
	
		LD A,(DATAINP)
		LD HL,(EDITADR)
		LD (HL),A
	
EDITNEXT:	
		INC HL
		LD (EDITADR),HL
		JP DONEDIT
	
 	
	
		JP EDITNEXT	
	
	
	
		



		
		
TABLEDIT:
		.byte "Edit memory :"
		.byte "$"	  


;------------------GO TO ADRESS-(RUN)----------------------

	
	
RUN_ADR:
		LD A,'G'
		CALL TXD
		LD A,'-'
		CALL TXD 
		LD A, '$'
		CALL TXD
		LD A, '?'
		CALL TXD
		LD A, $08
		CALL TXD ; DISPLAY 4 CHAR INPUT PROMPT
		CALL BYTEIN2
		LD HL, (ADRSINP)
		JP (HL)
	
	

;----------------INPUT HEX TO BYTE CONVERTER 2 BYTE OR 1 BYTE---------
INTLINR:                   ;4 NIBBLE  INPUT   
		LD HL, KEYINBUF -1 ; 
		LD A,(HL)
		CALL BYTERDR 
		LD (KEYINRES + 1),A 
	
INLIN2:	LD HL, KEYINBUF + 1       ;2 NIBBLE INPUT
		LD A,(HL)
		CALL BYTERDR 
		LD (KEYINRES),A 
		RET
	

BYTERDR:
		
		LD	D,$00		;Set up   ;	* Get 2 ASCII chrs as hex byte	*
		CALL HEXCONR		;Get byte and convert to hex
		ADD	A,A		;First nibble so
		ADD	A,A		;multiply by 16
		ADD	A,A		;
		ADD	A,A		;
		LD	D,A		;Save hi nibble in D
HEXCONR:
	
		INC HL                ;HL:FF21
		
		LD A, (HL)
			
		;CALL	RXD		;Get next chr
		SUB	$30		;Makes '0'-'9' equal 0-9
		CP	$0A		;Is it 0-9 ?
		JR	C,NALPHAR	;If so miss next bit
		SUB	$07		;Else convert alpha
NALPHAR:	
		OR	D		;Add hi nibble back
		RET			;RESULT STORED IN A REGISTER!



;---------------LOAD HEX FILE ROUTINE

LOADERZ:
	
	
		LD HL,TABLE25         ;LOADING.. MSG
		LD B,15   ; DECIMAL IF NOT H AT THE END
		CALL PRINT	
	
		CALL INTLIN1
		
	
LOAD_ED:	              ; FILE LOADED MESAGE
		LD HL,TABLE2
		LD B, 15
		CALL PRINT
		
		LD A,'$'
		CALL TXD
		
		LD HL,(LOADSTADR)  ;DOWNLOADED FILE START ADRESS
		LD A,H
		CALL HEXOUT
		LD A,L
		CALL HEXOUT

		LD A,$0A
		CALL TXD
		LD A,$0D
		CALL TXD
		LD A,$07
		CALL TXD
	
		JP MA_IN
	
	
		
;	*********************************
;	*				*
;	*     Get Intel hex record	*
;	*				*
;	*********************************

;Short version - no checksum calculation.

INTLIN1:	
		LD A,$00
		LD (HEXLDREG),A
INTLIN:	CALL	RXD		;Get chr
		CALL TXD		; Erturk DEBUG
		CP  $1B
		RET Z
		CP	':'		;Is it ':'?
		JR	NZ,INTLIN	;If not then next
		CALL	BYTERD		;Get record length
		LD	B,A		;Put in B
		CALL	BYTERD		;Get record address hi byte
		LD	H,A		;Put in H
		CALL	BYTERD		;Get record address lo byte
		LD	L,A		;Put in L
	
		LD A,(HEXLDREG)		;CHECK IF HL RECORDED TO DISPLAY SOURCE ADRESS BEFORE?
		CP $01                   ;IF NOT, RECORD IT. OTHERWISE GO ON
		JP Z,GO_ON
		LD A,$01
		LD (HEXLDREG),A
		LD (LOADSTADR),HL	; LOADED PROGRAM START ADRESS HEADER REGISTER
	
GO_ON:	CALL BYTERD		;Record type(NOT IGNORED IN EFEX MON)
		CP $01                   ;IF END OF FILE THEN EXIT PROGRAM
		RET Z          ;JP Z,LOAD_ED        PROGRAM ENDED RETURN TO HOME
	
	
DATAIN:	CALL	BYTERD		;Get record data byte
		LD	(HL),A		;Save byte to memory
		INC	HL		;Next address
		DJNZ	DATAIN		;Decrement count and jump if not finished
		JR	INTLIN		;Ignore checksum byte and [CR][LF]
	
		RET		;PROGRAM ENDED RETURN HOME

BYTERD:	LD	D,$00		;Set up   ;	* Get 2 ASCII chrs as hex byte	*
		CALL	HEXCON		;Get byte and convert to hex
		ADD	A,A		;First nibble so
		ADD	A,A		;multiply by 16
		ADD	A,A		;
		ADD	A,A		;
		LD	D,A		;Save hi nibble in D
HEXCON:	CALL	RXD		;Get next chr
		SUB	$30		;Makes '0'-'9' equal 0-9
		CP	$0A		;Is it 0-9 ?
		JR	C,NALPHA	;If so miss next bit
		SUB	$07		;Else convert alpha
NALPHA:	OR	D		;Add hi nibble back
		RET			;

;-------------------------Hex load finished-----------------

;--------------------------INTEL HEX SAVE ROUTINE
;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
;INTEL HEX SAVE PROGRAM         ;
;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
;	LD HL,START ADRESS
;	LD DE, END ADRESS
	
INTSAVE:
		PUSH HL
		EX DE,HL
		SBC HL,DE
		EX DE,HL
		POP HL
		LD A,$00
		LD (SAVECHCK),A	;RESET CHECKSUM COUNTER
		LD B,$10
		
		LD A,$0D		;ENTER
		CALL TXD ;TXD ROUTINE
		LD A,$0A
		CALL TXD ;TXD ROUTINE
		
COMP:	LD A,D	; DE TEK BAYTA INMIS
		CP 0
		JP Z, MINUS
		JP DONGU
	
MINUS:	LD A,E      ;E 10H TAN KUCUKSE..
		SUB $10
		JP C,MINIMUS
		JP DONGU
	
MINIMUS: LD B,E    ;DE 10H TAN AZ
		JP DONGU1 
	
DONGU:	LD B,$10
DONGU1:	LD A,':'
		CALL TXD ;TXD ROUTINE		;SEND START CODE
		LD A,B
		CALL HEXOUT		;SEND BYTE COUNT (DEFAULT 16)
	
		LD A,H 			;SEND RECORD ADRESS
		CALL HEXOUT
		LD A,L
		CALL HEXOUT
	
		LD A,0 			;SEND RECORD TYPE (0=DATA)
		CALL HEXOUT
	
		CALL YAZ
		LD A,D		;DE BYTE COUNT REACHED?
		OR E
		JP NZ, COMP
	
		LD A,':'		;ENDING COLON
		CALL TXD ;TXD ROUTINE		
		LD B,$07
DISEND:	LD A,'0'
		CALL TXD ;TXD ROUTINE
		DJNZ DISEND
		LD A,'1'
		CALL TXD ;TXD ROUTINE
		LD A,$FF
		CALL HEXOUT
	
		RET      ;PROGRAM ENDED    CALL RE_START	RESET DISPLAYS
				;JP MA_IN	;TURN INTO ROM

	
	
	
	
YAZ:	LD A,(HL)
		CALL HEXOUT
		INC HL
		DEC DE
		DJNZ YAZ		;16 BYTES SENDED
		LD A, $FF		;SEND FAKE CHECKSUM
		CALL HEXOUT
	
		LD A,$0D		;ENTER
		CALL TXD ;TXD ROUTINE
		LD A,$0A
		CALL TXD ;TXD ROUTINE
		RET
		
;------------------------------SAVE FINISHED




;----------------------HEXOUT--------------------------------------------
		
	
	
;HEXOUT DO NOT CHANGES ANY REGISTER	
HEXOUT:	PUSH BC ; THIS SUBROUTINE SENDS CONTENTS OF ACC TO TERMINAL AS 
		PUSH DE ; TWO CHAR HEX VALUE (ASCII) 
		PUSH HL
		PUSH AF
		
		AND $F0
		RRA
		RRA
		RRA
		RRA
		LD (HIGHNIBBLE),A  ;HIGH NIBBLE SYSTEM VARIABLE
		CALL HEXAS
	
		POP AF
		PUSH AF
		AND $0F
		LD (LOWNIBBLE),A  ;LOW NIBBLE SYSTEM VARIABLE
		CALL HEXAS
	
		POP AF
		POP HL
		POP DE
		POP BC
	
		RET
	
HEXAS:	LD HL, TABLEX ; HEX NIBBLE TO ASCII CONVERTER
		LD  B, 0	;ADDING HL WITH A
		LD  C, A
		ADC HL, BC
		LD A,(HL)
		CALL TXD ;TXD ROUTINE
		RET	
TABLEX:	.byte '0','1','2','3','4','5','6','7'
		.byte '8','9','A','B','C','D','E','F'
	

;HEXOUT DO NOT CHANGES ANY REGISTER

TABLE28:
		.byte $0A,$0D
		.byte "ENTER AD:"
TABLE29:
		.byte $0A,$0D
		.byte "ENTER DT:"
	
TABLE: 	.byte $0C,$0D
		.byte "EfexMon "
		.byte "By M.PEKER "
		.byte "v1.0b"

		.byte $0A,$0D
		.byte "Press H "
		.byte "for help"
		.byte $0A,$0D
        .byte $0A,$0D 
		.byte "Ready."
		.byte $0A,$0D
		.byte $07
	
	
TABLE13:
		.byte $0A,$0D,$07
		.byte "Press "
		.byte "any key "
		.byte "to send !"
		.byte $0A,$0D
	
	

	
TABLE2: .byte $0D 
		.byte "loaded "
		.byte "adress:"

TABLE25: 
		.byte $0D
		.byte "Hex Loading"
		.byte "..."
        
		
	
	
TABLE6:	.byte $0A,$0D
		.byte "C:\>"
	
TABLE21:
		.byte $0A,$0D

		.byte "A-"
		.byte "Assembler"
		.byte $0A,$0D
	
	
		.byte "D-"
		.byte "Disassembler"
		.byte $0A,$0D
	
	
		.byte "L-Load"

		.byte $0A,$0D
	

		.byte "S-Save"

		.byte $0A,$0D
	

		.byte "E-Edit"

		.byte $0A,$0D
		
		
		.byte "W-Warmst"

		.byte $0A,$0D
		
		
		.byte "M-Move"
		.byte $0A,$0D
		
		
		.byte "X-Hexdump"
		.byte $0A,$0D
		
		
			
		.byte "G-Go"
		.byte $0A,$0D
		
		.byte "F-Fill"
		.byte $0A,$0D
		
		
		.byte "U-Routines"
	
		.byte $0A,$0D
		
		
TABLEH10:	
		.byte "DELAY  (S):  $"
		

	
TABLEH8:	
		.byte "PROMPT (R):  $"
		
TABLEH7:
		
		.byte " A -> UART"
		.byte $0A,$0D
	
TABLEH6:
		
		.byte "HEXOUT (S):  $"
		
	
	
TABLEH5:
		
		.byte " -> FF42"
		.byte $0A,$0D
		
	
TABLEH4:	
		.byte "BYTEIN1(S):  $"

TABLEH3:	
		
		
		.byte " -> FF43-FF44"
		.byte $0A,$0D

TABLEH2:            ;
		.byte "BYTEIN2(S):  $"	
	
TABLEH1:
		.byte "RXD    (S):  $"	
	
TABLE22:

	
		.byte "TXD    (S):  $"
	
	
;--ASSEMBLER AND DISASSEMBLER OPERATES ON SAME TABLE
;
;        
;INSTRUCTION , VIRGUL, CODE COUNT,MACHINE CODE,OPERAND #-$-NULL, TOTAL BYTE COUNT 
;2CH VIRGUL DEMEK
;BU ASSEMBLER .byte DE VIRGUL KABUL ETMIYOR!!!

	
TABLECOD:

		
		.byte "_ADC A",$2C,"(HL)",1,$8E,$FF

		.byte "_ADC A",$2C,'A',1,$8F,$FF	;$FF IS NULL INDEX CODE TO FIND  COMMAND 
		.byte "_ADC A",$2C,'B',1,$88,$FF	;'_' IS INDEX CHAR TO FIND MNEMONIC
		.byte "_ADC A",$2C,'C',1,$89,$FF
		.byte "_ADC A",$2C,'D',1,$8A,$FF
		.byte "_ADC A",$2C,'E',1,$8B,$FF
		.byte "_ADC A",$2C,'H',1,$8C,$FF
		.byte "_ADC A",$2C,'L',1,$8D,$FF
		.byte "_ADC A",$2C,'#',1,$CE,$FF

	
		.byte "_ADD A",$2C,"(HL)",1,$86,$FF

		.byte "_ADD A",$2C,'A',1,$87,$FF
		.byte "_ADD A",$2C,'B',1,$80,$FF
		.byte "_ADD A",$2C,'C',1,$81,$FF
		.byte "_ADD A",$2C,'D',1,$82,$FF
		.byte "_ADD A",$2C,'E',1,$83,$FF
		.byte "_ADD A",$2C,'H',1,$84,$FF
		.byte "_ADD A",$2C,'L',1,$85,$FF
		.byte "_ADD A",$2C,'#',1,$C6,$FF
		.byte "_ADD HL",$2C,"BC",1,$09,$FF
		.byte "_ADD HL",$2C,"DE",1,$19,$FF
		.byte "_ADD HL",$2C,"HL",1,$29,$FF
		.byte "_ADD HL",$2C,"SP",1,$39,$FF

	
		.byte "_AND (HL)",1,$A6,$FF

		.byte "_AND A",1,$A7,$FF
		.byte "_AND B",1,$A0,$FF
		.byte "_AND C",1,$A1,$FF
		.byte "_AND D",1,$A2,$FF
		.byte "_AND E",1,$A3,$FF
		.byte "_AND H",1,$A4,$FF
		.byte "_AND L",1,$A5,$FF
		.byte "_AND #",1,$E6,$FF
		

		
		.byte "_CALL C",$2C,'$',1,$DC,$FF
		.byte "_CALL M",$2C,'$',1,$FC,$FF
		.byte "_CALL NC",$2C,'$',1,$D4,$FF
		.byte "_CALL NZ",$2C,'$',1,$C4,$FF
		.byte "_CALL P",$2C,'$',1,$F4,$FF
		.byte "_CALL PE",$2C,'$',1,$EC,$FF
		.byte "_CALL PO",$2C,'$',1,$E4,$FF
		.byte "_CALL Z",$2C,'$',1,$CC,$FF
		.byte "_CALL $",1,$CD,$FF
		
		.byte "_CCF",1,$3F,$FF
		
		.byte "_CP (HL)",1,$BE,$FF

		.byte "_CP A",1,$BF,$FF
		.byte "_CP B",1,$B8,$FF
		.byte "_CP C",1,$B9,$FF
		.byte "_CP D",1,$BA,$FF
		.byte "_CP E",1,$BB,$FF
		.byte "_CP H",1,$BC,$FF
		.byte "_CP L",1,$BD,$FF
		.byte "_CP #",1,$FE,$FF
		


		.byte "_CPL",1,$2F,$FF
		
		.byte "_DAA",1,$27,$FF
		
		.byte "_DEC (HL)",1,$35,$FF

		.byte "_DEC A",1,$3D,$FF
		.byte "_DEC B",1,$05,$FF
		.byte "_DEC BC",1,$0B,$FF
		.byte "_DEC C",1,$0D,$FF
		.byte "_DEC D",1,$15,$FF
		.byte "_DEC DE",1,$1B,$FF
		.byte "_DEC E",1,$1D,$FF
		.byte "_DEC H",1,$25,$FF
		.byte "_DEC HL",1,$2B,$FF

		.byte "_DEC L",1,$2D,$FF
		.byte "_DEC SP",1,$3B,$FF
		.byte "_DI",1,$F3,$FF
		.byte "_DJNZ #",1,$10,$FF
		
		.byte "_EI",1,$FB,$FF
		.byte "_EX (SP)",$2C,"HL",1,$E3,$FF
		.byte "_EX AF",$2C,"AF",1,$08,$FF
		.byte "_EX DE",$2C,"HL",1,$EB,$FF
		.byte "_EXX",1,$D9,$FF

		.byte "_HALT",1,$76,$FF
		

		

		
		.byte "_IN A",$2C,"(#)",1,$DB,$FF
		

		.byte "_INC (HL)",1,$34,$FF

		.byte "_INC A",1,$3C,$FF
		.byte "_INC B",1,$04,$FF
		.byte "_INC BC",1,$03,$FF
		.byte "_INC C",1,$0C,$FF
		.byte "_INC D",1,$14,$FF
		.byte "_INC DE",1,$13,$FF
		.byte "_INC E",1,$1C,$FF
		.byte "_INC H",1,$24,$FF
		.byte "_INC HL",1,$23,$FF

		.byte "_INC L",1,$2C,$FF
		.byte "_INC SP",1,$33,$FF
		
		.byte "_JR C",$2C,'#',1,$38,$FF
		.byte "_JR NC",$2C,'#',1,$30,$FF
		.byte "_JR NZ",$2C,'#',1,$20,$FF
		.byte "_JR Z",$2C,'#',1,$28,$FF
		.byte "_JR #",1,$18,$FF	   

		

		.byte "_JP (HL)",1,$E9,$FF

		.byte "_JP C",$2C,'$',1,$DA,$FF
		.byte "_JP M",$2C,'$',1,$FA,$FF
		.byte "_JP NC",$2C,'$',1,$D2,$FF
		.byte "_JP NZ",$2C,'$',1,$C2,$FF
		.byte "_JP P",$2C,'$',1,$F2,$FF
		.byte "_JP PE",$2C,'$',1,$EA,$FF
		.byte "_JP PO",$2C,'$',1,$E2,$FF
		.byte "_JP Z",$2C,'$',1,$CA,$FF
		.byte "_JP $",1,$C3,$FF
		

		
		.byte "_LD (BC)",$2C,'A',1,$02,$FF
		.byte "_LD (DE)",$2C,'A',1,$12,$FF
		.byte "_LD (HL)",$2C,'A',1,$77,$FF
		.byte "_LD (HL)",$2C,'B',1,$70,$FF
		.byte "_LD (HL)",$2C,'C',1,$71,$FF
		.byte "_LD (HL)",$2C,'D',1,$72,$FF
		.byte "_LD (HL)",$2C,'E',1,$73,$FF
		.byte "_LD (HL)",$2C,'H',1,$74,$FF
		.byte "_LD (HL)",$2C,'L',1,$75,$FF
		.byte "_LD (HL)",$2C,'#',1,$36,$FF

		.byte "_LD ($)",$2C,'A',1,$32,$FF
		.byte "_LD ($)",$2C,"HL",1,$22,$FF
		
		
		.byte "_LD A",$2C,"(BC)",1,$0A,$FF
		.byte "_LD A",$2C,"(DE)",1,$1A,$FF
		.byte "_LD A",$2C,"(HL)",1,$7E,$FF

		.byte "_LD A",$2C,'A',1,$7F,$FF
		.byte "_LD A",$2C,'B',1,$78,$FF
		.byte "_LD A",$2C,'C',1,$79,$FF
		.byte "_LD A",$2C,'D',1,$7A,$FF
		.byte "_LD A",$2C,'E',1,$7B,$FF
		.byte "_LD A",$2C,'H',1,$7C,$FF
		.byte "_LD A",$2C,'L',1,$7D,$FF
		.byte "_LD A",$2C,"($)",1,$3A,$FF
		.byte "_LD A",$2C,'#',1,$3E,$FF             
		.byte "_LD B",$2C,"(HL)",1,$46,$FF
		.byte "_LD B",$2C,'A',1,$47,$FF
		.byte "_LD B",$2C,'B',1,$40,$FF
		.byte "_LD B",$2C,'C',1,$41,$FF
		.byte "_LD B",$2C,'D',1,$42,$FF
		.byte "_LD B",$2C,'E',1,$43,$FF
		.byte "_LD B",$2C,'H',1,$44,$FF
		.byte "_LD B",$2C,'L',1,$45,$FF
		.byte "_LD B",$2C,'#',1,$06,$FF
		.byte "_LD BC",$2C,'$',1,$01,$FF
		.byte "_LD C",$2C,"(HL)",1,$4E,$FF
		.byte "_LD C",$2C,'A',1,$4F,$FF
		.byte "_LD C",$2C,'B',1,$48,$FF
		.byte "_LD C",$2C,'C',1,$49,$FF
		.byte "_LD C",$2C,'D',1,$4A,$FF
		.byte "_LD C",$2C,'E',1,$4B,$FF
		.byte "_LD C",$2C,'H',1,$4C,$FF
		.byte "_LD C",$2C,'L',1,$4D,$FF
		.byte "_LD C",$2C,'#',1,$0E,$FF
		.byte "_LD D",$2C,"(HL)",1,$56,$FF
		.byte "_LD D",$2C,'A',1,$57,$FF
		.byte "_LD D",$2C,'B',1,$50,$FF
		.byte "_LD D",$2C,'C',1,$51,$FF
		.byte "_LD D",$2C,'D',1,$52,$FF
		.byte "_LD D",$2C,'E',1,$53,$FF
		.byte "_LD D",$2C,'H',1,$54,$FF
		.byte "_LD D",$2C,'L',1,$55,$FF
		.byte "_LD D",$2C,'#',1,$16,$FF
		.byte "_LD DE",$2C,'$',1,$11,$FF
		.byte "_LD E",$2C,"(HL)",1,$5E,$FF
		.byte "_LD E",$2C,'A',1,$5F,$FF
		.byte "_LD E",$2C,'B',1,$58,$FF
		.byte "_LD E",$2C,'C',1,$59,$FF
		.byte "_LD E",$2C,'D',1,$5A,$FF
		.byte "_LD E",$2C,'E',1,$5B,$FF
		.byte "_LD E",$2C,'H',1,$5C,$FF
		.byte "_LD E",$2C,'L',1,$5D,$FF
		.byte "_LD E",$2C,'#',1,$1E,$FF
		.byte "_LD H",$2C,"(HL)",1,$66,$FF
		.byte "_LD H",$2C,'A',1,$67,$FF
		.byte "_LD H",$2C,'B',1,$60,$FF
		.byte "_LD H",$2C,'C',1,$61,$FF
		.byte "_LD H",$2C,'D',1,$62,$FF
		.byte "_LD H",$2C,'E',1,$63,$FF
		.byte "_LD H",$2C,'H',1,$64,$FF
		.byte "_LD H",$2C,'L',1,$65,$FF
		.byte "_LD H",$2C,'#',1,$26,$FF
		.byte "_LD HL",$2C,"($)",1,$2A,$FF
		.byte "_LD HL",$2C,'$',1,$21,$FF
		.byte "_LD L",$2C,"(HL)",1,$6E,$FF
		.byte "_LD L",$2C,'A',1,$6F,$FF
		.byte "_LD L",$2C,'B',1,$68,$FF
		.byte "_LD L",$2C,'C',1,$69,$FF
		.byte "_LD L",$2C,'D',1,$6A,$FF
		.byte "_LD L",$2C,'E',1,$6B,$FF
		.byte "_LD L",$2C,'H',1,$6C,$FF
		.byte "_LD L",$2C,'L',1,$6D,$FF
		.byte "_LD L",$2C,'#',1,$2E,$FF
		.byte "_LD SP",$2C,'$',1,$31,$FF
		.byte "_LD SP",$2C,"HL",1,$F9,$FF
	
	
			



	

		.byte "_NOP",1,$00,$FF
	
		.byte "_OR (HL)",1,$B6,$FF

		.byte "_OR A",1,$B7,$FF
		.byte "_OR B",1,$B0,$FF
		.byte "_OR C",1,$B1,$FF
		.byte "_OR D",1,$B2,$FF
		.byte "_OR E",1,$B3,$FF
		.byte "_OR H",1,$B4,$FF
		.byte "_OR L",1,$B5,$FF
		.byte "_OR #",1,$F6,$FF
		

		.byte "_OUT (#)",$2C,'A',1,$D3,$FF
		
		

		
		.byte "_POP AF",1,$F1,$FF
		.byte "_POP BC",1,$C1,$FF
		.byte "_POP DE",1,$D1,$FF
		.byte "_POP HL",1,$E1,$FF

		
		.byte "_PUSH AF",1,$F5,$FF
		.byte "_PUSH BC",1,$C5,$FF
		.byte "_PUSH DE",1,$D5,$FF
		.byte "_PUSH HL",1,$E5,$FF

		
		.byte "_RET",1,$C9,$FF
		.byte "_RET C",1,$D8,$FF
		.byte "_RET M",1,$F8,$FF
		.byte "_RET NC",1,$D0,$FF
		.byte "_RET NZ",1,$C0,$FF
		.byte "_RET P",1,$F0,$FF
		.byte "_RET PE",1,$E8,$FF
		.byte "_RET PO",1,$E0,$FF
		.byte "_RET Z",1,$C8,$FF

		.byte "_RLA",1,$17,$FF
		

		

		.byte "_RLCA",1,$07,$FF
		.byte "_RRA",1,$1F,$FF

		.byte "_RRCA",1,$0F,$FF

	
		.byte "_RST 00",1,$C7,$FF
		.byte "_RST 08",1,$CF,$FF
		.byte "_RST 10",1,$D7,$FF
		.byte "_RST 18",1,$DF,$FF
		.byte "_RST 20",1,$E7,$FF
		.byte "_RST 28",1,$EF,$FF
		.byte "_RST 30",1,$F7,$FF
		.byte "_RST 38",1,$FF,$FF
		
		.byte "_SBC A",$2C,"(HL)",1,$9E,$FF

		.byte "_SBC A",$2C,'A',1,$9F,$FF
		.byte "_SBC A",$2C,'B',1,$98,$FF
		.byte "_SBC A",$2C,'C',1,$99,$FF
		.byte "_SBC A",$2C,'D',1,$9A,$FF
		.byte "_SBC A",$2C,'E',1,$9B,$FF
		.byte "_SBC A",$2C,'H',1,$9C,$FF
		.byte "_SBC A",$2C,'L',1,$9D,$FF

		.byte "_SBC A",$2C,'#',1,$DE,$FF
		
		.byte "_SCF",1,$37,$FF
		

			

	
		.byte "_SUB (HL)",1,$96,$FF

		.byte "_SUB A",1,$97,$FF
		.byte "_SUB B",1,$90,$FF
		.byte "_SUB C",1,$91,$FF
		.byte "_SUB D",1,$92,$FF
		.byte "_SUB E",1,$93,$FF
		.byte "_SUB H",1,$94,$FF
		.byte "_SUB L",1,$95,$FF
		.byte "_SUB #",1,$D6,$FF
		
		
		.byte "_XOR (HL)",1,$AE,$FF

		.byte "_XOR A",1,$AF,$FF
		.byte "_XOR B",1,$A8,$FF
		.byte "_XOR C",1,$A9,$FF
		.byte "_XOR D",1,$AA,$FF
		.byte "_XOR E",1,$AB,$FF
		.byte "_XOR H",1,$AC,$FF
		.byte "_XOR L",1,$AD,$FF
		.byte "_XOR #",1,$EE,$FF
	
AFTERCOD:
		.byte "_ADC A",$2C,"(IX+#)",2,$DD,$8E
		.byte "_ADC A",$2C,"(IY+#)",2,$FD,$8E
		.byte "_ADC HL",$2C,"BC",2,$ED,$4A
		.byte "_ADC HL",$2C,"DE",2,$ED,$5A
		.byte "_ADC HL",$2C,"HL",2,$ED,$6A
		.byte "_ADC HL",$2C,"SP",2,$ED,$7A
		.byte "_ADD A",$2C,"(IX+#)",2,$DD,$86
		.byte "_ADD A",$2C,"(IY+#)",2,$FD,$86
		.byte "_ADD IX",$2C,"BC",2,$DD,$09
		.byte "_ADD IX",$2C,"DE",2,$DD,$19
		.byte "_ADD IX",$2C,"IX",2,$DD,$29
		.byte "_ADD IX",$2C,"SP",2,$DD,$39
		.byte "_ADD IY",$2C,"BC",2,$FD,$09
		.byte "_ADD IY",$2C,"DE",2,$FD,$19
		.byte "_ADD IY",$2C,"IY",2,$FD,$29
		.byte "_ADD IY",$2C,"SP",2,$FD,$39
		.byte "_AND (IX+#)",2,$DD,$A6
		.byte "_AND (IY+#)",2,$FD,$A6
		.byte "_BIT #",$2C,"(HL)",2,$CB,$46
		.byte "_BIT #",$2C,'A',2,$CB,$47
		.byte "_BIT #",$2C,'B',2,$CB,$40
		.byte "_BIT #",$2C,'C',2,$CB,$41
		.byte "_BIT #",$2C,'D',2,$CB,$42
		.byte "_BIT #",$2C,'E',2,$CB,$43
		.byte "_BIT #",$2C,'H',2,$CB,$44
		.byte "_BIT #",$2C,'L',2,$CB,$45
		.byte "_CP (IX+#)",2,$DD,$BE
		.byte "_CP (IY+#)",2,$FD,$BE
		.byte "_CPD",2,$ED,$A9	;BASLANGICI BENZER KOMUTLARDA TABLODA ONCE KISA OLAN OLMALI
		.byte "_CPDR",2,$ED,$B9
		.byte "_CPI",2,$ED,$A1
		.byte "_CPIR",2,$ED,$B1
		.byte "_DEC (IX+#)",2,$DD,$35
		.byte "_DEC (IY+#)",2,$FD,$35
		.byte "_DEC IX",2,$DD,$2B
		.byte "_DEC IY",2,$FD,$2B

		.byte "_EX (SP)",$2C,"IX",2,$DD,$E3
		.byte "_EX (SP)",$2C,"IY",2,$FD,$E3

		.byte "_IM0",2,$ED,$46
		.byte "_IM1",2,$ED,$56
		.byte "_IM2",2,$ED,$5E
		.byte "_IN A",$2C,"(C)",2,$ED,$78
		.byte "_IN B",$2C,"(C)",2,$ED,$40
		.byte "_IN C",$2C,"(C)",2,$ED,$48
		.byte "_IN D",$2C,"(C)",2,$ED,$50
		.byte "_IN E",$2C,"(C)",2,$ED,$58
		.byte "_IN H",$2C,"(C)",2,$ED,$60
		.byte "_IN L",$2C,"(C)",2,$ED,$68
		.byte "_INC (IX+#)",2,$DD,$34
		.byte "_INC (IY+#)",2,$FD,$34
		.byte "_IND",2,$ED,$AA
		.byte "_INDR",2,$ED,$BA
		.byte "_INI",2,$ED,$A2
		.byte "_INIR",2,$ED,$B2
		.byte "_INC IX",2,$DD,$23
		.byte "_INC IY",2,$FD,$23
		
		.byte "_JP (IX+#)",2,$DD,$E9
		.byte "_JP (IY+#)",2,$FD,$E9
		

		.byte "_LD (IX+#)",$2C,'A',2,$DD,$77
		.byte "_LD (IX+#)",$2C,'B',2,$DD,$70
		.byte "_LD (IX+#)",$2C,'C',2,$DD,$71
		.byte "_LD (IX+#)",$2C,'D',2,$DD,$72
		.byte "_LD (IX+#)",$2C,'E',2,$DD,$73
		.byte "_LD (IX+#)",$2C,'H',2,$DD,$74
		.byte "_LD (IX+#)",$2C,'L',2,$DD,$75
		.byte "_LD (IY+#)",$2C,'A',2,$FD,$77
		.byte "_LD (IY+#)",$2C,'B',2,$FD,$70
		.byte "_LD (IY+#)",$2C,'C',2,$FD,$71
		.byte "_LD (IY+#)",$2C,'D',2,$FD,$72
		.byte "_LD (IY+#)",$2C,'E',2,$FD,$73
		.byte "_LD (IY+#)",$2C,'H',2,$FD,$74
		.byte "_LD (IY+#)",$2C,'L',2,$FD,$75
		.byte "_LD ($)",$2C,"BC",2,$ED,$43
		.byte "_LD ($)",$2C,"DE",2,$ED,$53
		.byte "_LD ($)",$2C,"IX",2,$DD,$22
		.byte "_LD ($)",$2C,"IY",2,$FD,$22
		.byte "_LD ($)",$2C,"SP",2,$ED,$73
		.byte "_LD A",$2C,"(IX+#)",2,$DD,$7E
		.byte "_LD A",$2C,"(IY+#)",2,$FD,$7E
		.byte "_LD A",$2C,'I',2,$ED,$57
		.byte "_LD A",$2C,'R',2,$ED,$5F
		.byte "_LD B",$2C,"(IX+#)",2,$DD,$46
		.byte "_LD B",$2C,"(IY+#)",2,$FD,$46
		.byte "_LD BC",$2C,"($)",2,$ED,$4B
		.byte "_LD C",$2C,"(IX+#)",2,$DD,$4E
		.byte "_LD C",$2C,"(IY+#)",2,$FD,$4E
		.byte "_LD D",$2C,"(IX+#)",2,$DD,$56
		.byte "_LD D",$2C,"(IY+#)",2,$FD,$56
		.byte "_LD DE",$2C,"($)",2,$ED,$5B
		.byte "_LD E",$2C,"(IX+#)",2,$DD,$5E
		.byte "_LD E",$2C,"(IY+#)",2,$FD,$5E
		.byte "_LD H",$2C,"(IX+#)",2,$DD,$66
		.byte "_LD H",$2C,"(IY+#)",2,$FD,$66
		.byte "_LD I",$2C,'A',2,$ED,$47
		.byte "_LD IX",$2C,"($)",2,$DD,$2A
		.byte "_LD IX",$2C,'$',2,$DD,$21
		.byte "_LD IY",$2C,"($)",2,$FD,$2A
		.byte "_LD IY",$2C,'$',2,$FD,$21
		.byte "_LD L",$2C,"(IX+#)",2,$DD,$6E
		.byte "_LD L",$2C,"(IY+#)",2,$FD,$6E
		.byte "_LD R",$2C,'A',2,$ED,$4F
		.byte "_LD SP",$2C,"($)",2,$ED,$7B
		.byte "_LD SP",$2C,"IX",2,$DD,$F9
		.byte "_LD SP",$2C,"IY",2,$FD,$F9
		.byte "_LDD",2,$ED,$A8
		.byte "_LDDR",2,$ED,$B8
		.byte "_LDI",2,$ED,$A0
		.byte "_LDIR",2,$ED,$B0
		.byte "_NEG",2,$ED,$44
		.byte "_OR (IX+#)",2,$DD,$B6
		.byte "_OR (IY+#)",2,$FD,$B6
		.byte "_OTDR",2,$ED,$BB
		.byte "_OTIR",2,$ED,$B3
		
		.byte "_OUT (C)",$2C,'A',2,$ED,$79
		.byte "_OUT (C)",$2C,'B',2,$ED,$41
		.byte "_OUT (C)",$2C,'C',2,$ED,$49
		.byte "_OUT (C)",$2C,'D',2,$ED,$51
		.byte "_OUT (C)",$2C,'E',2,$ED,$59
		.byte "_OUT (C)",$2C,'H',2,$ED,$61
		.byte "_OUT (C)",$2C,'L',2,$ED,$69
		.byte "_OUTD",2,$ED,$AB
		.byte "_OUTI",2,$ED,$A3
		.byte "_POP IX",2,$DD,$E1
		.byte "_POP IY",2,$FD,$E1
		.byte "_PUSH IX",2,$DD,$E5
		.byte "_PUSH IY",2,$FD,$E5
		
		.byte "_RES #",$2C,"(HL)",2,$CB,$86
	;	.byte "_RES #",$2C,"(IX+#)",2,$DD,$CB
	;	.byte "_RES #",$2C,"(IY+#)",2,$FD,$CB
		.byte "_RES #",$2C,'A',2,$CB,$87
		.byte "_RES #",$2C,'B',2,$CB,$80
		.byte "_RES #",$2C,'C',2,$CB,$81
		.byte "_RES #",$2C,'D',2,$CB,$82
		.byte "_RES #",$2C,'E',2,$CB,$83
		.byte "_RES #",$2C,'H',2,$CB,$84
		.byte "_RES #",$2C,'L',2,$CB,$85
		.byte "_RETI",2,$ED,$4D
		.byte "_RETN",2,$ED,$45
		
		.byte "_RL (HL)",2,$CB,$16
	;	.byte "_RL (IX+#)",2,$DD,$CB
	;	.byte "_RL (IY+#)",2,$FD,$CB
		.byte "_RL A",2,$CB,$17
		.byte "_RL B",2,$CB,$10
		.byte "_RL C",2,$CB,$11
		.byte "_RL D",2,$CB,$12
		.byte "_RL E",2,$CB,$13
		.byte "_RL H",2,$CB,$14
		.byte "_RL L",2,$CB,$15
		.byte "_RLC (HL)",2,$CB,$06
	;	.byte "_RLC (IX+#)",2,$DD,$CB
	;	.byte "_RLC (IY+#)",2,$FD,$CB
		.byte "_RLC A",2,$CB,$07
		.byte "_RLC B",2,$CB,$00
		.byte "_RLC C",2,$CB,$01
		.byte "_RLC D",2,$CB,$02
		.byte "_RLC E",2,$CB,$03
		.byte "_RLC H",2,$CB,$04
		.byte "_RLC L",2,$CB,$05
		.byte "_RLD",2,$ED,$6F
		.byte "_RRD",2,$ED,$67
		.byte "_RR (HL)",2,$CB,$1E
	;	.byte "_RR (IX+#)",2,$DD,$CB
	;	.byte "_RR (IY+#)",2,$FD,$CB
		.byte "_RR A",2,$CB,$1F
		.byte "_RR B",2,$CB,$18
		.byte "_RR C",2,$CB,$19
		.byte "_RR D",2,$CB,$1A
		.byte "_RR E",2,$CB,$1B
		.byte "_RR H",2,$CB,$1C
		.byte "_RR L",2,$CB,$1D
		.byte "_RRC (HL)",2,$CB,$0E
	;	.byte "_RRC (IX+#)",2,$DD,$CB
	;	.byte "_RRC (IY+#)",2,$FD,$CB
		.byte "_RRC A",2,$CB,$0F
		.byte "_RRC B",2,$CB,$08
		.byte "_RRC C",2,$CB,$09
		.byte "_RRC D",2,$CB,$0A
		.byte "_RRC E",2,$CB,$0B
		.byte "_RRC H",2,$CB,$0C
		.byte "_RRC L",2,$CB,$0D
		
		.byte "_SBC A",$2C,"(IX+#)",2,$DD,$9E
		.byte "_SBC A",$2C,"(IY+#)",2,$FD,$9E
		.byte "_SBC HL",$2C,"BC",2,$ED,$42
		.byte "_SBC HL",$2C,"DE",2,$ED,$52
		.byte "_SBC HL",$2C,"HL",2,$ED,$62
		.byte "_SBC HL",$2C,"SP",2,$ED,$72
		.byte "_SET #",$2C,"(HL)",2,$CB,$C6
	;	.byte "_SET #",$2C,"(IX+#)",2,$DD,$CB
	;	.byte "_SET #",$2C,"(IY+#)",2,$FD,$CB
		.byte "_SET #",$2C,'A',2,$CB,$C7
		.byte "_SET #",$2C,'B',2,$CB,$C0
		.byte "_SET #",$2C,'C',2,$CB,$C1
		.byte "_SET #",$2C,'D',2,$CB,$C2
		.byte "_SET #",$2C,'E',2,$CB,$C3
		.byte "_SET #",$2C,'H',2,$CB,$C4
		.byte "_SET #",$2C,'L',2,$CB,$C5
	
		.byte "_SLA (HL)",2,$CB,$26
	;	.byte "_SLA (IX+#)",2,$DD,$CB
	;	.byte "_SLA (IY+#)",2,$FD,$CB
		.byte "_SLA A",2,$CB,$27
		.byte "_SLA B",2,$CB,$20
		.byte "_SLA C",2,$CB,$21
		.byte "_SLA D",2,$CB,$22
		.byte "_SLA E",2,$CB,$23
		.byte "_SLA H",2,$CB,$24
		.byte "_SLA L",2,$CB,$25
		.byte "_SRA (HL)",2,$CB,$2E
	;	.byte "_SRA (IX+#)",2,$DD,$CB
	;	.byte "_SRA (IY+#)",2,$FD,$CB
		.byte "_SRA A",2,$CB,$2F
		.byte "_SRA B",2,$CB,$28
		.byte "_SRA C",2,$CB,$29
		.byte "_SRA D",2,$CB,$2A
		.byte "_SRA E",2,$CB,$2B
		.byte "_SRA H",2,$CB,$2C
		.byte "_SRA L",2,$CB,$2D
		
		.byte "_SRL (HL)",2,$CB,$3E
	;	.byte "_SRL (IX+#)",2,$DD,$CB
	;	.byte "_SRL (IY+#)",2,$FD,$CB
		.byte "_SRL A",2,$CB,$3F
		.byte "_SRL B",2,$CB,$38
		.byte "_SRL C",2,$CB,$39
		.byte "_SRL D",2,$CB,$3A
		.byte "_SRL E",2,$CB,$3B
		.byte "_SRL H",2,$CB,$3C
		.byte "_SRL L",2,$CB,$3D
		.byte "_SUB (IX+#)",2,$DD,$96
		.byte "_SUB (IY+#)",2,$FD,$96

		.byte "_XOR (IX+#)",2,$DD,$AE
		.byte "_XOR (IY+#)",2,$FD,$AE

		.byte 0,0,0,0,0,0,0,0
		.byte 0,0,0,0,0,0,0,0
CODEND:	.byte 0,0,0,0,0,0,0,0
		.byte 0,0,0,0,0,0,0,0


	
	
	

	
		
		.END