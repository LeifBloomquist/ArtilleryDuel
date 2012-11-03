; duel-chat.asm
; Weather War III Packet Chat routines

; ==============================================================
; Display contents of a chat packet.
; Moved to main game thread.  No longer in IRQ.
; ==============================================================

SHOWCHATMSG
  ;First, check for a zero-length chat message.  Ignore if it is.
  lda INPACKET+$2D  ;First byte of message text
  bne CHATOK
  jmp SHOWCHATMSG_x

CHATOK
  ;Clear the bottom of the screen.
  PLOT 0,24
  PRINT "                                       "
  
  ;Force a zero-termination, no matter what
  lda #$00
  sta INPACKET+$2D+$27  ;39 decimal
  
  ;Print the message
  PLOT 0,24  
  PRINT CG_YEL  
  PRINTSTRING (INPACKET+$2D)

  ; Ping sound
  jsr SOUND_CHAT

SHOWCHATMSG_x  
  ; Clear the packet flags.
  lda #$00
  sta PACKET_RECEIVED  
  sta CHAT_RECEIVED
  rts


; ==============================================================
; Chat Input - in main game thread.
; ==============================================================

CHATINPUT
  PLOT 0,24  
  PRINT "                                       "
  PLOT 0,24  
  PRINT 158 ; Yellow
  
  ;Clear chat text buffer
  lda #$00
  ldx #$27
clearchat1
  sta CHATTEXT,x
  dex
  bne clearchat1
  
  lda #$00
  sta $cc        ; Force cursor to flash
  sta JOYOK      ; Turn off joystick input

  jsr FILTERED_TEXT  
  
  ; Could check carry for run-stop  
  sty CHATPACKET+2 ; Length returned in y
  
  lda #$01
  sta $cc  ; Turn off cursor flashing
  
  jsr SENDCHAT  ;Send the message and wait for ack
  
  ; Ping sound
  jsr SOUND_CHAT
  
  PLOT 0,24
  PRINT "                                       "  
  rts
