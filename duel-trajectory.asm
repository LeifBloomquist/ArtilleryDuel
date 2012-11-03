;------------------------------------------------------------------------------
; Plot and animate the bullet trajectory
; Also do collisions etc

SHOWBULLET  
    jsr SOUND_FIRE
    PLOT 0,0

    ; So whose turn is it,and which player# are they?
    lda MYTURN
    beq NOTMYTURN
    
    lda MYPLAYERNUM
    sta playernum
    jmp doparameters
    
NOTMYTURN
    lda OPP_PLAYERNUM
    sta playernum

; This code could be optimized
doparameters

    lda playernum
    cmp #$02    ; Left side of screen?  (p1)
    beq player2 ; No, right side  (p2)
     
    lda $d000  ; Top-left of tower.  Move it over and down a bit.
    clc
    adc #$05    
    sta startx
     
    lda $d001
    clc
    adc #$10
    sta starty
    jmp paramscontd
    
player2
    lda $d002  ; Top-left of tower.  Move it over and down a bit.
    clc
    adc #$05    
    sta startx
    
    lda $d003
    clc
    adc #$10
    sta starty

paramscontd  
    lda WEAPONANGLE
    sta angle
   
    lda WEAPONPOWER
    lsr ; divide by 2
    sta power
   
    jmp trajectory

;------------------------------------------------------------------------------
; Input Parameters

startx 
    .byte $00
 
starty
    .byte $00 

; tacky, need to fix up labels
WEAPONANGLE
angle  ;degrees
  dc.b $00

WEAPONPOWER
power
  dc.b $00    

;------------------------------------------------------------------------------
; Lookup tables for SIN/COS, from lookup.xls

sinbyte
    .byte 0,4,8,13,17,22,26,31,35,39,44,48,53,57,61,65,70,74,78,83,87,91,95,99,103,107,111,115,119,123,127,131,135,138,142,146,149,153,156,160,163,167,170,173,177,180,183,186,189,192,195,198,200,203,206,208,211,213,216,218,220,223,225,227,229,231,232,234,236,238,239,241,242,243,245,246,247,248,249,250,251,251,252,253,253,254,254,254,254,254,255

cosbyte
    .byte 255,254,254,254,254,254,253,253,252,251,251,250,249,248,247,246,245,243,242,241,239,238,236,234,232,231,229,227,225,223,220,218,216,213,211,208,206,203,200,198,195,192,189,186,183,180,177,173,170,167,163,160,156,153,149,146,142,138,135,131,127,123,119,115,111,107,103,99,95,91,87,83,78,74,70,65,61,57,53,48,44,39,35,31,26,22,17,13,8,4,0

;------------------------------------------------------------------------------
; "Variables"

curx  ;X-position
  .byte $00,$00   ; First byte is "fraction", second byte is "integer"
 
cury  ;Y-position
  .byte $00,$00   ; First byte is "fraction", second byte is "integer"

dy ; Y component of current speed 
  .byte $00,$00   ; low/high, as above

dx ; X component of current speed
  .byte $00,$00   ; low/high

playernum ; Whose turn is it?
  .byte $00 

nocollis  ; Temporarily hold off $d01e to give the bullet time to get past shooter's sprite
  .byte $00

windcounter
  .byte $00

;------------------------------------------------------------------------------
; "Function"

trajectory 
    ;Start the sprite/sprite collision suppression countdown
    lda #$30    ;trial and error
    sta nocollis
    
    ;Show bullet sprite
    lda $d015
    ora #$80
    sta $D015
    
    ;Reset the wind counter
    jsr RESETWINDCOUNTER
   
    ; Current object position - 16 bits
    lda startx
    sta curx+1
    sta sprite8x   ;Actually set the sprite position too
    lda #$00
    sta curx
   
    lda starty
    sta cury+1
    sta sprite8y   ;Actually set the sprite position too
    lda #$00
    sta cury    

    ; Clear sprite collision registers by reading them - moved down so sprite is shown already
    lda $d01e ; sprite-sprite
    lda $d01f ; background
          
    ; Sin and cos were swapped to rotate the input 90 degrees 
    ; Break speed into component vectors - Y
    ldx angle
    lda sinbyte,x  ; Get sin(angle) from lookup table
    ldy power     
    jsr multiply8x8
    stx dy     ; Low byte
    sta dy+1   ; High byte
   
    ; Break speed into component vectors - X
    ldx angle
    lda cosbyte,x  ; Get cos(angle) from lookup table
    ldy power
    jsr multiply8x8
    stx dx     ; Low byte
    sta dx+1   ; High byte
   
    ; Negate dy because "up" is negative on the screen 
    ; 16 bit Binary Negation
    SEC             ;Ensure carry is set
    LDA #0          ;Load constant zero
    SBC dy+0        ;... subtract the least significant byte
    STA dy+0        ;... and store the result
    LDA #0          ;Load constant zero again
    SBC dy+1        ;... subtract the most significant byte
    STA dy+1        ;... and store the result

    lda playernum
    cmp #$02
    bne trajloop
    ; If playernum = 2, also negate dx so shot goes left 
    ; 16 bit Binary Negation
    SEC             ;Ensure carry is set
    LDA #0          ;Load constant zero
    SBC dx+0        ;... subtract the least significant byte
    STA dx+0        ;... and store the result
    LDA #0          ;Load constant zero again
    SBC dx+1        ;... subtract the most significant byte
    STA dx+1        ;... and store the result
 
