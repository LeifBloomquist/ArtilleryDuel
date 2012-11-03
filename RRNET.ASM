
;RR-Net Card Driver
;Part of SixNet
;Inspired by the work of Doc Bacardi
;
;LAST MODIFIED: 08/28/2005

;=============================================================================
;RRNET CONSTANTS
RRNET_PAGE       = $de02
RRNET_DAT0       = $de04
RRNET_DAT1       = $de06
RRNET_RXTX0      = $de08
RRNET_RXTX1      = $de0a
RRNET_TXCMD      = $de0c
RRNET_TXLEN      = $de0e

RRNET_MAGIC     = $630e ;Magic word to detect RRNET
RRNET_RESET	= $0055 ;Word used to reset RRNET
RRNET_PROMISC   = $0d05 ;Accept broadcast and directed packets
RRNET_RXTXEN	= $00d3 ; Enable transmit, receive

;Packet Page Register Pointer Constants
RRNET_PID	= $00 ;$0000
RRREG_RXCFG	= $01 ;$0102
RRREG_RXCTL	= $02 ;$0104
RRREG_TXCFG	= $03 ;$0106
RRREG_TXCMD	= $04 ;$0108
RRREG_BUFCFG	= $05 ;$010a

RRREG_LINECTL	= $06 ;$0112
RRREG_SELFCTL	= $07 ;$0114
RRREG_BUSCTL	= $08 ;$0116
RRREG_TESTCTL	= $09 ;$0118

RRREG_RXEVENT	= $0a ;$0124
RRREG_TXEVENT	= $0b ;$0128
RRREG_BUFEVENT  = $0c

RRREG_RXMISS    = $0d
RRREG_TXCOL     = $0e

RRREG_LINEST    = $0f
RRREG_SELFST    = $10
RRREG_BUSST     = $11

RRREG_IA0       = $12 ;MAC Address, bytes 0-1
RRREG_IA1       = $13 ;MAC Address, bytes 2-3
RRREG_IA2       = $14 ;MAC Address, bytes 4-5

RROP_BUFREQ	= $00c9

;Packet Page Register Address Hi/Lo Tables
RRREG_LO
	dc.b $00,$02,$04,$06,$08,$0a,$12,$14
	dc.b $16,$18,$24,$28,$2c,$30,$32,$34
	dc.b $36,$38,$58,$5a,$5c
	
RRREG_HI
	dc.b $00,$01,$01,$01,$01,$01,$01,$01
	dc.b $01,$01,$01,$01,$01,$01,$01,$01
	dc.b $01,$01,$01,$01,$01

;=============================================================================
;RRNET SEND
RRNET_SEND
;	PRINT 13,"SENDING PACKET",13
	;Send Data Start Address
	lda #<OUTPACKET
	sta XMIT_PTR	
	lda #>OUTPACKET
	sta XMIT_PTR+$01

	;Allocate Buffer
	lda #<RROP_BUFREQ
	sta RRNET_TXCMD
	lda #>RROP_BUFREQ
	sta RRNET_TXCMD+$01

	;Set Transmit Length
	lda OUT_PACKET_LENGTH
	sta RRNET_TXLEN
	sta XMIT_LEN
	
	lda OUT_PACKET_LENGTH+1
	sta RRNET_TXLEN+1
	sta XMIT_LEN+1

	;Select Bus Status Register
	ldy #RRREG_BUSST
	jsr RRNET_SETPAGE

RRNET_SWAIT ;wait for BSR READY (bit 8 set)
	lda RRNET_DAT0+$01
	ldx RRNET_DAT0
	lsr
	bcc RRNET_SWAIT
	; Send Packet
	jsr RRNET_XMIT
	rts
	
;=============================================================================
;Process incoming packet
RRNET_READ
	; skip status
	lda RRNET_RXTX0+$01
	lda RRNET_RXTX0
	;set incoming packet buffer
   	lda #<INPACKET
   	ldx #>INPACKET
	sta RECV_PTR
	stx RECV_PTR+$01
 	;Read packet to buffer
	jsr RRNET_RECV
	;set inpacket length
	lda RECV_LEN
	sta IN_PACKET_LENGTH
	lda RECV_LEN+$01
	sta IN_PACKET_LENGTH+$01
	rts

;=============================================================================
;Check RRNET for incoming packet
RRNET_POLL
	; select the receive event register
	ldy #RRREG_RXEVENT
	jsr RRNET_SETPAGE
	
	; Check for valid packet (bit 8)
	lda RRNET_DAT0+1
	lsr
	bcc RRNET_P2
	;Packet received
	lda #$01
	clc
	rts
RRNET_P2 ;No packet
	lda #$00
	clc
	rts


