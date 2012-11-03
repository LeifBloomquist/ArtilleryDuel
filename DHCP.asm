;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 4/24/2006 
;
;DHCP PROTOCOL=================================================================
;                                                        _,.-------.,_
;DHCP PACKET FORMAT:                                 ,;~'             '~;,
;+----------+---------+----------+-----------+     ,;                     ;,
;|$00-$0d   |$0e-$21  |$22-$29   |$2a-       |    ;                         ;
;+----------+---------+----------+-----------+   ,'                         ',
;|MAC Header|IP Header|UDP Header|DHCP Packet|  ,;                           ;,
;+----------+---------+----------+-----------+  ; ;      .           .      ; ;
;                                               | ;   ______       ______   ; |
;MAC Header Fields:                             |  `/~"     ~" . "~     "~\'  |
;$00 - Destination MAC (6)                      |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
;$06 - Source MAC (6)                            |   |        }:{        |   |
;$0c - Packet Type (2)                           |   !       / | \       !   |
;                                                .~  (__,.--" .^. "--.,__)  ~.
;IP Header Fields:                               |     ---;' / | \ `;---     |
;$0e - IP Version (1)                             \__.       \/^\/       .__/
;$0f - Type of Service (1)                         V| \                 / |V
;$10 - Total Length of packet (2)                   | |T~\___!___!___/~T| |
;$12 - Identifier (2)                               | |`IIII_I_I_I_IIII'| |
;$14 - Flags (1)                                    |  \,III I I I III,/  |
;$15 - Fragment (1)                                  \   `~~~~~~~~~~'    /
;$16 - Time To Live (1)                                \   .       .   /
;$17 - Protocol (1)                                      \.    ^    ./
;$18 - Checksum (2)                                        ^~~~^~~~^
;$1a - Source IP Address (4)
;$1e - Destination IP Address (4)
;
;UDP Header Fields:
;$22 - Source Port (2)
;$24 - Dest Port (2)
;$26 - Length (2)
;$28 - Checksum (2)
;
;DHCP Packet Fields
;$2a - Opcode (1)
;$2b - Hardware Type (1)
;$2c - Hardware Address Length (1)
;$2d - Hop Count (1)
;$2e - Transaction ID (4)
;$32 - Number of seconds (2)
;$34 - Flags (2) (only using 1 bit!)
;$36 - Client IP (4)
;$3a - Your IP (4)
;$3e - Server IP (4)
;$42 - Gateway IP (4)
;$46 - Client Hardware Address (16)
;$56 - Server Host Name (64)
;$96 - Boot filename (128)
;=============================================================================
;EQUATES
DHCP_STATE_IDLE	    = $00
DHCP_STATE_DISCOVER = $01
DHCP_STATE_REQ	    = $02


DHCP_MTYPE_REQ	 = $01
DHCP_MTYPE_REPLY = $02

DHCP_HWTYPE_ETHERNET = 1;

DHCP_STATE	dc.b $00
DHCP_SRC_PORT	= 68
DHCP_DEST_PORT  = 67

DHCP_OPTION_MASK        = 1
DHCP_OPTION_ROUTER      = 3
DHCP_OPTION_NAMESERV    = 6
DHCP_OPTION_IPADDR      = 50
DHCP_OPTION_LEASE       = 51
DHCP_OPTION_TYPE        = 53
DHCP_OPTION_SERVER      = 54
DHCP_OPTION_END         = 255

;=============================================================================
DHCP_SERVER	dc.b 0,0,0,0
DHCP_HEADER
DHCP_MTYPE	dc.b $00
DHCP_HWTYPE	dc.b $01
DHCP_HWLEN	dc.b $06
DHCP_HOP	dc.b $00
DHCP_TID	dc.b $37,$33,$7c,$64
DHCP_NOS	dc.b $00,$00
DHCP_FLAGS	dc.b $00,$00
DHCP_CADDRESS	dc.b $00,$00,$00,$00
DHCP_YADDRESS	dc.b $00,$00,$00,$00
DHCP_SADDRESS	dc.b $00,$00,$00,$00
DHCP_GADDRESS	dc.b $00,$00,$00,$00

DHCP_HWADDRESS	ds.b 16,0
DHCP_SHOSTNAME	ds.b 64,0
DHCP_BFILENAME  ds.b 128,0

DHCP_MAGIC	dc.b 99,130,83,99
DHCP_DATA	ds.b 64,0

