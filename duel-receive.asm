; duel-receive.asm
; Packet Receive + Handling Routine

; Port to "listen" on
USER_DEST_PORT   = 3000

; Miscellaneous flags
LAST_PACKET_TYPE
  dc.b $00

; Flag that a packet was received 
PACKET_RECEIVED
  dc.b $00
  
; Special flag for chat packets
CHAT_RECEIVED
  dc.b $00

; Special flag for announce packets, as the game stalls if this isn't detected
ANNOUNCE_RECEIVED
  dc.b $00

; Special flag for health packets, as the game stalls if this isn't detected
HEALTH_RECEIVED
  dc.b $00

; Temporary holder of the checksum we received
RCV_CSUM
  dc.b $ff

; ==============================================================
; Master packet receiver.  This occurs inside the interrupt!
; A UDP packet has arrived, and the port matches the one we want.
; ==============================================================

MYUDP_PROCESS
  ;Show receive (green)
  lda #$0d
	sta COMMSLED

; Check that the packet type is sensible before flagging it.  
  lda INPACKET+$2A  ; Beginning of UDP data buffer
  
  ; copy to LAST_PACKET_TYPE
  sta LAST_PACKET_TYPE
 
; Check for ACK packets --------------------------------- 
  cmp #$80  ; ACK
  bne DOCHECK
  jmp FLAGRECEIVED   ; Don't ACK ACK packets
  
  ; Check checksum, and don't ack if bad
DOCHECK
  jsr CHECKSUM
  beq NOTACK
  jmp BADCSUM

; Check for Chat packet ---------------------------------
NOTACK
  lda LAST_PACKET_TYPE
  cmp #$05  ;Chat
  bne NOTCHAT
  lda #$01
  sta CHAT_RECEIVED
  jsr SENDACK
  jmp FLAGRECEIVED

; Check for Announce packet ---------------------------------
NOTCHAT
  lda LAST_PACKET_TYPE
  cmp #$01  ;Announce
  bne NOTANNOUNCE 
  jsr GRABOPPNAME
  jsr SENDACK
  lda #$01
  sta ANNOUNCE_RECEIVED
  jmp FLAGRECEIVED

; Check for Health packets ---------------------------------
NOTANNOUNCE
  lda LAST_PACKET_TYPE
  cmp #$03  ;Health
  bne NOTHEALTH
  
  ;Store opponent's health 
  lda INPACKET+$2C
  sta OPPHEALTH
  jsr SENDACK
  
  lda #$01
  sta HEALTH_RECEIVED
  jmp FLAGRECEIVED

; Check for Weather packets ---------------------------------
NOTHEALTH
  lda LAST_PACKET_TYPE
  cmp #$04  ;Weather - handle it right away
  bne NOTWEATHER 
  lda INPACKET+$2C
  sta CLOUDLOC    
  lda INPACKET+$2D
  sta WINDSPEED    
  jsr SHOWWEATHER
  jsr SENDACK
  jmp MYUDP_PROCESS_x  ; Don't set packet received flag - we've handled it already so main loop can ignore it.

; Check for Weapon packets ---------------------------------
NOTWEATHER
  lda LAST_PACKET_TYPE
  cmp #$02  ;Weapon - just flag - handled by main code
  bne UNKNOWNTYPE
  jsr SENDACK
  jmp FLAGRECEIVED

UNKNOWNTYPE
  ;Don't ACK any other packets, since they're of an unknown type
  PLOT 0,0
  IPRINT CG_WHT,"UNKNOWN PACKET "
  PRINTBYTE LAST_PACKET_TYPE  ; This should be made threadsafe
  jmp MYUDP_PROCESS_x  

FLAGRECEIVED  
  ; Flag that we got the packet - this is cleared after packet has been processed by the code that uses it
  lda #$01
  sta PACKET_RECEIVED

MYUDP_PROCESS_x  
  ;Show no more activity	
	lda #$0b
	sta COMMSLED
  rts

; -------------------------------------------------------------------------
; Make bad checksums really obvious visually - maybe remove in the future
BADCSUM
  lda $d021 ;Save screen color 
  ldx #$00
bad1
  nop
  nop
  dex
  stx $d021
  bne bad1
  sta $d021
  jmp MYUDP_PROCESS_x

; -------------------------------------------------------------------------
; Do Checksum here
CHECKSUM
  ldx LAST_PACKET_TYPE
  lda BYTESPERPACKET,x
  tay
  tax
  lda INPACKET+$2A,x   ; A now holds the checksum we received
  sta RCV_CSUM  
  
  ;Point x:a to start of received packet
  ;and calculate our own checksum
  ldx #<(INPACKET+$2A)
  lda #>(INPACKET+$2A)
  dey ; So we aren't including the checksum byte itself
  jsr DATACHECKSUM
  
  lda CSUM
  sta CSUM_SAVE
  
  lda RCV_CSUM
  cmp CSUM
  ; Zero bit now contains whether or not checksum matches, use bne/beq
  rts

; -------------------------------------------------------------------------
; Grab the opponent's name from the received packet
GRABOPPNAME	
	ldx #$08 ; was INPACKET+$2D; # of chars
COPYNAME
  lda INPACKET+$2E,x
  sta OPP_NAME,x
  dex
  cpx #$ff ;So the "zeroth" byte gets copied
  bne COPYNAME
  rts

; -------------------------------------------------------------------------
; A lookup table of the length of packets, by packet type.
BYTESPERPACKET
  dc.b $ff,$0d,$04,$03,$04,$2b  ; There is no packet 0
