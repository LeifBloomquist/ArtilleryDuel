;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 1/25/2006 
;
;IP PROTOCOL==================================================================
;                                                       _,.-------.,_
;IP PACKET FORMAT:                                  ,;~'             '~;,
;+----------+----------+---------+                ,;                     ;,
;|$00-$0d   |$0e-$21   |$22->    |               ;                         ;
;+----------+----------+---------+              ,'                         ',
;|MAC Header|IP Header |IP Data  |             ,;                           ;,
;+----------+----------+---------+             ; ;      .           .      ; ;
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

IP_PROTOCOL_ICMP = 1
IP_PROTOCOL_TCP  = 6
IP_PROTOCOL_UDP  = 17

IP_BCAST	dc.b 0
IP_BCASTIP	dc.b 255,255,255,255
IP_BCASTIPMAC	dc.b 255,255,255,255,255,255
IP_HEADER

IP_VERSION	dc.b $45	;Version and IHL (STATIC)
IP_TOS		dc.b $00	;Type of Service (STATIC)
IP_TOTAL_LEN	dc.w $0000	;Total Length of packet (H:L)(-MAC Header Length)
IP_IDENTIFIER	dc.w $0000	;Packet Identifier (STATIC) <-Not Good
IP_FLAGS	dc.b $40	;Flags (STATIC)
IP_FRAGMENT	dc.b $00	;Fragment (STATIC)
IP_TTL		dc.b $FF	;TTL 
IP_PROTOCOL	dc.b $00	
IP_CHECKSUM	dc.w $0000
IP_SOURCE	dc.w $0000,$0000
IP_DEST		dc.w $0000,$0000
IP_DATA
IP_BUFFER	ds.b $1000 	;4k buffer
IP_DATALEN	dc.b $00,$00

		;broadcast

;=============================================================================
;Initialize IP
IP_INIT
	lda #<CARD_IP
	ldx #>CARD_IP
	jsr IP_SET_SRC
	rts
;=============================================================================
;Process incoming IP Packet
IP_PROCESS ;act on incoming IP Packet
	lda INPACKET+$17
	cmp #IP_PROTOCOL_ICMP  ;Is this an ICMP packet?
	bne NOT_ICMP
	;(LB) This doesn't do anything, but the fact that it is here makes incoming pings work.  Bizarre!
  ;IPRINT "ICMP PACKET RECEIVED",13
	jmp ICMP_PROCESS
	
NOT_ICMP
	cmp #IP_PROTOCOL_UDP
	bne NOT_UDP
	jmp UDP_PROCESS
	
NOT_UDP
	cmp #IP_PROTOCOL_TCP
	bne NOT_TCP
	jmp TCP_PROCESS
NOT_TCP
	rts

;=============================================================================
IP_SEND ;expects header to already be built. 
;	PRINT 13,"ip send called",13

	jsr IP_SETCHECKSUM
	lda IP_BCAST
	beq IP_SEND3 ;is this a broadcast packet?
	lda #<IP_BCASTIP
	ldx #>IP_BCASTIP
	jsr IP_SETDEST
	lda #<IP_BCASTIPMAC
	ldx #>IP_BCASTIPMAC
	jmp IP_SEND2
IP_SEND3
	lda #<IP_DEST
	ldx #>IP_DEST
	jsr IPMASK
	bcc IP_SEND1
	;external IP, use GW_MAC
	lda #<CARD_GATE_MAC
	ldx #>CARD_GATE_MAC
	jmp IP_SEND2
IP_SEND1 ;internal IP, resolve its MAC and set it
	lda #<IP_DEST
	ldx #>IP_DEST
	jsr GET_ARP
	bcc IP_SEND2
	jmp IP_SEND_ERR
IP_SEND2
	jsr MAC_SETDEST
	;set source MAC
	jsr MAC_SETSRC ;<-This can be optimized out!
	;set MAC Type
	ldx #$08
	lda #$00
	jsr MAC_SETTYPE
	;Set MAC Data Addr 
	lda #<IP_HEADER
	ldx #>IP_HEADER
	jsr MAC_SETDATAADDR
	;SET MAC Data Length (H:L to L:H)
	lda IP_TOTAL_LEN+1
	ldx IP_TOTAL_LEN
	jsr MAC_SETDATALEN
;	PRINT 13,"ip calling mac send",13
	jmp MAC_SEND
IP_SEND_ERR
	sec
	rts
;Before IP_SEND
;Set Protocol
;Set Source
;Set Dest
;Set TTL
;Copy Data in and set data len
;=============================================================================
IP_SETPROTOCOL ; Expects protocol in a
	sta IP_PROTOCOL
	rts
;=============================================================================
IP_SET_SRC	;expects pointer to ip in x:a
	stx IP_SSS+2
	sta IP_SSS+1
	ldx #$00
IP_SSS	lda $ffff,x
	sta IP_SOURCE,x
	inx
	cpx #$04
	bne IP_SSS
	rts
;=============================================================================
IP_SETDEST ;Expects dest ip addr in (x:a)
	sta IP_SD1+$01
	stx IP_SD1+$02
	ldx #$00
IP_SD1	lda $FFFF,x
	sta IP_DEST,x
	inx
	cpx #$04
	bne IP_SD1
	rts
;=============================================================================
IP_SETTTL
	sta IP_TTL
	rts
;=============================================================================
IP_SET_DATALEN ;expects length of data in IP_BUFFER in x:a
	stx IP_TOTAL_LEN
	sta IP_TOTAL_LEN+$01
	;add length of IP header ($14)
	lda #$14
	clc
	adc IP_TOTAL_LEN+1
	sta IP_TOTAL_LEN+1
	bcc IPDL_0
	inc IP_TOTAL_LEN
IPDL_0
	rts
;=============================================================================
IP_SETCHECKSUM ;Routine by Doc Bacardi from RRNet Source
	; clear checksum field
	lda #0
	sta IP_CHECKSUM
	sta IP_CHECKSUM+$01

	; start to make checksum at start of ip header
	lda #<IP_HEADER
	sta MakeChecksumZp_Ptr
	lda #>IP_HEADER
	sta MakeChecksumZp_Ptr+1

	; length of area to make checksum of is the ip header
	lda #$14
	sta MakeChecksumZp_Len
	lda #$00
	sta MakeChecksumZp_Len+1

	; calculate checksum for the ip header
	jsr MakeChecksum

	; store checksum in header
	sta IP_CHECKSUM
	stx IP_CHECKSUM+1
	rts
;=============================================================================
IP_SET_FRAG
	rts

IP_SET_BCAST
	sta IP_BCAST
	rts
