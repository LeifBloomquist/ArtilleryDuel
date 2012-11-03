;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 8/27/2005 
;
;DNS PROTOCOL=================================================================
;                                                       _,.-------.,_
;   PACKET FORMAT:                                  ,;~'             '~;,
;+----------+----------+----------+               ,;                     ;,
;|$00-$0d   |$0e-$21   |$22-$29   |              ;                         ;
;+----------+----------+----------+             ,'                         ',
;|MAC Header|IP Header |UDP Header|            ,;                           ;,
;+----------+----------+----------+            ; ;      .           .      ; ;
;|                                             | ;   ______       ______   ; |
;                                              |  `/~"     ~" . "~     "~\'  |
;                                              |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
;                                               |   |        }:{        |   |
;                                               |   !       / | \       !   |
;                                               .~  (__,.--" .^. "--.,__)  ~.
;MAC Header Fields:                             |     ---;' / | \ `;---     |
;$00 - Destination MAC (6)                       \__.       \/^\/       .__/
;$06 - Source MAC (6)                             V| \                 / |V
;$0c - Packet Type (2)                             | |T~\___!___!___/~T| |
;                                                  | |`IIII_I_I_I_IIII'| |
;IP Header Fields:                                 |  \,III I I I III,/  |
;$0e - IP Version (1)                               \   `~~~~~~~~~~'    /
;$0f - Type of Service (1)                            \   .       .   /
;$10 - Total Length of packet (2)                       \.    ^    ./
;$12 - Identifier (2)                                     ^~~~^~~~^
;$14 - Flags (1)                   
;$15 - Fragment (1)                
;$16 - Time To Live (1)            
;$17 - Protocol (1)                
;$18 - Checksum (2)                
;$1a - Source IP Address (4)
;$1e - Destination IP Address (4)
;
;UDP Header Fields:
;$22 - Source Port (2)
;$24 - Dest Port (2)
;$26 - Length (2)
;$28 - Checksum (2)
;
;DNS Fields:
;$2a - Identification (2)
;$2c - Flags (2)
;      Control Byte 1 (1)
;      bit 0 - Query/Response
;      bits 1-4 - Opcode
;      bit 5 - Authoritative Answer
;      bit 6 - Truncated
;      bit 7 - Recursion Desired
;      Control Byte 2 (1)
;      bit 0 - Recursion Available
;      bit 1 - Z
;      bit 2 - Authenticated Data
;      bit 3 - Checking Disabled
;      bits 4-7 - Return code
;$2e - Total Questions (2)
;$30 - Total Answer RRs (2)
;$32 - Total Authority RRs (2)
;$34 - Total Additional RRs (2)
;$36 - Questions (Variable Length)
;$?? - Answer RRs (Variable Length)
;$?? - Authority RRs (Variable Length)
;$?? - Additional RRs (Variable Length)

DNS_STATUS_IDLE = $00
DNS_STATUS_QUERY = $01

DNS_FLAGS_QUERY = $0100

DNS_SOURCE_PORT = 3159

DNS_TYPE_HOST	= $0001
DNS_CLASS_INET	= $0001

DNS_STATUS	dc.b #DNS_STATUS_IDLE

DNS_HEADER
DNS_IDENT	dc.b $00,$00 ;Transaction ID
DNS_FLAGS	dc.b $01,$00

DNS_QUESTIONS	dc.b $00,$01
DNS_ANSRR	dc.b $00,$00
DNS_AUTHRR	dc.b $00,$00
DNS_ADDITION	dc.b $00,$00

DNS_NAMBUF	dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00
		
DNS_QUERY_TYPE	dc.b $00,$01
DNS_CLASS	dc.b $00,$01

DNS_NAMLEN	dc.b $00 ;should include trailing null

DNS_ANSADDR	dc.b $00,$00 ;holder for answer offset, calced at query time
			     ;(INPACKET+$36)+DNS_NAMLEN+$04

DNS_RESIP	dc.b 0,0,0,0 ;holder for resolved IP

DNS_PROCESS ;process incoming DNS packet
	;IPRINT "processing dns packet"	
	;Check Transaction ID
	lda INPACKET+$2a
	cmp DNS_IDENT
	bne DNP_0
	lda INPACKET+$2b
	cmp DNS_IDENT+1
	bne DNP_0
	;This is the one we were waiting for
	;calculate Answer base
	;INPACKET+$3a+NAMELEN+$0d ($47+NAMELEN)
	lda #<(INPACKET+$47)
	sta DNS_ANSADDR
	lda #>(INPACKET+$47)
	sta DNS_ANSADDR+1
	lda DNS_NAMLEN
	clc
	adc DNS_ANSADDR
	sta DNS_ANSADDR
	bcc DNP_1
	inc DNS_ANSADDR+1