trajloop   
     ; Display on screen
     ldx curx+1 ; high byte
     ldy cury+1 ; high byte
     stx sprite8x
     sty sprite8y

    ; Slow the action down so we can actually see it
    ldy #$00
slowdown
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dey
    bne slowdown
  
     ; Move the object - 16-bit addition
    ; X component   
    clc
    lda curx
    adc dx
    sta curx   
    lda curx+1
    adc dx+1
    sta curx+1
   
    ; Y component
    clc
    lda cury
    adc dy
    sta cury   
    lda cury+1
    adc dy+1
    sta cury+1
   
    ; Check for collision with background
    lda $d01f
    and #$80
    beq NOCOLLIS1  ;zero, meaning no collision
   
    ;Hit the ground!
    jmp MISSED
    
NOCOLLIS1
    ;Check if the bullet's probably cleared the first sprite
    lda nocollis
    bne NOCOLLISX

    ;Check for collisions between sprites
    lda $d01e
    beq CHECKOOB     ; None
    
CHECKP1
    cmp #$81  ;Player 1
    bne CHECKP2
    jmp PLAYER1HIT
    
CHECKP2    
    cmp #$82  ;Player 2
    bne CHECKOOB
    jmp PLAYER2HIT

NOCOLLISX
    ; Clear collision registers by reading them
    lda $d01e     
    lda $d01f
    dec nocollis  ; Count down...
    
CHECKOOB
    ;Check for out of bounds -
    
    ; Left side is easy for x due to the wrap (also handles right)
    clc
    lda curx+1
    sbc #20 ; decimal  - 24 is edge of screen, give some leeway
    bcs gravity  ; Didn't have to borrow
    
    jmp OUTOFBOUNDS    
    ;Top is allowed, for dramatic effect of the bullet disappearing

    ; Simulate gravity -----------------------------------------------------
gravity  
    inc dy       ; Smallest possible
    bne wind     ; dy (low byte) did not wrap around to zero   
    inc dy+1     ; increment the high byte

    ; Simulate wind -----------------------------------------------------
wind    
    ; Decrement the countdown
    dec windcounter
    bne endloop  ;Not zero yet, keep counting
    
    ;Zero.  Reset counter for next pass, and fall through to code that affects the speed.
    jsr RESETWINDCOUNTER
    
wind_direction   ; Determine direction
    lda CLOUDLOC
    bne wind_positive
    
;wind_negative
    dec dx       ; Smallest possible
    ldx dx
    cpx #$FF    
    bne endloop  ; dx (low byte) did not wrap around to -1 (FF)   
    dec dx+1     ; decrement the high byte
    jmp endloop
    
wind_positive    ; Positive (to right) - works perfectly
    inc dx       ; Smallest possible
    bne endloop  ; dx (low byte) did not wrap around to zero   
    inc dx+1     ; increment the high byte
   
endloop
    jmp trajloop

;Exit routine.
traj_x
    ;Turn off bullet sprite
    lda #$03
    sta $D015
    
    ; Clear any messages
    PLOT 0,24
    PRINT "                                       "
    rts

; -------------------------------------------------------------------------
; The various ways the shot can end.

OUTOFBOUNDS
    jsr SOUND_BOUNDS
    PLOT 0,24
    PRINT 28, "           OUT OF BOUNDS!              "
    jsr ONESECOND
    jmp traj_x

