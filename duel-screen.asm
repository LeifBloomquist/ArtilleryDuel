; duel-screen.asm
; Screen+Sprite routines

; Color RAM location of the comms character
COMMSLED   = $db95 

ORIGSCREEN1
  incbin "duel-screen.bin"

ORIGSCREEN = ORIGSCREEN1+2  ; Skip over loading address
  
DRAWORIGSCREEN
  ldx #$00
LOOPSOS
  lda ORIGSCREEN,x
  sta $0400,x
  
  lda ORIGSCREEN+$100,x
  sta $0500,x
  
  lda ORIGSCREEN+$200,x
  sta $0600,x
  
  lda ORIGSCREEN+$2E7,x
  sta $06E7,x  
  
  inx
  beq SCREENCOLOR
  jmp LOOPSOS

SCREENCOLOR
  lda COLORDATA,x
  sta $d800,x
  
  lda COLORDATA+$100,x
  sta $d900,x
  
  lda COLORDATA+$200,x
  sta $da00,x
  
  lda COLORDATA+$2e7,x
  sta $dae7,x 
 
  inx
  beq DRAW_x
  jmp SCREENCOLOR
 
DRAW_x
  rts
    
    
sprite7point EQU $07fe
sprite1x EQU $D000
sprite1y EQU $D001
sprite2x EQU $D002
sprite2y EQU $D003
sprite7x EQU $D00C
sprite7y EQU $D00D
sprite8x EQU $D00E
sprite8y EQU $D00F
    
;------------------------------------------------------------------------------
; We are using 4 sprites:
; #1 = Player 1
; #2 = Player 2
; #7 = Explosions, appears on hit
; #8 = Bullet (1 at a time), gets turned on and off

SETUPSPRITES
  lda #$03   ;1+2 only
  sta $D015
  
  ; Player 1 default location
  ldx #$28
  ldy #$95
  stx sprite1x
  sty sprite1y
  
  ; Player 2 default location
  ldx #$DA
  ldy #$A5
  stx sprite2x
  sty sprite2y
  
  ; Hide the 'bullet' and "explosion"
  lda #$00
  sta sprite7x
  sta sprite7y
  sta sprite8x
  sta sprite8y
  
  ;Colors - P1 and P2
  ldx #$01
  lda PLAYERCOLORS,x
  sta $d027
  
  ldx #$02
  lda PLAYERCOLORS,x
  sta $d028
  
  ;Set explosion to light red
  lda #$0a
  sta $d02d
  
  ;This also uses sprite multicolors, so set them here
  lda #$07
  sta $d025
  lda #$02
  sta $d026  
  
  ;Set bullet to white
  lda #$01
  sta $d02e
  
  ;Sprite pointers
  lda #$0d
  sta $07f8
  
  lda #$0e
  sta $07f9
  
  lda #$0f
  sta $07FF
  
  lda #$A0
  sta sprite7point
  
  ;Set sprite #7 to multicolor
  lda #$40
  sta $d01c
  
  ;Copy turret sprite data to cassette buffer
  ldx #$00
SPRLOOP
  lda SPRITEDATA,x
  sta $0340,x
  inx
  cpx #$c0
  bne SPRLOOP
  rts

;------------------------------------------------------------------------------
KABOOM
  lda #$A0
  sta sprite7point
  
  ;Show P1 and P2 and explosion, and hide bullet
  lda #$43
  sta $D015
  
  ; Centered on old bullet location
  ldx sprite8x
  ldy sprite8y
  dex
  dex
  dex
  dex
  dex
  dex
  dex
  dex
  dex
  dex
  dex
  dey
  dey
  dey
  dey
  dey
  dey
  dey
  dey
  dey 
  stx sprite7x
  sty sprite7y
 
  ldx #$00
  stx SHAKECOUNT
  
  lda #$01
  sta $dd01
  
BOOMLOOP
  ; Slow the action down so we can actually see it
  jsr TENTHSECOND  
  inc sprite7point
  
  lda SHAKE
  beq BLOOP1
  
  ;Shake screen
  ldx SHAKECOUNT
  lda SHAKE_X,x
  sta $d016
  lda SHAKE_Y,x
  sta $d011
  inc SHAKECOUNT
  
