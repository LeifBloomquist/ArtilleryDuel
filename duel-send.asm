; duel-send.asm
; Weather War III / Artillery Duel Packet Send Routines

; ==============================================================
; Macro to prep and copy UDP packet.  Does the following:
;   1. Set packet location to copy from
;   2. Gets checksum and adds it to the packet
;   3. Copies the data to the UDP send buffer
;   {1} is the start of the packet
;   {2) is the checksum location
; ==============================================================

	MAC PREPCOPY
	ldx #<{1}
  lda #>{1}
  stx COPYLOC+1
  sta COPYLOC+2
  
  ldy MYDATALEN
  dey ; So we don't include the checksum byte itself
  dey
  jsr DATACHECKSUM
  lda CSUM
  sta {2}
    
  jsr COPYTOUDPBUFFER
	ENDM

LASTPACKETNUM
  dc.b $01 

MYDATALEN
  dc.b $00 

; ==============================================================
; The "Announce" packet used at the beginning of the game.
; ==============================================================

ANNOUNCEPACKET
  dc.b $01    ; Type = announce
  dc.b $00    ; Packet#
  dc.b $00    ; Who is first?  1=me, 2=opponent
  dc.b $08    ; # chars in name, overwritten
MY_NAME
  dc.b $00,$00,$00,$00,$00,$00,$00,$00  ; My name in PETSCII - 8 chars
  dc.b $00  ; Zero-terminate it for printing, this byte *is* sent

ANN_CSUM
  dc.b $FF  ; Checksum, overwritten

SENDANNOUNCE
  lda #$0e  ; Including zero-term. and checksum (was $0c)
  ldx #$00
  sta MYDATALEN
  jsr UDP_SET_DATALEN
  
  ; Clear any previously received packet flag
  lda #$00
  sta PACKET_RECEIVED
  
  ; Packet#
  inc LASTPACKETNUM
  lda LASTPACKETNUM
  sta ANNOUNCEPACKET+1
  
; Copy data into buffer and send
  PREPCOPY ANNOUNCEPACKET, ANN_CSUM
  jmp SENDWAITACK
  

; ==============================================================
; Weapon packet - Weapon angle and power
; ==============================================================

WEAPONPACKET
  dc.b $02    ; Type = Weapon
  dc.b $FF    ; Packet# - overwritten 
  dc.b $FF    ; Weapon angle in degrees - overwritten 
  dc.b $FF    ; Weapon power +/-100 - overwritten 
WEAPON_CSUM
  dc.b $FF    ; Checksum - Overwritten

SENDWEAPON
  lda #$05
  ldx #$00
  sta MYDATALEN
  jsr UDP_SET_DATALEN
  
  ; Packet#
  inc LASTPACKETNUM
  lda LASTPACKETNUM
  sta WEAPONPACKET+1

  ; Weapon + Power already in buffer
  
  ; Copy data into buffer and send
  PREPCOPY WEAPONPACKET, WEAPON_CSUM 
  jmp SENDWAITACK


; ==============================================================
; Health Packet
; ==============================================================

HEALTHPACKET
  dc.b $03    ; Type = Weapon
  dc.b $FF    ; Packet# - overwritten 
  dc.b $FF    ; Health remaining - overwritten  
HEALTH_CSUM
  dc.b $FF    ; Checksum - Overwritten

SENDHEALTH
  lda #$04
  ldx #$00
  sta MYDATALEN
  jsr UDP_SET_DATALEN
  
  ; Packet#
  inc LASTPACKETNUM
  lda LASTPACKETNUM
  sta HEALTHPACKET+1

  ; Health value, always 1 byte
  lda MYHEALTH
  sta HEALTHPACKET+2
  
  ; Copy data into buffer
  PREPCOPY HEALTHPACKET, HEALTH_CSUM
  
  jmp SENDWAITACK


; ==============================================================
; Weather packet - wind direction and speed
; ==============================================================

WEATHERPACKET
  dc.b $04    ; Type = weather
  dc.b $FF    ; Packet# - overwritten 
  dc.b $FF    ; Direction 0/1 (+/-) for Artillery Duel
  dc.b $FF    ; Wind speed 0-100
WEATHER_CSUM
  dc.b $FF    ; Checksum - Overwritten

