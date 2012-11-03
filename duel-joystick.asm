
;Flag that the joystick may be used for input
JOYOK
   .byte $00 
  
; Rate at which joystick moves - higher = slower movement
JOYCOUNT
  .byte $08

;This holds the joystick button
JOYBUTTON
  .byte $00

; This is called from inside the interrupt!
READJOYSTICK   ; Thanks Jason aka TMR/C0S

  lda JOYOK      ; At a part of the game where joystick input is allowed
  bne CHECKJOYCOUNT
RX
  jmp JOY_OUT1

CHECKJOYCOUNT  
  dec JOYCOUNT
  bne RX
  lda #$08
  sta JOYCOUNT
  ; Drop through

  lda $dc00  ; Port 2
up  
  lsr
  bcs down
  ; do up here, don't use A
  
  ;Check range
  ldx MYANGLE
  cpx #90  ;Decimal
  beq down
  
  inc MYANGLE
  jsr SOUND_TURRET

down  
  lsr
  bcs left
  ; do down here, don't use A
  
  ;Check range
  ldx MYANGLE
  beq left  ;Zero
  
  dec MYANGLE
  jsr SOUND_TURRET

left 
  lsr
  bcs right
  ; do left here, don't use A
  
  ;Check range
  ldx MYPOWER  
  beq right ;zero
  
  dec MYPOWER
  jsr SOUND_TURRET

right  
  lsr
  bcs fire
  ; do right here, don't use A
  
  ;Check range
  ldx MYPOWER
  cpx #100  ;Decimal
  beq fire
  
  inc MYPOWER
  jsr SOUND_TURRET

fire
  lsr
  bcs JOY_OUT
  ; do firing here
  ldx #$01
  stx JOYBUTTON

JOY_OUT
  ;For fun - use Shift as an alternate fire button.  
  ;This way Shift-Lock can be used as a demo mode.
  lda $028e
  cmp #$01
  bne JOY_OUT1 
  ldx #$01
  stx JOYBUTTON

JOY_OUT1
  rts 