DNP_1	
	;IP is at (DNS_ANSADDR)
	lda DNS_ANSADDR
	sta DNP_L+1
	lda DNS_ANSADDR+1
	sta DNP_L+2
		
	ldx #$00
DNP_L	lda $ffff,x
	sta DNS_RESIP,x
	inx
	cpx #$04
	bne DNP_L
	lda #DNS_STATUS_IDLE
	sta DNS_STATUS
DNP_0 
	rts

;Before DNS_SEND
;Set Transaction Ident
;Set Flags
;Set Num of Questions

DNS_REQUEST 	
	lda #DNS_STATUS_QUERY
	sta DNS_STATUS
	;generate IDENT
	lda $dc08
	sta DNS_IDENT
	lda $dc09
	sta DNS_IDENT+1
	
	;Set UDP Source Port
	ldx #>DNS_SOURCE_PORT
	lda #<DNS_SOURCE_PORT
	jsr UDP_SET_SRC_PORT
	
	;Set UDP Dest Port	
	ldx #$00
	lda #53
	jsr UDP_SET_DEST_PORT

	;set UDP Data length to $10 + DNS_NAMLEN
	ldx #$00
	lda DNS_NAMLEN
	clc
	adc #$11;0
	bcc DNR_4
	inx
DNR_4
	jsr UDP_SET_DATALEN
	
	;COpy Data
	ldx #$00
DNR_5
	lda DNS_HEADER,x
	sta UDP_DATA,x
	inx
	cpx #$0c
	bne DNR_5
	
	;Copy Name into UDP_DATA
	ldy #$00
DNR_0
	lda DNS_NAMBUF,y
	sta UDP_DATA+$0c,y
	iny
	cpy DNS_NAMLEN
	bne DNR_0
DNR_C
	;Insert Query Type and Class
	iny
	ldx #$00
DNR_D
	lda DNS_QUERY_TYPE,x
	sta UDP_DATA+$0c,y
	inx
	iny
	cpx #$04
	bne DNR_D
	
	;set dest ip
	lda #<CARD_NS1
	ldx #>CARD_NS1
	jsr UDP_SET_DEST_IP
	
;Before UDP_SEND
;Set Source Port  check
;Set Dest Port    check
;Set Data Len     check
;Copy Data  check
;Set Dest IP check
	
	lda #$00
	sta UDP_BCAST
	jsr UDP_SEND
	rts

DNS_PTR	dc.b $00

DNS_SETNAME ;Expectx x:a to point to a nts, returns len (including null) in y
            ;processes domain name to acceptable format (len)string(len)string, etc...

	sta DNS_TMP
	stx DNS_TMP+1
	ldy #$00
	ldx #$00
	sty DNS_PTR ;initial prevloc is $00
DNS_SN0
	lda (DNS_TMP),y
	beq DNS_SN1 ;Is it a $00?
	cmp #$2e    ;is it a dot?
	bne DNS_SN3
	;store char count in previous location
	txa
	ldx DNS_PTR
	sta DNS_NAMBUF,x
	;set location to current
	tya
	clc
	adc #$01
	sta DNS_PTR
	;start char count back at -1 (to account for the current char)
	ldx #$ff
DNS_SN3
	sta DNS_NAMBUF+1,y
	inx ;inc char count
	iny
	cpy #$f0 ;max out at $f0
	bne DNS_SN0
	lda #$00
DNS_SN1 
	;store final null byte
	sta DNS_NAMBUF+1,y
	iny
	
	;store final length
	sty DNS_NAMLEN
DNS_SN2	
	;stash final strlen
	txa
	ldx DNS_PTR
	sta DNS_NAMBUF,x
	rts


DNS_RESOLVER
	PRINT CRLF,"resolve:"
; (LB)
;	INPUT SEND_DOMAIN,80
;	PRINT CRLF,"resolving..."
;	ldx #>SEND_DOMAIN
;	lda #<SEND_DOMAIN
	jsr DNS_SETNAME
	jsr DNS_REQUEST
DNRE_0	lda DNS_STATUS
	bne DNRE_0
	PRINT CRLF
	ldx #>DNS_RESIP
	lda #<DNS_RESIP
	jsr printip
	jsr getanykey
	rts
