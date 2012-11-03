;Source by Six of Style (Oliver VieBrooks)              _,.-------.,_
;http://style64.org                                 ,;~'             '~;,
;http://thedarkside.ath.cx                        ,;                     ;,
;mailto:six@darklordsofchaos.com                 ;                         ;
;Last Updated 11/29/2006                        ,'       Style 2006        ',
;                                              ,;                           ;,
;                                              ; ;      .           .      ; ;
;                                              | ;   ______       ______   ; |
;                                              |  `/~"     ~" . "~     "~\'  |
;                                              |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
;                                               |   |        }:{        |   |
;                                               |   !       / | \       !   |
;                                               .~  (__,.--" .^. "--.,__)  ~.
;                                               |     ---;' / | \ `;---     |
;                                                \__.       \/^\/       .__/
;                                                 V| \                 / |V
;                                                  | |T~\___!___!___/~T| |
;                                                  | |`IIII_I_I_I_IIII'| |
;                                                  |  \,III I I I III,/  |
;                                                   \   `~~~~~~~~~~'    /
;                                                     \   .       .   /
;                                                       \.    ^    ./
;                                                         ^~~~^~~~^

; (LB) - removed some crap

OLDSTART
;	jsr LOAD_CONFIG
;	jsr initTOD
;	jsr net_init
;	bcs S_1
;	jsr irq_init
;	PRINT 13,"aUTOCONFIGURE WITH dhcp? "
;	jsr yesno
;	beq S_2
;	cmp #$02
;	beq S_1
;	PRINT 13,"dhcp iNIT"
;	jsr DHCP_DISCOVER
;	jsr getanykey
;	
;S_2	jsr get_macs
;	bcc S_0
;	ERROR "could not resolve gateway mac!"
;	jmp S_1	
;S_0
;	jsr MENU (LB)
;S_1	PRINT 13,"eXITING.",13
;	rts
	
net_init
	jsr CARD_DETECT
	bcs detect_ERROR
	cmp #$01
	bne f_RR
	PRINT CG_GRN,"ETH64 DETECTED",CRLF
	jmp init
f_RR	PRINT CG_RED,"RR-NET COMPATIBLE CARD DETECTED",CRLF
init	jsr CARD_INIT
	bcs init_ERROR
	PRINT CG_RED,"CARD INITIALIZED",CRLF
	clc
	rts
	
detect_ERROR
	ERROR "NO CARD WAS DETECTED!"
	sec
	rts
init_ERROR
	ERROR "ERROR DURING INITIALIZATION!"
	sec
	rts

get_macs ;returns carry clear if success, set if error
	;get MAC for gateway
	lda #<CARD_GATE
	ldx #>CARD_GATE
	jsr GET_ARP
	bcs getmacs_ERR
	;copy gateway mac
	ldx #$00
gm_0
	lda ARP_MAC,x
	sta CARD_GATE_MAC,x
	inx
	cpx #$06
	bne gm_0
	clc
	rts
getmacs_ERR
	sec
	rts
	
initTOD
	lda $dc0f
	and #$7f
	sta $dc0f
	lda #$00
	sta $dc08
	rts

irq_init
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
	lda #<IRQ
	sta $0314
	lda #>IRQ
	sta $0315
	cli
	rts
	
;===========================
; Several changes by (LB)
;===========================

IRQ
	inc $d019
	lda #$31
	sta $d012

	jsr READJOYSTICK
	
	jsr CARD_POLL
	beq IRQx
	
  jsr IRQ_PACKET
IRQx
	jmp $ea31    

; Alternate code suggested by Fungus - save if we need it
; Note that cursor won't flash in chat mode properly
;IRQx
;  jsr $FF9F  ;Scan keys, since we're not using ea31
;	 jmp $ea81  ;was jmp $ea31    

;==================
	
IRQ_PACKET
	jsr CARD_READ
	jsr MAC_PROCESS	
	rts
	

killirq
	sei
	inc $d019 ;ack any pending vic irq
	jsr $ff81
	lda #$31
	sta $0314
	lda #$ea
	sta $0315
	cli
	PRINT "NETIRQ KILLED", CRLF
	rts
;=============================================================================
;MAIN MENU - Removed by (LB)
;=============================================================================

;=============================================================================
;VARIABLES AND DATA

pingcount	dc.b $00	
TIMEOUT	dc.b $00
TICKER  dc.b $00
;=============================================================================
;INCLUDES
	include "checksum.asm"
	include "utils.asm"
	
	include "ETH64.ASM"
	include "RRNET.ASM"
	include "CARD.ASM"
	include "MAC.ASM"
	include "ARP.ASM"
	include "IP.ASM"
	include "ICMP.ASM"
	include "UDP.ASM"
	include "TCP.ASM"

	include "DHCP.ASM"
	include "DNS.ASM"
	include "PING.ASM"
	
	include "PACKET.ASM" ;(LB) - moved

;BUFFER=======================================================================

BUFSTART
	org $cfff
BUFFEND
