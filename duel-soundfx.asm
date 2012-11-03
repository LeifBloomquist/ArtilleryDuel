; Sound Effects

;------------------------------------------------------------------------------
; Setup - clear sound chip and set maximum volume!

SOUND_SETUP
  ldx #$00
  txa
SETUP1
  sta $d400,x
  inx
  cpx #$19
  bne SETUP1
  
  lda #$0f
  sta $d418
  rts

;------------------------------------------------------------------------------
; Fire Cannon - use Voice 1

SOUND_FIRE
  lda #$0f
  sta $d418
  lda #$00
  sta $d405  
  lda #$0A
  sta $d406
  lda #$05
  sta $d401
  lda power
  sta $d400
  lda #$81
  sta $d404
  lda #$80
  sta $d404
  rts
  

  
;------------------------------------------------------------------------------
; Hit the Ground - use Voice 2

SOUND_MISSED
  lda #$0f
  sta $d418
  lda #$0f
  sta $d40c  
  lda #$0B
  sta $d40d
  lda #$02
  sta $d408
  lda #$00
  sta $d407
  lda #$81
  sta $d40b
  lda #$80
  sta $d40b
  rts
 

;------------------------------------------------------------------------------
; Move turret - use Voice 1  Don't use A as we're inside joystick routine.

SOUND_TURRET
  ldx #$00
  stx $d405  
  ldx #$f8
  stx $d406
  ldx #$03
  stx $d401
  ldx #$00
  stx $d400
  ldx #$21
  stx $d404
  ldx #$20
  stx $d404
  rts
  

------------------------------------------------------------------------------
; Out of bounds swish - use Voice 2

SOUND_BOUNDS
  lda #$0f
  sta $d40c  
  lda #$0B
  sta $d40d
  lda #$10
  sta $d408
  lda #$00
  sta $d407
  lda #$81
  sta $d40b
  lda #$80
  sta $d40b
  rts


;------------------------------------------------------------------------------
; Direct Hit!! - use Voice 2

SOUND_DIRECT
  lda #$0f
  sta $d418
  lda #$0f
  sta $d40c  
  lda #$0B
  sta $d40d
  lda #$01
  sta $d408
  lda #$00
  sta $d407
  lda #$81
  sta $d40b
  lda #$80
  sta $d40b
  rts

;------------------------------------------------------------------------------
; Incoming chat message - voice 2

SOUND_CHAT
  lda #$0f
  sta $d418
  lda #$01
  sta $d40c  
  lda #$07
  sta $d40d
  lda #$30
  sta $d408
  lda #$00
  sta $d407
  lda #$11
  sta $d40b
  lda #$10
  sta $d40b
  rts