DHCP_DISC_DATA	dc.b $35,$01,$01 ;DHCP Message Type = DHCP Discover
		dc.b $37,$03,$01,$03,$06 ;Parameter Request List = Mask,Router,DNS
		dc.b $ff

DHCP_REQ_DATA
		dc.b $35,$01,$03
		dc.b $36,$04
DHCP_REQ_SRV	dc.b $00,$00,$00,$00
		dc.b $32,$04
DHCP_REQ_IP	dc.b $00,$00,$00,$00
		dc.b $ff
		
		
;============================================================================	
DHCP_PROCESS	;Process incoming DHCP packet
	lda DHCP_STATE
	cmp DHCP_STATE_DISCOVER
	bne DHCP_PROC0
	;Ok, we're in discover mode.  Is this an offer packet?
;	lda (INPACKET+$11a)
;	cmp #$35
;	bne DHCP_PROCx
;	lda (INPACKET+$11b)
;	cmp #$01
;	bne DHCP_PROCx
;	lda (INPACKET+$11c)
;	cmp #$02
;	bne DHCP_PROCx
	jmp DHCP_OFFER_PROC ;send a request based on this data
DHCP_PROC0
	cmp DHCP_STATE_REQ
	bne DHCP_PROCx
	jmp DHCP_SEND_ACK  ;send an ack
DHCP_PROCx
	rts

	
;============================================================================	
DHCP_OFFER_PROC ;process DHCP OFFER Packet

	lda INPACKET+$3a
	sta DHCP_REQ_IP
	sta CARD_IP
	lda INPACKET+$3b
	sta DHCP_REQ_IP+1
	sta CARD_IP+1
	lda INPACKET+$3c
	sta DHCP_REQ_IP+2
	sta CARD_IP+2
	lda INPACKET+$3d
	sta CARD_IP+3
	sta DHCP_REQ_IP+3

	lda INPACKET+$3e
	sta DHCP_REQ_SRV
	lda INPACKET+$3f
	sta DHCP_REQ_SRV+1
	lda INPACKET+$40
	sta DHCP_REQ_SRV+2
	lda INPACKET+$41
	sta DHCP_REQ_SRV+3
	;HWTYPE, HWLEN, HOP, TID,NOS,flags,cad,yad,sad,gad,shost
	;bfilename,magic are static
	;hwaddress already set by discover
	lda #<(INPACKET+$11a)
	ldx #>(INPACKET+$11a)
DHCP_0x
	jsr DHCP_PARSEOPTION
	bcc DHCP_0x
	
	;Set DHCP_DATA
	ldx #$00
DHCP_O1
	lda DHCP_REQ_DATA,x
	sta DHCP_DATA,x
	inx
	cpx #$16
	bne DHCP_O1
	;rest is pad
	lda #$00
DHCP_O2
	sta DHCP_DATA,x
	inx
	cpx #$40
	bne DHCP_O2
	;set state
	lda DHCP_STATE_REQ
	sta DHCP_STATE

	lda #<IP_BCASTIP
	ldx #>IP_BCASTIP
	jsr UDP_SET_DEST_IP

	jmp DHCP_SEND
	rts

;============================================================================	
DHCP_SEND_ACK
	rts
;============================================================================	
DHCP_DISCOVER ;Send DHCP Discover
	;zero out card_ip
	lda #$00
	sta CARD_IP
	sta CARD_IP+1
	sta CARD_IP+2
	sta CARD_IP+3
	
	;Setup DHCP
	lda #DHCP_MTYPE_REQ
	sta DHCP_MTYPE
	;HWTYPE, HWLEN, HOP, TID,NOS,flags,cad,yad,sad,gad,shost
	;bfilename,magic are static
	;set client hardware address {Will only do this in DHCP_Discover)
	ldx #$00
DHCP_D0
	lda CARD_MAC,x
	sta DHCP_HWADDRESS,x
	inx
	cpx #$06
	bne DHCP_D0

	;Set DHCP_DATA
	ldx #$00
DHCP_D1
	lda DHCP_DISC_DATA,x
	sta DHCP_DATA,x
	inx
	cpx #$09
	bne DHCP_D1
	;rest is pad
	lda #$00
DHCP_D2
	sta DHCP_DATA,x
	inx
	cpx #$40
	bne DHCP_D2
	lda DHCP_STATE_DISCOVER
	sta DHCP_STATE
	lda #<IP_BCASTIP
	ldx #>IP_BCASTIP
	jsr UDP_SET_DEST_IP
	
	jmp DHCP_SEND

