; duel-game.asm
; Main Game!

; ==============================================================
; Main Game Loop - broken into subroutines 
; ==============================================================

;------------------------------------------------------------------------------
MAINLOOP
  ; Draw the game screen 
  PRINT CG_UCS  ; Switch back to upper/graphics
  jsr DRAWORIGSCREEN
  jsr SETUPSPRITES
  jsr SOUND_SETUP
  
  lda #$00
  sta $d020

  ldx MYPLAYERNUM
  lda PLAYERCOLORS,x
  sta $0286
  PLOT 37,4
  PRINTBYTE MYPLAYERNUM
  
  ;Init game - set my health to 100 and show
  lda #100
  sta MYHEALTH
  PLOT 31,13
  PRINT CG_WHT
  PRINTBYTE MYHEALTH
  PRINT "% "

  ;Start of game loop
MAINLOOP1

  ;Reset health received flag here.  Avoids race condition later on.
  lda #$00
  sta HEALTH_RECEIVED

  lda MYTURN
    
  ; Not my turn.
  beq goTARGET
    
  ; My turn.
  jsr ATTACKER
  jmp ENDOFTURN 
  
goTARGET  ; In case the attacker code grows >255 byes, can't branch 
  jsr TARGET
  jmp ENDOFTURN

; ==============================================================
; End of turn 
; ==============================================================

ENDOFTURN
  ; Exchange health packets - attacker goes first  
  lda MYTURN
  beq WAITHEALTH2  ; Not my turn.   
  
; My turn, Send first ----------------------------------------
SENDFIRST
  jsr SENDHEALTH
  
  ; Wait for packet second.
  jsr WAITHEALTH

  ; Done.
  jmp SHOWHEALTH
  
; Not my turn.  Wait first. ---------------------------------
WAITHEALTH2
  jsr WAITHEALTH
	
  ;Send second.
  jsr SENDHEALTH

   ;Done.
  jmp SHOWHEALTH 
  
  ; Display my health ---------------------------
SHOWHEALTH
  PLOT 31,13
  PRINT CG_WHT
  PRINTBYTE MYHEALTH
  PRINT "%  "
 
CHECKME   
  ;Check end of game for me
  ldx MYHEALTH
  dex  ; So that health=0 means game over
  bpl CHECKOPP       ; Result still positive, I'm OK
  
  ;Negative result - I'm dead!
  lda #$00
  sta YOUWIN
  jmp ENDOFGAME

CHECKOPP
  ;Check end of game for opponent
  ldx OPPHEALTH
  dex  ; So that health=0 means game over
  bpl TOGGLE       ; Result still positive, Opponent is OK
  
  ;Negative result - Opponent is dead!
  lda #$01
  sta YOUWIN
  jmp ENDOFGAME
  
TOGGLE  
  ; Toggle whose turn it is and go back to start
  lda #$01
  eor MYTURN
  sta MYTURN
  jmp MAINLOOP1  

; ==============================================================
; My turn 
; ==============================================================

ATTACKER
  jsr SENDWEATHER   ; Calcs and sends cloud location+windspeed 
  jsr SHOWWEATHER   ; Shows what was just sent
  jsr SHOWSETTINGS  ; Show my initial angle+power

PROMPT  
  ldx MYPLAYERNUM
  lda PLAYERCOLORS,x
  sta $0286 
  PLOT 31,16
  PRINT "YOUR    "
  PLOT 31,17
  PRINT "TURN    "
  PLOT 31,18
  PRINT "        "
  
PLAYERINPUT ;----------------------------
  lda #$01
  sta JOYOK  ; Allow joystick input
  
; Check keys
  jsr $ffe4
  cmp #$00
  beq CHECKJOY
  
KEYS 
  cmp #$88  ;F7, chat
  bne CHECKJOY
  jsr CHATINPUT  
  jmp PLAYERINPUT

; Joystick is read and processed by the interrupt.
CHECKJOY
  lda JOYBUTTON
  bne DOFIRE
  jsr SHOWSETTINGS
  beq PLAYERINPUT  ; zero means no fire, keep looking for input 