BLOOP1  
  lda sprite7point
  cmp #$A9
  bne BOOMLOOP
  
  ;Turn off all sprites except P1 and P2
  lda #$03   ;1+2 only
  sta $D015
  lda #$00
  sta SHAKE
  
  lda #$00
  sta $dd01
  rts

; Future - clear the spot on screen where we hit (still buggy)
;  ldx sprite8x
;  lda SPRITE2CHAR_X,x
;  sta CHARX
  
;  ldy sprite8y
;  lda SPRITE2CHAR_Y,y
;  sty CHARY
;  
;  ldy CHARY
;  ldx CHARX
;  clc
;  jsr $E50A  ; PLOT 
;  PRINT " "
;  rts

SHAKE
  dc.b #$00  
  
SHAKECOUNT
  dc.b #$00  

; 9 frames of shaking
SHAKE_X
  dc.b $09,$0E,$0F,$0D,$0B,$0C,$0A,$09,$08

SHAKE_Y
  dc.b $1C,$1D,$1F,$1C,$1E,$18,$19,$1A,$1B

;------------------------------------------------------------------------------
SPRITEDATA
   incbin "duel-sprites.bin"

COLORDATA
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFNNNNNNNNNF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFNNNNNBBBBF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFLLLLLLLLLF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFEEEEEEEEEF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFEEEEEEEEEF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFEEEEEEEEEF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFEEEEEEEEEF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFEEEEEEEEEF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFEEEEEEEEEF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFFEEEEEEEEF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFANNNNNOKAF"
   dc.b "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFF"
   dc.b "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"

; 255 to 100 mapping - putting it here causes the game to lock up????
 ; dc.b 00,00,00,01,01,01,02,02,03,03,03,04,04,05,05,05
 ; dc.b 06,06,07,07,07,8,8,9,9,9,10,10,11,11,11,12
 ; dc.b 12,13,13,13,14,14,15,15,15,16,16,16,17,17,18,18
 ; dc.b 18,19,19,20,20,20,21,21,22,22,22,23,23,24,24,24
 ; dc.b 25,25,26,26,26,27,27,28,28,28,29,29,30,30,30,31
 ; dc.b 31,32,32,32,33,33,33,34,34,35,35,35,36,36,37,37
 ; dc.b 37,38,38,39,39,39,40,40,41,41,41,42,42,43,43,43
 ; dc.b 44,44,45,45,45,46,46,47,47,47,48,48,49,49,49,50
 ; dc.b 50,50,51,51,52,52,52,53,53,54,54,54,55,55,56,56
 ; dc.b 56,57,57,58,58,58,59,59,60,60,60,61,61,62,62,62
 ; dc.b 63,63,64,64,64,65,65,66,66,66,67,67,67,68,68,69
 ; dc.b 69,69,70,70,71,71,71,72,72,73,73,73,74,74,75,75
 ; dc.b 75,76,76,77,77,77,78,78,79,79,79,80,80,81,81,81
 ; dc.b 82,82,83,83,83,84,84,84,85,85,86,86,86,87,87,88
 ; dc.b 88,88,89,89,90,90,90,91,91,92,92,92,93,93,94,94
 ; dc.b 94,95,95,96,96,96,97,97,98,98,98,99,99,100,100,100

PLAYERCOLORS
   dc.b $01,$07,$0A

;CHARX
;  dc.b 0
;CHARY
; dc.b 0

;SPRITE2CHAR_X
;  dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1
;  dc.b 1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,24,24,24,24,24
;  dc.b 24,24,24,25,25,25,25,25,25,25,25,26,26,26,26,26,26,26,26,27,27,27,27,27,27,27,27,28,28,28,28,28,28,28,28

;SPRITE2CHAR_Y
;  dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3
;  dc.b 4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9,10,10,10,10,10,10,10,10,11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,24,24,24,24,24,24,24,24,24,24,24,24,24,24

;------------------------------------------------------------------------------
; Routine to display the current wind speed and direction.
;------------------------------------------------------------------------------

SHOWWEATHER
  PLOT 10,23
  PRINT CG_GRN, CG_RVS, "          "
  PLOT 10,23
  PRINT "WIND "
  
  lda CLOUDLOC
  bne WPLUS

WMINUS 
  PRINT "- "
  jmp SHOWWEATHER_x
  
WPLUS 
  PRINT "+ "
  
SHOWWEATHER_x
  PRINTBYTE WINDSPEED
  PRINT CG_NRM
  rts
