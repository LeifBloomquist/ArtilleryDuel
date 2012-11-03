; configuration.asm

; Configuration program for Artillery Duel

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
  PRINT CRLF, CG_LCS, CG_WHT
  PRINT "aRTILLERY dUEL nETWORK cONFIGURATOR", CRLF,CRLF
  PRINT "tHIS PROGRAM CREATES A FILE CALLED", CRLF
  PRINT "IPCONFIG-DEFAULT WHICH CONTAINS YOUR", CRLF
  PRINT "NETWORK SETTINGS.  vISIT", CRLF
  PRINT "HTTP://WWW.PARADROID.NET/IPCONFIG/", CRLF
  PRINT "FOR THE FILE FORMAT."
  
  ;Copy the template into the same area of memory we'll load/save from
  ldx #$00
c1
  lda CONFIGTEMPLATE,x
  sta $c000,x
  inx
  bne c1   ; Just copy whole page

PROMPT
 ;------------------------------------------------Prompts
  PRINT CG_WHT,CRLF,CRLF,"eNTER DESIRED mac ADDRESS [HEX]"
  jsr getmac
  ldx #$00
MAC
  lda gotmac,x
  sta $c008,x
  inx
  cpx #$06
  bne MAC 

GETMYIP
  PRINT CG_WHT,CRLF,CRLF,"eNTER DESIRED ip ADDRESS: "
  jsr getip
  lda IP_OK
	beq GETMYIP   ;Zero if IP was invalid
	
  ldx #$00
IPADD
  lda gotip,x
  sta $c010,x
  inx
  cpx #$04
  bne IPADD 
  
GETMASK
  PRINT CG_WHT,CRLF,CRLF,"eNTER NETMASK: "
  jsr getip
  lda IP_OK
	beq GETMASK   ;Zero if IP was invalid
  
  ldx #$00
MASK
  lda gotip,x
  sta $c016,x
  inx
  cpx #$04
  bne MASK

GETGATE	
	PRINT CG_WHT,CRLF,CRLF,"eNTER GATEWAY: "
  jsr getip
  lda IP_OK
	beq GETGATE   ;Zero if IP was invalid
  
  ldx #$00
GWAY
  lda gotip,x
  sta $c01c,x
  inx
  cpx #$04
  bne GWAY
	
	PRINT CG_WHT,CRLF,CRLF,"eNTER NAME [MAX 8 CHARS]: "
	ldax $c028
	ldy #$09
  jsr INPUT
  
; --------------------------------------------Print for confirmation
  PRINT CRLF,CRLF,"configuration:", CRLF
  PRINT "mac ADDRESS: "
  ldax $c008
  jsr printmac
  PRINT CRLF
  
  PRINT "ip ADDRESS:  "
  ldax $c010
  jsr printip
  PRINT CRLF

  PRINT "nETMASK:     "
  ldax $c016
  jsr printip
  PRINT CRLF

  PRINT "gATEWAY:     "
  ldax $c01c
  jsr printip
  PRINT CRLF

  PRINT "nAME:        "
  ldy #$c0
  lda #$28
  jsr $ab1e ; STROUT 	
  PRINT CRLF

OK
  PRINT CRLF, "iS THIS CORRECT? " 
  jsr yesno
  bne YQ 
  jmp PROMPT  ; no, start again
  
YQ
  cmp #$01  ;Y
  beq SAVECONFIG
  
  cmp #$02  ;Q
  bne OK
  
  rts ; Quit
  
; ------------------------------------------------------------Save File
SAVECONFIG
  PRINT CRLF,CRLF,"sAVING...",CRLF
  jsr SAVEFILE
  rts

; ------------------------------------------------------------Includes etc.
; Dummy locations so that UTILS.ASM compiles
CARD_MASK
CARD_IP
PACKET_RECEIVED

; Fill in all the chunk headers etc and defaults
CONFIGTEMPLATE
  dc.b $ec,$64				              ; Magic ID
	dc.b 1,4,$02,$02	                ; RR-Net - this is ignored anyway
	dc.b 2,8,$00,$80,$10,$0c,$64,$01	; MAC address
	dc.b 3,6,192,168,1,64		          ; IP address
	dc.b 4,6,255,255,255, 0		        ; Netmask
	dc.b 5,6,192,168,1,1		          ; Gateway
	dc.b 6,6,0,0,0,0                  ; DNS, not used yet
	dc.b 9,10,"PLAYER",0,0            ; Name, zero-padded
	dc.b 0                            ; EOF


;Temporary text buffer
GOTINPUT
CHATTEXT	
  ds.b $28    ; 40 bytes

; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

  include "leif-diskroutines.asm"
  include "UTILS.ASM"
  include "duel-utils.asm"
	include "duel-ipaddress.asm"
