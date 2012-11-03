; duel-main.asm

; Artillery Duel - Network game for the Commodore 64!
;
; Leif Bloomquist   (Game code)    leif@schemafactor.com
; Oliver VieBrooks  (Network code)
; Chris Boudreau    (Testing)
; Thurstan Johnston (Testing)
; Raymond LeJuez    (Explosions) 
; Robin Harbron     (Fixed point math and hardware loan)

	processor 6502
	org $0801
	
	;zeropage addresses and equates
	include "equates.asm"
	
	;macros
	include "macros.asm"
	include "duel-macros.asm"

BASIC   ;6 sys 2064
	dc.b $0c,$08,$06,$00,$9e,$20,$32,$30
	dc.b $36,$34,$00,$00,$00,$00,$00
	
START
	jsr initTOD	
	jsr STARTUPSCREEN

  ; Determine order - in future, random
  PRINT CRLF, CG_GR3 
  PRINT "PRESS ",CG_WHT,"1",CG_GR3," TO CONNECT TO A SERVER", CRLF 
  PRINT "PRESS ",CG_WHT,"2",CG_GR3," TO SET UP A SERVER", CRLF,CRLF
  
  lda #$00
  sta ANNOUNCE_RECEIVED
  
GETPLAYERNUM
  jsr $FFE4  ;GETIN - key in A
  cmp #$00
  beq GETPLAYERNUM
  
  ; Check for 1 or 2 and set my turn 
  cmp #$31 ;1
  bne P2
  
  ; Set up Player 1 -------------------------
  ldx #$01
  stx MYTURN  
  
  ldx #$01
  stx MYPLAYERNUM
  
  ldx #$02
  stx OPP_PLAYERNUM
  
  jmp GETOPPONENTIP

P2
  cmp #$32
  bne GETPLAYERNUM
  
  ; Set up Player 2 -------------------------  
  ldx #$00
  stx MYTURN
  
  ldx #$02
  stx MYPLAYERNUM
  
  ldx #$01
  stx OPP_PLAYERNUM
  jmp NETSETUP       ; Don't prompt for opponent address
  
GETOPPONENTIP
	; Ask for opponent's IP address. 
	PRINT CG_BLU,"OPPONENT IP ADDRESS? ",CG_YEL
	jsr getip
	lda IP_OK
	beq GETOPPONENTIP   ;Zero if IP was invalid
	PRINT CRLF,CRLF

NETSETUP	
  lda #<gotip
	ldx #>gotip
	jsr UDP_SET_DEST_IP

  jsr SOUND_SETUP 
  
	; Network Setup	
	jsr net_init
  bcc CARD_OK
  PRINT CRLF,CG_WHT,"NO CARD FOUND!",CRLF
  jmp nomac
  
CARD_OK
	jsr irq_init
	
  ; Ports are hardcoded
  ; Source Port
  lda #<3001
  ldx #>3001
  jsr UDP_SET_SRC_PORT
  
  ; Destination Port - same as the one we listen on
  lda #<USER_DEST_PORT
  ldx #>USER_DEST_PORT
  jsr UDP_SET_DEST_PORT

  ;Figure out order
	lda MYPLAYERNUM
  cmp #$01
  bne PLAYER2SEND
  jmp PLAYER1SEND  

  ; ---------------------------------------------------------------
	; Player 2 must first "listen" for Player 1
PLAYER2SEND	
  PRINT CRLF,CG_LBL,"LISTENING FOR ANNOUNCE PACKETS ON       UDP PORT "
	PRINTWORD USER_DEST_PORT  
  PRINT CRLF 
  jsr WAITFORANNOUNCE
  
  ;Copy IP address from the incoming packet
  PRINT CG_WHT,"OPPONENT IP:", CG_YEL
  PRINT_IP INPACKET+$1A
  lda #<(INPACKET+$1A)
	ldx #>(INPACKET+$1A)
	jsr UDP_SET_DEST_IP
	
	jsr GATEWAYMAC  ; Get gateway MAC once we know opponent's IP, if needed
  
  ;Now send our info, after a 1-second delay
  PRINT CG_LBL,"REPLYING...",CRLF
  jsr ONESECOND
  jsr SENDANNOUNCE  ; Blocks until ACK received
  
  jmp MAINLOOP  ; And on to the main game!
  
	; ---------------------------------------------------------------
	; Player 1 sends to Player 2 first
PLAYER1SEND
  jsr GATEWAYMAC  ; Get gateway MAC first, if needed

	; Send the announce packet(s) to opponent, and wait for response. 
	PRINT CRLF,CG_LBL,"SENDING ANNOUNCE PACKETS TO             UDP PORT "
	PRINTWORD USER_DEST_PORT
  PRINT " ON "
  PRINT_IP UDP_DEST_IP
	jsr SENDANNOUNCE  ; Blocks until ACK received
	
	PRINT CG_LBL,"WAITING FOR REPLY",CRLF
  jsr ONESECOND
	jsr WAITFORANNOUNCE
 
  jmp MAINLOOP ; And on to the main game!
  
; --------------------------------------------------------------  
WAITFORANNOUNCE ; Always clear and wait
  lda #$00
  sta PACKET_RECEIVED

