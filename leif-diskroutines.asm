;*
;* Disk routines.

READST   EQU $FFB7
SETLFS   EQU $FFBA
SETNAM   EQU $FFBD
OPEN     EQU $FFC0
CLOSE    EQU $FFC3
CHKIN    EQU $FFC6
CHKOUT   EQU $FFC9
CLRCHN   EQU $FFCC
CHRIN    EQU $FFCF
CHROUT   EQU $FFD2
LOAD     EQU $FFD5
SAVE     EQU $FFD8
STOP     EQU $FFE1
GETIN    EQU $FFE4
CLALL    EQU $FFE7

FAQ2     EQU $69
ACC      EQU FAQ2
AUX      EQU ACC+2
EXT      EQU AUX+2
BLNSW    EQU $CC
BLNON    EQU $CF
BLNCT    EQU $CD


;--------------------------------------------------------------------------
LOADADDR 
  dc.b $00,$C0       ;Load target address
SAVESTRT 
  dc.b $00,$C0       ;Beginning of block to save
SAVEEND  
  dc.b $31,$C0       ;End of block to save
FILENAMEREPLACE
  dc.b "@:"
FILENAME
  dc.b "IPCONFIG-DEFAULT",0
  dc.b 0,0


;--------------------------------------------------------------------------
;*
;* SAVEFILE, whose purpose is awfully self-evident.
;*

SAVEFILE   
  LDX #<FILENAMEREPLACE
  LDY #>FILENAMEREPLACE
  LDA #$12    ;Length - note two extra for @:
  JSR SETNAM
  
  LDA #$08   ;File no.
  LDX $BA    ;Current device number
  LDY #$01   ;Secondary address
  JSR SETLFS
  
	 ;Temporary values to save the starting address in zero-page
  LDA SAVESTRT
  STA FAQ2

  LDA SAVESTRT+1
  STA FAQ2+1

	;Save from (FAQ2) to SAVEEND
  LDX SAVEEND
  LDY SAVEEND+1
  LDA #FAQ2  ;Note #!
  JSR SAVE

  BCS ERROR
  JSR CLRCHN
  CLC
  RTS

;--------------------------------------------------------------------------
; Common error handler
;
ERROR   JSR CLALL
        JSR CLRCHN
        LDY #00
LOOP2   LDA ERTEXT,Y
        BEQ END
        JSR CHROUT
        INY
        BNE LOOP2

END     JSR GETERR
        SEC
        RTS

ERTEXT  dc.b 13
        dc.b "*** DISK ERROR ***", 0

;--------------------------------------------------------------------------
;
;* LOADFILE - remarkably similar to SAVEFILE - works!
;*
LOADFILE   
  LDX #<FILENAME
  LDY #>FILENAME
  LDA #$10    ; Length
  JSR SETNAM
  
  LDA #$08    ;File no.
  LDX $BA     ;Current device number
  LDY #$00    ;Secondary address
  JSR SETLFS

  LDA #$00    ;Load, not verify
  LDX LOADADDR
  LDY LOADADDR+1
  JSR LOAD
  BCS ERROR

  JSR CLRCHN  
  CLC
  RTS

;--------------------------------------------------------------------------
;*
;* SENDCMD sends a command to the current drive
;*
SENDCMD  
  LDA #13
  JSR CHROUT
  LDA #$00     ; '>'   TODO
  JSR CHROUT
  LDX #39
      ;   JSR INPUT   TODO
  BEQ ERRORC

  LDA #$0F
  LDX $BA
  LDY #$0F
  JSR SETLFS
  LDA #00
  JSR SETNAM
  JSR OPEN
  BCS ERRORC
  LDX #$0F
  JSR CHKOUT
  LDY #00
LOOP    ; LDA STRBUF,Y     ; TODO
  BEQ ERRORC
  JSR CHROUT
  INY
  BNE LOOP

ERRORC   JSR CLRCHN
  LDA #$0F
  JSR CLOSE
  JMP CLRCHN

;--------------------------------------------------------------------------
;*
;* GETERR prints the error message from the current disk drive.
;*
GETERR   
  LDA #13
  JSR CHROUT
;*
;* This method is a bit faster on output to screen.
;*
  LDA #$0F
  LDX $BA
  LDY #$0F
  JSR SETLFS
  LDA #00
  JSR SETNAM
  JSR OPEN
  LDX #$0F
  JSR CHKIN
LOOPy    JSR CHRIN
  CMP #$0D
  BEQ EXIT
  JSR CHROUT
  BNE LOOPy
EXIT    JSR CHROUT
  JSR CHROUT       ;One more to look nice
  LDA #15
  JSR CLOSE
  JMP CLRCHN  ; Which does an RTS

;--------------------------------------------------------------------------
;*
;* PRINTDIR reads the directory from the current device
;* and prints it to the screen.
;*
PRINTDIR 
  LDA #01   ;File no.
  LDX $BA   ;Current device number
  LDY #00   ;Secondary address
  JSR SETLFS
  LDA #1
  LDX #<DOLLAR
  LDY #>DOLLAR
  JSR SETNAM
  JSR OPEN
  LDX #01
  JSR CHKIN
  BCS ENDP  ;Error if carry set

  JSR CHRIN        ;Grab load address
  JSR CHRIN
LOOP1   LDA #13
  JSR CHROUT
  JSR CHRIN        ;Line link
  JSR CHRIN
  JSR CHRIN        ;Line number (file size)
  TAY
  JSR CHRIN
  TAX
  JSR READST
  BNE ENDP
  TYA
  LDY #10   ;Base
       ;  JSR PRINTNUM     ;Print out the number in X,Y
  LDA #32
  JSR CHROUT       ;Add a space to look nice
LOOPz   JSR CHRIN
  TAX
  BEQ LOOP1
  JSR CHROUT
  BNE LOOPz
ENDP     LDA #01
  JSR CLOSE
  JMP CLRCHN

DOLLAR  dc.b "$"