;============================================================================	
DHCP_SEND
	;lda #<IP_BCAST
	;ldx #>IP_BCAST
	;jsr UDP_SET_DEST_IP
	lda #$01
	sta UDP_BCAST
	;Prep UDP
	ldax #DHCP_SRC_PORT ;bootpc
	jsr UDP_SET_SRC_PORT
	ldax #DHCP_DEST_PORT ;bootps
	jsr UDP_SET_DEST_PORT
	;Set Data Len
	ldax #304
	jsr UDP_SET_DATALEN

	;copy to udp data
	ldx #$00
DHCP_S0	lda DHCP_HEADER,x
	sta UDP_DATA,x
	inx
	bne DHCP_S0
	lda DHCP_HEADER+100,x
DHCP_S1	sta UDP_DATA+100,x
	inx
	cpx #49
	bne DHCP_S1

	jsr UDP_SEND
	rts
	

DHCP_PARSEOPTION
;expects option start in x:a, returns cc if good, cs if end of options
;returns address of next option in x:a
	sta DHCP_PTR
	stx DHCP_PTR+1
DH_P0
	ldy #$00
	lda (DHCP_PTR),y
	cmp #DHCP_OPTION_END

	bne DH_P1
	;end of options
	sec
	rts

DH_P1   ;subnet mask
	cmp #DHCP_OPTION_MASK
	bne DH_P2
	jsr DH_PAdd2 ;skip option byte+length byte
	lda DHCP_PTR
	ldax CARD_MASK
	stax as0
	ldxa DHCP_PTR
	ldy #$04
	jsr copybytes
	jsr DH_PAdd4
	jmp DH_Px
DH_P2   ;gateway
	cmp #DHCP_OPTION_ROUTER
	bne DH_P3
	jsr DH_PAdd2 ;skip option byte+length byte
	lda DHCP_PTR
	ldax CARD_GATE
	stax as0
	ldxa DHCP_PTR
	ldy #$04
	jsr copybytes
	jsr DH_PAdd4
	jmp DH_Px
DH_P3   ;name server
	cmp #DHCP_OPTION_NAMESERV
	bne DH_P4
	jsr DH_PAdd2 ;skip option byte+length byte (it's 4)
	lda DHCP_PTR
	ldax CARD_NS1
	stax as0
	ldxa DHCP_PTR
	ldy #$04
	jsr copybytes
	jsr DH_PAdd4
	jmp DH_Px
DH_P4   ;our ip address
	cmp #DHCP_OPTION_IPADDR
	bne DH_P5
	jsr DH_PAdd2 ;skip option byte+length byte
	lda DHCP_PTR
	ldax CARD_IP
	stax as0
	ldxa DHCP_PTR
	ldy #$04
	jsr copybytes
	jsr DH_PAdd4
	jmp DH_Px
DH_P5   ;DHCP Lease Duration
	cmp #DHCP_OPTION_LEASE
	bne DH_P6
	jsr DH_PAdd2 ;skip option byte+length byte
	jsr DH_PAdd4 ;skip this data.  Fuck leasing/renewing for now.
	jmp DH_Px
DH_P6   ;DHCP Message Type
	cmp #DHCP_OPTION_TYPE
	bne DH_P7
	jsr DH_PAdd2 ;skip option byte + length byte
	jsr DH_PAdd  ;skip data
	jmp DH_Px
DH_P7   ;DHCP Server Address 
	cmp #DHCP_OPTION_SERVER
	bne DH_PErr
	jsr DH_PAdd2 ;skip option byte+length byte
	lda DHCP_PTR
	ldax DHCP_SERVER
	stax as0
	ldxa DHCP_PTR
	ldy #$04
	jsr copybytes
	jsr DH_PAdd4
	jmp DH_Px
DH_PErr ;unknown option, attempt to skip it and it's data.
	jsr DH_PAdd ;discard option
	ldy #$00
	lda (DHCP_PTR),y
	tay
DHPErrL	jsr DH_PAdd
	dey
	bne DHPErrL
DH_Px
	ldxa DHCP_PTR
	clc
	rts

DH_PAdd4
	jsr DH_PAdd
	jsr DH_PAdd
DH_PAdd2
	jsr DH_PAdd
DH_PAdd
	inc DHCP_PTR
	bne DHPAddx
	inc DHCP_PTR+1
DHPAddx
	rts
	
	
	