WAITFORANNOUNCE1  
  lda ANNOUNCE_RECEIVED  ; Set by irq
  beq WAITFORANNOUNCE1
  
  ;Clear flags 
  lda #$00
  sta ANNOUNCE_RECEIVED
  sta PACKET_RECEIVED
  
  ;Opponent name was already copied in the IRQ  
  PRINT CRLF,CG_WHT,"OPPONENT NAME:",CG_YEL
  PRINTSTRING OPP_NAME
  PRINT CRLF
  
  ; Grab their player#
  ;lda INPACKET+$2C
  ;sta OPP_PLAYERNUM
  rts
 
; =======================================
; Get Gateway MAC address
; =======================================

;Only get gateway MAC if the opponent's not on the local subnet	
GATEWAYMAC
	lda #<UDP_DEST_IP
	ldx #>UDP_DEST_IP
	jsr IPMASK
	bcc MAC_SKIP
	
	PRINT CG_LBL,CRLF,"RESOLVING GATEWAY MAC..."
  jsr get_macs	
	bcc MAC_OK

  ;Flag errors
  PRINT CRLF,CG_WHT,"ERROR RESOLVING THE GW MAC!",CRLF

nomac jmp nomac  
 
MAC_OK
   PRINT CG_LBL, "OK",CRLF 
MAC_SKIP
   rts
  
  ; This part ends around $0a45 - so there are a few hundred wasted bytes here.
  
; =================================================================
; Binary Includes
; =================================================================
  ;Include music here
  org $0ffe  ; $1000-2, because of the load address
  incbin "eve_of_war.dat"  
  
  ;Include charset here
  org $1ffe  ; $2000-2, because of the load address
  incbin "duel2.font" 
  
  ;Include the explosion sprites here - these are from WizardNJ!  No load address
  org $2800   ; Sprite block 160 or $A0
  incbin "duel-explosions.spr" 

; =================================================================
; Game Info
; =================================================================
	
OPP_NAME  
  dc.b $00,$00,$00,$00,$00,$00,$00,$00 ; 8 chars max  
  dc.b $00 ; Guarantee name is zero-terminated
  
  ds.b $10 ; Big buffer on player name !!!!  Get rid of this later
  
OPP_PLAYERNUM
  dc.b $FF ; Overwritten

MYPLAYERNUM
  dc.b $FF ; Overwritten  

; ----------------------------------------------------------------
; Startup Screen
; ----------------------------------------------------------------
STARTUPSCREEN

  ; Black scary screen with red border
  lda #$00
	sta $d021
	lda #$02
  sta $d020

   ;Set up the font
  lda #$19
  sta $d018
  PRINT CG_DCS  ;Inhibit Shift/C=  
  
  ; Title
  PRINT CG_CLR,CG_LBL,"ARTILLERY DUEL ", CG_RED, "NETWORK ", CG_LBL, "1.0",CRLF,CRLF

  ; PAL/NTSC
  jsr SETUP_PAL
  
  PLOT 0,1
  
  ;Load and display config
	jsr LOADCONFIG
	
	PRINT CRLF,CG_BLU, "WELCOME ", CG_YEL
	PRINTSTRING MY_NAME
	
  PRINT CG_BLU, "!", CRLF,CRLF,"MY ADDRESS IS ", CG_YEL
  PRINT_IP CARD_IP

  PRINT CG_BLU, "MY NETMASK IS ", CG_YEL
  PRINT_IP CARD_MASK  

  PRINT CG_BLU, "MY GATEWAY IS ", CG_YEL 
  PRINT_IP CARD_GATE
  
	;Cue Music
  jsr $1000

	sei
	lda #$01
	sta $d019
	sta $d01a
	lda #$1b
	sta $d011
	lda #$7f
	sta $dc0d
	lda #$31
	sta $d012
	lda #<MUSIC
	sta $0314
	lda #>MUSIC
	sta $0315
	cli
	rts
	
;---------------------------------------------------------------

NTSCCOUNT
  .byte $07
	
MUSIC
	inc $d019
	lda #$31
	sta $d012
	
	;Using a PAL tune.  Skip every 6th frame if NTSC
	lda $2A6
  bne MUSICPLAY
	
	dec NTSCCOUNT
	bne MUSICPLAY
	lda #$07
	sta NTSCCOUNT
	jmp MUSIC_x
MUSICPLAY
	jsr $1003
MUSIC_x
	jmp $ea31


; ----------------------------------------------------------------
LOADCONFIG

  ; Todo, set up default, so if file isn't read we can still use default

  PRINT CRLF,CG_BLU,"LOADING CONFIGURATION...",CRLF
  
  ;Check that device# isn't 0  (This is seen with Final Replay)
  lda $BA
  bne LOADOK
  
  ;Since it was, set it to 8  
  lda #$08
  sta $BA
  
LOADOK  
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
  
  ;Player Name
  ldx #$07
nameloop
  lda $c028,x
  sta MY_NAME,x
  dex
  cpx #$ff  ; So the zeroth byte gets copied
  bne nameloop
  
  rts
  
; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

	include "duel-game.asm"
  include "leif-diskroutines.asm"
	include "duel-send.asm"
	include "duel-receive.asm"
	include "duel-utils.asm"
	include "duel-ipaddress.asm"
	include "duel-chat.asm"
	include "duel-screen.asm"
  include "duel-trajectory.asm"
  include "duel-soundfx.asm"
  include "duel-joystick.asm"
  include "SIXNET.ASM"
