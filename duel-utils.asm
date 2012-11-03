; duel-utils.asm
; Utils and macros

; ==============================================================
; One second delay - thanks groepaz
; ==============================================================

ONESECOND
    ldx #60   ; - NTSC   use #50 for PAL
lp:
    lda #$f8
lp2:
    cmp $d012    ; reached the line
    bne lp2
lp3:
    cmp $d012    ; past the line
    beq lp3
    
    ; Count down
    dex
    bne lp

ONESECOND_x    
    rts

; ==============================================================
; One second delay that can be interrupted by a packet
; ==============================================================

WAITONE
    ldx #60  ; - NTSC   use #50 for PAL
alp:
    lda #$f8
alp2:
    cmp $d012    ; reached the line
    bne alp2
alp3:
    cmp $d012    ; past the line
    beq alp3
    
    ; Early exit if a packet is received
    lda PACKET_RECEIVED
    bne WAITONE_x           ; exit if flag = 1
    
    ; Count down
    dex
    bne alp

WAITONE_x    
    rts
    

; ==============================================================
; One-tenth second delay
; ==============================================================

TENTHSECOND
    ldx #6   ; - NTSC   use #5 for PAL
tlp:
    lda #$f8
tlp2:
    cmp $d012    ; reached the line
    bne tlp2
tlp3:
    cmp $d012    ; past the line
    beq tlp3
    
    ; Count down
    dex
    bne tlp

TENTHSECOND_x    
    rts
    
; ====================================================================
; Return a random number from 1-255 using SID Voice #3 - thanks Golan
; ====================================================================

RANDOM255
  LDA #$FF
  STA $D40F
  LDA #$80
  STA $D412
  LDA $D41B
  rts



; ==============================================================
; Simple checksum on sent/received data
; Start of data in x:a, length in y
; checksum in CSUM when finished
; ==============================================================

CSUM_SAVE dc.b $00

CSUM dc.b $00

DATACHECKSUM
  stx DCS1+1
  sta DCS1+2
  
  lda #$00 ; Reset checksum
  sta CSUM
  clc
  
DCS1
  lda $FFFF,y   ;Overwritten above
  adc CSUM
  sta CSUM  
  dey
  cpy #$FF       ; aka -1 This is needed so the "zeroth" byte gets added 
  bne DCS1
  rts


; ==============================================================
; All defaults are NTSC.  This code overrides for PAL.
; ==============================================================

SETUP_PAL
  PLOT 35,24
  PRINT CG_RED 
  
  lda $2A6
  bne DOPAL 
  
  ; NTSC System detected, don't change anything
  PRINT "NTSC"
  rts
  
  ; PAL System detected, make changes
DOPAL
  
  PRINT "PAL"
  lda #50
  sta ONESECOND+1
  sta WAITONE+1
  lda #$05
  sta TENTHSECOND+1
  rts

SETUP_PAL_x
  rts


; ==============================================================
; Filtered Input routine
; ==============================================================

TEXT_FILTER
  dc.b " ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890.,-+!#$%&'()*",0

;Input a string and store it in GOTINPUT, terminated with a null byte.
;x:a is a pointer to the allowed list of characters, null-terminated.
;max # of chars in y returns num of chars entered in y.

MAXCHARS
  dc.b $00

LASTCHAR
  dc.b $00

GETIN = $ffe4

FILTERED_TEXT
  lda #>TEXT_FILTER
  ldx #<TEXT_FILTER
  ldy #38
  ;Drop through

FILTERED_INPUT
  sty MAXCHARS
  stx CHECKALLOWED+1
  sta CHECKALLOWED+2

  ;Zero characters received.
  lda #$00
  sta INPUT_Y

 ;Wait for a character.
INPUT_GET
  jsr GETIN
  beq INPUT_GET
  
  sta LASTCHAR

  cmp #$14               ;Delete
  beq DELETE ;TODO

  cmp #$0d              ;Return
  beq INPUT_DONE

  ;Check the allowed list of characters.
  ldx #$00
CHECKALLOWED
  lda $FFFF,x           ;Overwritten
  beq INPUT_GET         ;Reached end of list (0)

  cmp LASTCHAR
  beq INPUTOK            ;Match found

  ;Not end or match, keep checking
  inx
  jmp CHECKALLOWED

INPUTOK
  lda LASTCHAR          ;Get the char back
  ldy INPUT_Y
  sta CHATTEXT,y
  jsr $ffd2             ;Print it
  
  inc INPUT_Y           ;Next character

  ;End reached?
  lda INPUT_Y
  cmp MAXCHARS
  beq INPUT_DONE

  ;Not yet.
  jmp INPUT_GET

INPUT_DONE
   ldy INPUT_Y
   lda #$00
   sta CHATTEXT,y   ;Zero-terminate
   rts

; Delete last character.
DELETE
  ;First, check if we're at the beginning.  If so, just exit.
  lda INPUT_Y
  bne DELETE_OK
  jmp INPUT_GET
  
  ;At least one character entered. 
DELETE_OK
  ;Move pointer back.
  dec INPUT_Y
  
  ;Store a zero, just in case no other characters are entered.
  ldy INPUT_Y
  lda #$00
  sta CHATTEXT,y

  ;Print the delete char
  lda #$14
  jsr $ffd2
  
  ;Wait for next char
  jmp INPUT_GET
