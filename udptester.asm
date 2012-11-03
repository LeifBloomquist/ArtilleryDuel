; UDPtester.asm - simple code to exercise udp rcv+checksum 

	processor 6502
	org $0801
	
	;zeropage addresses and equates
	include "equates.asm"
	
	;macros
	include "macros.asm"
	include "duel-macros.asm"
	
COMMSLED equ $d020

BASIC   ;6 sys 2064
	dc.b $0c,$08,$06,$00,$9e,$20,$32,$30
	dc.b $36,$34,$00,$00,$00,$00,$00
	
START
	jsr initTOD	

  lda #7 ;decimal
  sta CARD_IP+2
  sta CARD_GATE+2
  
  lda #64 ;decimal
  sta CARD_IP+3
  
  lda #$00
  sta CARD_MAC+0
  lda #$80
  sta CARD_MAC+1
  lda #$10
  sta CARD_MAC+2
  lda #$0c 
  sta CARD_MAC+3
  lda #$64 
  sta CARD_MAC+4
  lda #$01 
  sta CARD_MAC+5
  

  PRINT 13, 150, "MY IP ADDRESS IS ", 158
  ldx #>CARD_IP
  lda #<CARD_IP
  jsr printip
  PRINT 13


NETSETUP   
	; Network Setup	
	jsr net_init
	jsr irq_init
	jsr get_macs
	; TODO handle errors
  bcc MAC_OK

  ;TODO, Check for error	
  PRINT 13,"ERROR RESOLVING THE GW mac",13
  PRINT 13,"eXITING.",13
  rts

MAC_OK
  PRINT "RESOLVED GATEWAY MAC", CRLF
  ; Ports are hardcoded
  ; Source Port
  lda #<3001
  ldx #>3001
  jsr UDP_SET_SRC_PORT
  
  ; Destination Port - same as the one we listen on
  lda #<USER_DEST_PORT
  ldx #>USER_DEST_PORT
  jsr UDP_SET_DEST_PORT
  
  PRINT CG_CLR
  lda #$00
  sta $0286
  
; ---------- Main Loop ---------------------------------------
  
WAITFORPACKET ; Always clear and wait
  lda #$00
  sta PACKET_RECEIVED
  
  lda #$BB
CLEARPACKET
  sta INPACKET+$2A,x
  inx
  bne CLEARPACKET

WAITFORPACKET1  
  lda PACKET_RECEIVED  ; Set by irq
  beq WAITFORPACKET1
  
  jmp SHOWHEX
  
  ; Show characters on screen
  ldx #$00
SHOW1
  lda INPACKET,x
  sta $0400,x
  inx
  bne SHOW1  ;wrap to 0
  
SHOWHEX
  ; Show hex bytes on screen
  PLOT 0,0
  ldx #$00
SHOW2
  lda INPACKET,x
  jsr hexstr
  
  lda $0286
  eor #$01
  sta $0286
  
  inx
  bne SHOW2  ;wrap to 0
  
  PRINT CRLF,CRLF, "PACKET LENGTH:"
  PRINTBYTE IN_PACKET_LENGTH
  PRINT CRLF,CRLF
  PRINT "RECEIVED:"
  PRINTBYTE RCV_CSUM
  PRINT "    ",CRLF
  
  PRINT "CALCULATED:"
  PRINTBYTE CSUM_SAVE
  PRINT "    ",CRLF
  
  jmp WAITFORPACKET
  
; ----------------------------------------------------------------
; Startup Screen
; ----------------------------------------------------------------
STARTUPSCREEN

  ; Black scary screen
  lda #$00
	sta $d020
	sta $d021

  PRINT $08  ;Inhibit Shift/C=  
  rts  	
  
	jsr LOADCONFIG	

; ----------------------------------------------------------------
LOADCONFIG

  ; Todo, set up default, so if file isn't read we can still use default

  PRINT 13,31,"LOADING CONFIGURATION...",13
  jsr LOADFILE
  
  ;MAC Address
  lda $c008+0 
  sta CARD_MAC+0
  lda $c008+1
  sta CARD_MAC+1
  lda $c008+2
  sta CARD_MAC+2
  lda $c008+3 
  sta CARD_MAC+3
  lda $c008+4 
  sta CARD_MAC+4
  lda $c008+5 
  sta CARD_MAC+5
  
  ; IP Address 
	lda $c010+0
  sta CARD_IP+0
  lda $c010+1
  sta CARD_IP+1
  lda $c010+2
  sta CARD_IP+2
  lda $c010+3
  sta CARD_IP+3
  
  ;Netmask
  lda $c016+0
  sta CARD_MASK+0
  lda $c016+1
  sta CARD_MASK+1
  lda $c016+2
  sta CARD_MASK+2
  lda $c016+3
  sta CARD_MASK+3
  
  ;Gateway
  lda $c01c+0
  sta CARD_GATE+0
  lda $c01c+1
  sta CARD_GATE+1
  lda $c01c+2
  sta CARD_GATE+2
  lda $c01c+3
  sta CARD_GATE+3
  
  rts


;--- Unresolved Symbols - dummies so code compiless
MYHEALTH
  dc.b $00
CLOUDLOC
  dc.b $00
SHOWCHATMSG
  rts
WINDSPEED
  dc.b $00
READJOYSTICK
  rts
  
; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

  include "leif-diskroutines.asm"
	include "duel-send.asm"
	include "duel-receive.asm"
	include "duel-utils.asm"
;	include "duel-chat.asm"
;	include "duel-screen.asm"
 ; include "duel-trajectory.asm"
 ; include "duel-soundfx.asm"
 ; include "duel-joystick.asm"

	
  include "SIXNET.ASM"