MISSED
    jsr SOUND_MISSED
    PLOT 0,24
    PRINT 28, "                MISSED!                "
    lda $d01e  ;Clear sprite flags by reading them
    jsr KABOOM
    jsr CHECKMINOR
    jsr ONESECOND
    jmp traj_x

PLAYER1HIT
    jsr SOUND_DIRECT
    PLOT 0,24
    PRINT 28, "       DIRECT HIT ON PLAYER 1!         "
    lda #$01
    sta SHAKE
    jsr KABOOM
    jsr ONESECOND
    
    ; Am I player one?
    lda MYPLAYERNUM
    cmp #$01
    bne P1DONE  ; No, exit (other player will calc health and send to me)
    
    lda #20
    jsr IWASHIT
    
P1DONE
    jmp traj_x

PLAYER2HIT
    jsr SOUND_DIRECT
    PLOT 0,24
    PRINT 28, "       DIRECT HIT ON PLAYER 2!         "
    lda #$01
    sta SHAKE
    jsr KABOOM
    jsr ONESECOND
    
    ; Am I player two?
    lda MYPLAYERNUM
    cmp #$02
    bne P2DONE  ; No, exit (other player will calc health and send to me)
    
    lda #20
    jsr IWASHIT
    
    ;Screen etc. updated in main game loop
P2DONE    
    jmp traj_x

;---------------------------------------------------------------------
; I was hit!  Take off "a" health from me and return.   
IWASHIT
    sta DAMAGE+1  ;Self-modifying code
    sec
    lda MYHEALTH
DAMAGE
    sbc #$00  ;Overwritten above
    sta MYHEALTH
    
    ;Keep value above 0
    bpl IWASHIT_x   ; Result still positive
    
    lda #$00
    sta MYHEALTH  ;Will still end the game
    
    ;Screen etc. updated in main game loop
IWASHIT_x
    rts

;---------------------------------------------------------------------
;Check for minor damage from near misses.
CHECKMINOR
    ;Check for collisions between sprites
    lda $d01e
    bne CHECKP1M
    jmp CHECKMINOR_x     ; None
    
CHECKP1M
    cmp #$41  ;Explosion and Player 1
    bne CHECKP2M
    PLOT 0,24
    PRINT 28, "       MINOR DAMAGE TO PLAYER 1        "
    
    ; Am I player one?
    lda MYPLAYERNUM
    cmp #$01
    bne CHECKMINOR_x  ; No, exit (other player will calc health and send to me)
    
    lda #10  ;decimal
    jsr IWASHIT
    rts

CHECKP2M
    cmp #$42  ;Explosion and Player 2
    bne CHECKMINOR_x
    PLOT 0,24
    PRINT 28, "       MINOR DAMAGE TO PLAYER 2        "
    
    ; Am I player two?
    lda MYPLAYERNUM
    cmp #$02
    bne CHECKMINOR_x  ; No, exit (other player will calc health and send to me)
    
    lda #10  ;decimal
    jsr IWASHIT
    rts

CHECKMINOR_x
    rts

; ---------------------------------------------------------------------   
; 8x8 Bit Multiplication
;
; Input: Byte1 in Val1
;          Byte 2 in Val2
;
; Output: Erg
; ---------------------------------------------------------------------

Val1
  .byte $00
  
Val2
  .byte $00
  
Erg 
  .byte $00, $00

multiply8x8
  sta Val1
  sty Val2
  jsr Mul8
  

  ;Scale the result to get greater input range
  ldx #$05; Scale factor = 2^x
scaleloop 
  clc         ; Carry = 0
  ror Erg+1   ; Carry = old bit 0 of high byte
  ror Erg     ; Bit 7 = Carry
  dex 
  bne scaleloop
  
  ldx Erg
  lda Erg+1 
  rts

; --- Original routine from Schlowski on Denial
Mul8:
    lda  #$00
    ldy  #8
Mul8Lp:
    asl   
    rol  Val1
    bcc Mul8L1
    clc
    adc  Val2
    bcc  Mul8L1
    inc  Val1
Mul8L1:
    dey
    bne  Mul8Lp
    sta  Erg
    lda  Val1
    sta  Erg+1
    rts

RESETWINDCOUNTER
    ;Intead of 0 to 100, make it 100 to 0
    sec
    lda #100
    sbc WINDSPEED

    sta windcounter
    inc windcounter          ; So it's never 0
    rts