DOFIRE    
  lda #$00
  sta JOYOK      ; Turn off joystick input
  sta JOYBUTTON  ; Clear the flag that joystick button has been pressed
 
  ;Preserve angle
  lda MYANGLE
  sta WEAPONANGLE
  sta WEAPONPACKET+2

  ; Preserve Power
  lda MYPOWER
  sta WEAPONPOWER
  sta WEAPONPACKET+3
  
  ; Ready to fire!  Send the packet.  Blocks until ACK received.
  jsr SENDWEAPON
  
  ; And animate the weapon in sync (more or less) with the opponent.
  jsr SHOWBULLET
  rts

; ========================================================================
; Not my turn.  Wait for opponent to send us a packet.  
; ========================================================================

TARGET
  ; Update screen
  jsr SHOWSETTINGS
  
  ldx OPP_PLAYERNUM
  lda PLAYERCOLORS,x
  sta $0286
  PLOT 31,16
  PRINT "WAITING "
  PLOT 31,17
  PRINT "FOR     "
  PLOT 31,18
  PRINTSTRING OPP_NAME
  
WAITFORPACKET ; Always clear and wait
  lda #$00
  sta PACKET_RECEIVED

WAITFORPACKET1  
  lda PACKET_RECEIVED  ; Set by irq
  bne GOTPACKET        ; not zero, so got packet
  
  ; Check keys
  jsr $ffe4
  cmp #$00
  beq WAITFORPACKET1
  
KEYS1 
  cmp #$88  ;F7, chat
  bne WAITFORPACKET1
  jsr CHATINPUT  
  jmp WAITFORPACKET
 
  ; Packet received! 
  ; Was already ACKed by the receive routine in the interrupt.
  ; Assume packet# was checked too.
GOTPACKET  
  lda LAST_PACKET_TYPE
  
CHECKFORWEAPON     ; This ends the turn  
  cmp #$02  ;weapon
  bne CHECKFORCHAT
  lda INPACKET+$2C
  sta WEAPONANGLE
  lda INPACKET+$2D
  sta WEAPONPOWER
  jsr SHOWBULLET  
  rts

CHECKFORCHAT
  lda CHAT_RECEIVED
  beq CHECK_x
  jsr SHOWCHATMSG
  
; All other packet types are ignored
CHECK_x
  jmp WAITFORPACKET 
  
; ==============================================================
; Weather animation - used by both sides - Fuzz's code here
; ==============================================================  

CLOUDLOC
  dc.b $00
  
WINDSPEED
  dc.b $00

WEATHERANIM
  rts  
  
; ==============================================================
; Update Screen for Angle/Power
; ==============================================================  

SHOWSETTINGS
  PRINT CG_WHT
  
  PLOT 31,7
  PRINTBYTE MYANGLE
  PRINT "'  " 
  
  PLOT 31,10
  PRINTBYTE MYPOWER
  PRINT "%  "

  ;Check for incoming chat
  lda CHAT_RECEIVED
  beq SHOWSETTINGS_x
  jsr SHOWCHATMSG

SHOWSETTINGS_x
  rts


; ==============================================================
; Game over!
; ==============================================================  
WINNER
  .byte #$00
  
YOUWIN
  .byte $FF
  
ENDOFGAME
  PRINT 19, 5, "GAME OVER!",13
  
  lda YOUWIN
  beq YOULOST
  
  PRINT CG_GRN,"YOU WON!",13
  jmp PLAYAGAIN

YOULOST
  PRINT CG_RED,"YOU LOST!!",13
  jmp PLAYAGAIN

PLAYAGAIN
  PRINT CG_YEL, "PLAY AGAIN (Y/N)"  
  jsr yn1
  
  cmp #$01 ; Y
  beq RESTART

  jmp 64738 ; reboot!
  
RESTART
  jmp MAINLOOP
  
;-------------------------------------------------------------------------
;Wait for a health packet

WAITHEALTH    
  lda #$07  ;Yellow.  LED is reset by receive routine in thread
	sta COMMSLED

  lda HEALTH_RECEIVED  ; Set by irq  
  bne WAITDONE
  
  lda $028d
  cmp #$04   ; CTRL Key
  bne WAITHEALTH           ; So LED stays yellow
  
  ;Done. 
WAITDONE
  rts



; ==============================================================  
  
MYTURN
  dc.b $FF ; Overwritten

MYANGLE
  dc.b 45  ; Default - decimal

MYPOWER
  dc.b 50  ; Default - decimal
  
MYHEALTH
  dc.b $64 ; Default, 100

OPPHEALTH
  dc.b $FF ; Read from packet and overwritten here