;=============================================================================
;Initialize RRNET
RRNET_INIT
	;reset chip to assure the default values in all regs
	ldy #RRREG_SELFCTL
	lda #<RRNET_RESET
	ldx #>RRNET_RESET
	jsr RRNET_WRITEPAGE

	;accept individual and broadcast packets
	ldy #RRREG_RXCTL
	lda #<RRNET_PROMISC
	ldx #>RRNET_PROMISC
	jsr RRNET_WRITEPAGE

	;set the mac address
	ldy #RRREG_IA0
	lda CARD_MAC
	ldx CARD_MAC+$01
	jsr RRNET_WRITEPAGE
	
	ldy #RRREG_IA1
	lda CARD_MAC+$02
	ldx CARD_MAC+$03
	jsr RRNET_WRITEPAGE
	
	ldy #RRREG_IA2
	lda CARD_MAC+$04
	ldx CARD_MAC+$05
	jsr RRNET_WRITEPAGE

	ldy #RRREG_LINECTL
	lda #<RRNET_RXTXEN
	ldx #>RRNET_RXTXEN
	jsr RRNET_WRITEPAGE
	clc
	rts

;=============================================================================
; Set Packet Page to RRNET Register (y) into (x:a)
RRNET_SETPAGE:
	lda RRREG_LO,y
	sta RRNET_PAGE
	lda RRREG_HI,y
	sta RRNET_PAGE+$01
	rts

;=============================================================================
; read RRNET Register (y) into (x:a)
RRNET_READPAGE:
	lda RRREG_LO,y
	sta RRNET_PAGE
	lda RRREG_HI,y
	sta RRNET_PAGE+$01
	lda RRNET_DAT0
	ldx RRNET_DAT0+$01
	rts

;=============================================================================
;write (x:a) to RRNET Register (y)
RRNET_WRITEPAGE:
	pha
	lda RRREG_LO,y
	sta RRNET_PAGE
	lda RRREG_HI,y
	sta RRNET_PAGE+$01
	pla
	sta RRNET_DAT0
	stx RRNET_DAT0+$01
	rts

;=============================================================================
;RECEIVE PACKET
;read packet into buffer in (RECV_PTR), return packet len in (RECV_LEN)
RRNET_RECV
	;get incoming packet length
	lda RRNET_RXTX0+$01
 	sta RECV_LEN+$01
	lda RRNET_RXTX0
	sta RECV_LEN

	ldy #$00
	ldx RECV_LEN+$01
   	
   	beq RRNET_RL1      ;packet_length < 256
RRNET_RL0
	lda RRNET_RXTX0
   	sta (RECV_PTR),y
   	iny
   	bne RRNET_R0
   	inc RECV_PTR+$01
RRNET_R0
	lda RRNET_RXTX0+$01
   	sta (RECV_PTR),y
   	iny
   	bne RRNET_RL0
   	inc RECV_PTR+$01
   	dex
   	bne RRNET_RL0

RRNET_RL1
	lda RRNET_RXTX0
   	sta (RECV_PTR),y
   	iny
   	cpy RECV_LEN
   	beq RRNET_READX

	lda RRNET_RXTX0+$01
   	sta (RECV_PTR),y
   	iny
   	cpy RECV_LEN
   	bne RRNET_RL1

RRNET_READX
 	clc
	lda RECV_LEN
	ldx RECV_LEN+$01
	rts

;=============================================================================
;TRANSMIT PACKET
;transmit packet at (XMIT_PTR), (XMIT_LEN) bytes long
RRNET_XMIT 
	;If this packet is less than $100 bytes...
	lda XMIT_LEN+$01
	beq RRNET_X1

RRNET_X0
	ldy #$00
RRNET_XL0
	lda (XMIT_PTR),y
	sta RRNET_RXTX0
	iny
	lda (XMIT_PTR),y
	sta RRNET_RXTX0+$01
	iny
	bne RRNET_XL0
	
	;increment high byte of ptr
	inc XMIT_PTR+$01
	;decrement high byte of length
	dec XMIT_LEN+$01
	bne RRNET_X0
	
RRNET_X1 ;last <$100 bytes
	lda XMIT_LEN ;are there any bytes left to send?
	beq RRNET_XX

	tax ;XMIT_LEN in x
	ldy #$00
	
RRNET_XL1
	lda (XMIT_PTR),y
	sta RRNET_RXTX0
	iny
	lda (XMIT_PTR),y
	sta RRNET_RXTX0+$01
	iny
	dex ;only XMIT_LEN bytes
	beq RRNET_XX
	dex
	bne RRNET_XL1
RRNET_XX
	rts