SENDWEATHER
  lda #$05
  ldx #$00
  sta MYDATALEN
  jsr UDP_SET_DATALEN
  
  ; Packet#
  inc LASTPACKETNUM
  lda LASTPACKETNUM
  sta WEATHERPACKET+1

  ; Random numbers
  jsr RANDOM255
  and #$01                  ;Odd/Even = +/-
  sta WEATHERPACKET+2
  sta CLOUDLOC

PICK
  jsr RANDOM255
  tay
  lda LOOKUP100,y   ;LOOKUP100 was moved to the end of the file to avoid timing problems
  sta WEATHERPACKET+3
  sta WINDSPEED
  
  ; Copy data into buffer and send
  PREPCOPY WEATHERPACKET, WEATHER_CSUM  
  jmp SENDWAITACK


; ==============================================================
; Outgoing chat packet
; ==============================================================

CHATPACKET
  dc.b $05    ; Type = chat
  dc.b $FF    ; Packet# - overwritten 
  dc.b $FF    ; Length - overwritten
GOTINPUT
CHATTEXT	
  ds.b $28    ; 40 bytes
CHAT_CSUM
  dc.b $FF    ; Checksum, overwritten

SENDCHAT
  lda #$2C
  ldx #$00
  sta MYDATALEN
  jsr UDP_SET_DATALEN
  
  ; Packet#
  inc LASTPACKETNUM
  lda LASTPACKETNUM
  sta CHATPACKET+1
  
  ; Length and text are written to by the CHATINPUT routine

  ; Copy data into buffer
  PREPCOPY CHATPACKET, CHAT_CSUM
  jmp SENDWAITACK



; Flag that we're currently waiting for an ACK, so don't send out ACKs ourselves
; Until complete

WAITINGFORACK
  .byte $00

; ==============================================================
; ALL PACKETS - send the data and wait for an ACK
; ==============================================================
SENDWAITACK
  ; Clear any previously received packet flag
  lda #$00
  sta PACKET_RECEIVED

  lda #$01
  sta WAITINGFORACK
 
SENDWAITACK1 
  ;Send the packet
  jsr UDP_SEND
  
  ; Show waiting (red)
  lda #$02
  sta COMMSLED
  
  ; Wait for one second or a packet
  jsr WAITONE  
  
  ; Did we receive a packet while waiting?  
  lda PACKET_RECEIVED
  beq SENDWAITACK1      ; flag=0, no packet, send again
    
  lda LAST_PACKET_TYPE 
  cmp #$80   ; ACK     ; Not an ACK, ignore and send again
  bne SENDWAITACK
  
  ; Compare sequence
  lda INPACKET+$2B  ;Received packet#
  cmp LASTPACKETNUM
  beq ACKOK
  
  ; Sequence# of ACK was bad!
  PLOT 0,0
  PRINT CG_WHT, "SENT PACKET #"
  PRINTBYTE LASTPACKETNUM
  PRINT CRLF
  PRINT "RCVD ACK #"
  PRINTBYTE INPACKET+$2B
  jmp SENDWAITACK1
  
  ; Packet was sent and ACKed.  Back to the game.
  ; Show no activity
ACKOK
  lda #$0b
  sta COMMSLED
  
  ; Clear waiting flag
  lda #$00
  sta WAITINGFORACK
  rts 

  
; ===========================================================================
; The ACK packet used to acknowledge any incoming packets.
; ========================================================s===================

ACKPACKET
  dc.b $80    ; Type = ACK
  dc.b $00    ; Packet# to ACK 
ACK_CSUM
  dc.b $FF

SENDACK
  ;If we're waiting for an ACK already, don't send one as it screws up the outgoing buffer
  lda WAITINGFORACK
  beq ACKGOAHEAD
  jmp NOACK
  
ACKGOAHEAD
  lda #$03
  ldx #$00
  sta MYDATALEN
  jsr UDP_SET_DATALEN
  
  ;Copy in the packet# that we're sending back
  lda INPACKET+$2B
  sta ACKPACKET+1
  
  ; Copy data into buffer
  PREPCOPY ACKPACKET, ACK_CSUM  
  jsr UDP_SEND
  
  ; There is no ACK in this case
NOACK
  rts


; ===========================================================================
; Helper routine to copy packets into the UDP buffer.   255 bytes max.
; ===========================================================================

COPYTOUDPBUFFER
  ldx UDP_LEN
  inx
COPYLOC
  lda $FFFF,x   ; This gets overwritten by PREPCOPY macro
  sta UDP_DATA,x
  dex
  cpx #$FF       ; aka -1 This is needed so the "zeroth" byte gets copied 
  bne COPYLOC
  rts
