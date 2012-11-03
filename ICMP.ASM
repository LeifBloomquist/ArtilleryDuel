;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 1/26/2006
;
;ICMP PROTOCOL================================================================
;                                                       _,.-------.,_
;ICMP PACKET FORMAT:                                ,;~'             '~;,
;+----------+---------+-----------+---------+     ,;                     ;,
;|$00-$0d   |$0e-$21  |$22-$24    |$26->    |    ;                         ;
;+----------+---------+-----------+---------+   ,'        Style 2006       ',
;|MAC Header|IP Header|ICMP Header|ICMP Data|  ,;                           ;,
;+----------+---------+-----------+---------+  ; ;      .           .      ; ;
;                                              | ;   ______       ______   ; |
;MAC Header Fields:                            |  `/~"     ~" . "~     "~\'  |
;$00 - Destination MAC                         |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
;$06 - Source MAC                               |   |        }:{        |   |
;$0c - Packet Type                              |   !       / | \       !   |
;                                               .~  (__,.--" .^. "--.,__)  ~.
;IP Header Fields:                              |     ---;' / | \ `;---     |
;$0e - IP Version                                \__.       \/^\/       .__/
;$0f - Type of Service                            V| \                 / |V
;$10 - Total Length of packet                      | |T~\___!___!___/~T| |
;$12 - Identifier                                  | |`IIII_I_I_I_IIII'| |
;$14 - Flags                                       |  \,III I I I III,/  |
;$15 - Fragment                                     \   `~~~~~~~~~~'    /
;$16 - Time To Live                                   \   .       .   /
;$17 - Protocol                                         \.    ^    ./
;$18 - Checksum                                           ^~~~^~~~^
;$1a - Source IP Address
;$1e - Destination IP Address
;
;ICMP Fields:
;$22 - Type
;$23 - Code
;$24 - Checksum
;$26 - Data
;=============================================================================
;EQUATES

ICMP_T_PONG        = $00
ICMP_T_UNREACHABLE = $03
ICMP_T_SRC	   = $04
ICMP_T_REDIRECT    = $05
ICMP_T_PING        = $08

ICMP_STATE_IDLE	   = $00
ICMP_STATE_REQ	   = $01
ICMP_STATE_REPLY   = $02

;=============================================================================
ICMP_HEADER

ICMP_TYPE	dc.b $00
ICMP_CODE	dc.b $00
ICMP_CHECKSUM	dc.w $0000

ICMP_DATA	ds.b $FC ; $fc bytes is the max data size we'll bother with.

ICMP_DATA_LEN	dc.w $00

ICMP_STATE	dc.b $00 ;0=idle, 1=awaiting ping returns

ICMP_DEST_IP	dc.b $00,$00,$00,$00

;=============================================================================
ICMP_PROCESS	;Process incoming ICMP packet
	lda INPACKET+$22
	cmp #ICMP_T_PONG
	bne ICMP_NOTREPLY
	jsr PING_PONGED ;process pong
	rts
ICMP_NOTREPLY
	cmp #ICMP_T_UNREACHABLE
	bne ICMP_NOTDNU
	;destination unreachable!
	jsr PING_DNU
	rts
ICMP_NOTDNU	
	cmp #ICMP_T_PING
	bne ICMP_NOTREQ
	jsr PING_PINGED ;we've been pinged!
	rts
ICMP_NOTREQ
	rts


;Before ICMP_SEND
;Set Type
;Set Code
;Put Data in ICMP_Data and Set Data Length
;Set Dest IP
;=============================================================================
ICMP_SEND	
;	PRINT 13,"icmp send called",13
	;Generate ICMP Checksum
	jsr ICMP_GEN_CHECKSUM
	;Set IP Protocol to ICMP
	lda #IP_PROTOCOL_ICMP
	jsr IP_SETPROTOCOL
	;Our SRC IP is the stored CARD IP <-Can be optimized out
	lda #<CARD_IP
	ldx #>CARD_IP
	jsr IP_SET_SRC

	lda #<ICMP_DEST_IP
	ldx #>ICMP_DEST_IP
	jsr IP_SETDEST
	
	lda #$80
	jsr IP_SETTTL

	;Copy ICMP Header+Data to IP_DATA
	lda ICMP_DATA_LEN
	clc
	adc #$04
	pha
	
	tax
ICMP_SEND0
	lda ICMP_HEADER-1,x
	sta IP_BUFFER-1,x
	dex
	bne ICMP_SEND0
	pla
	jsr IP_SET_DATALEN

	;Send	
	lda #$00
	sta IP_BCAST
	jmp IP_SEND
	rts
	
	
;=============================================================================
ICMP_SET_TYPE
	sta ICMP_TYPE
	rts

;=============================================================================
ICMP_SET_CODE
	sta ICMP_CODE
	rts

;=============================================================================
ICMP_COPY_DATA ;Expects data address in x:a, number of bytes in y
	sty ICMP_DATA_LEN
	sty ICMPSD_C+1
	stx ICMPSD_0+2
	sta ICMPSD_0+1
	ldx #$00
ICMPSD_0	
	lda $ffff,x
	sta ICMP_DATA,x
	inx
ICMPSD_C
	cpx #$ff
	bne ICMPSD_0
	rts

;=============================================================================
ICMP_SET_DEST_IP
	sta Isd0+$01
	stx Isd0+$02
	ldx #$00
Isd0	lda $FFFF,x
	sta ICMP_DEST_IP,x
	inx
	cpx #$04
	bne Isd0
	rts
;=============================================================================
ICMP_GEN_CHECKSUM
	lda #$00
	sta ICMP_CHECKSUM
	sta ICMP_CHECKSUM+1
	; start to make checksum at start of ICMP header in OUTPACKET
	lda #<ICMP_HEADER
	sta MakeChecksumZp_Ptr
	lda #>ICMP_HEADER
	sta MakeChecksumZp_Ptr+1

	; length of area to make checksum of is the ICMP Header+Data
	lda #$00
	sta MakeChecksumZp_Len+$01
	lda ICMP_DATA_LEN
	clc
	adc #$04
	sta MakeChecksumZp_Len
	bcc icg0
	inc MakeChecksumZp_Len+1
icg0	
	; calculate checksum for the ip header
	jsr MakeChecksum

	; store checksum in packet
	sta ICMP_CHECKSUM
	stx ICMP_CHECKSUM+$01
	rts
	
