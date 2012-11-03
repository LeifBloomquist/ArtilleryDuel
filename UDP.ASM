;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 1/26/2006
;
;UDP PROTOCOL=================================================================
;                                                       _,.-------.,_
;IP PACKET FORMAT:                                  ,;~'             '~;,
;+----------+----------+----------+----+          ,;                     ;,
;|$00-$0d   |$0e-$21   |$22-$29   |$2a-|         ;                         ;
;+----------+----------+----------+----+        ,'                         ',
;|MAC Header|IP Header |UDP Header|Data|       ,;                           ;,
;+----------+----------+----------+----+       ; ;      .           .      ; ;
;                                              | ;   ______       ______   ; |
;MAC Header Fields:                            |  `/~"     ~" . "~     "~\'  |
;$00 - Destination MAC (6)                     |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
;$06 - Source MAC (6)                           |   |        }:{        |   |
;$0c - Packet Type (2)                          |   !       / | \       !   |
;                                               .~  (__,.--" .^. "--.,__)  ~.
;IP Header Fields:                              |     ---;' / | \ `;---     |
;$0e - IP Version (1)                            \__.       \/^\/       .__/
;$0f - Type of Service (1)                        V| \                 / |V
;$10 - Total Length of packet (2)                  | |T~\___!___!___/~T| |
;$12 - Identifier (2)                              | |`IIII_I_I_I_IIII'| |
;$14 - Flags (1)                                   |  \,III I I I III,/  |
;$15 - Fragment (1)                                 \   `~~~~~~~~~~'    /
;$16 - Time To Live (1)                               \   .       .   /
;$17 - Protocol (1)                                     \.    ^    ./
;$18 - Checksum (2)                                       ^~~~^~~~^
;$1a - Source IP Address (4)
;$1e - Destination IP Address (4)
;
;UDP Header Fields:
;$22 - Source Port (2)
;$24 - Dest Port (2)
;$26 - Length (2)
;$28 - Checksum (2)
UDP_BCAST	dc.b $00
UDP_PSEUDO_HEADER
UDP_PSEUDO_SRC	dc.b $00,$00,$00,$00
UDP_PSEUDO_DEST	dc.b $00,$00,$00,$00
UDP_PSEUDO_PROTOCOL	dc.b 00,17
UDP_PSEUDO_LENGTH	dc.b $00,$00

UDP_HEADER
UDP_SRC	  dc.b $00,$00
UDP_DEST  dc.b $00,$00
UDP_PLEN  dc.b $00,$00
UDP_CSUM  dc.b $23,$cf;$00,$00

UDP_DATA  ds.b $300

UDP_DEST_IP   dc.b $00,$00,$00,$00
UDP_LEN	dc.b $00,$00
UDP_INIT

UDP_PROCESS ;process according to ports
	;IPRINT "processing UDP Packet"
	;Check for incoming DNS packets
	lda INPACKET+$24
	cmp #>DNS_SOURCE_PORT
	bne UDP_PROC_USER  ;(LB)
	lda INPACKET+$25
	cmp #<DNS_SOURCE_PORT
	bne UDP_PROC_USER  ;(LB)
	jsr DNS_PROCESS
	
	; Check for my UDP packets (LB)
UDP_PROC_USER
  ;Check for incoming USER packets
	lda INPACKET+$24 
	cmp #>USER_DEST_PORT  
	bne UDP_PROC_2
	lda INPACKET+$25
	cmp #<USER_DEST_PORT
	bne UDP_PROC_2
	jsr MYUDP_PROCESS
	rts	

  ;(LB) - removed, not using TFTP	
;UDP_PROC1
;	;Check for incoming TFTP packets
;	lda INPACKET+$24
;	cmp #>TFTP_SRC_PORT
;	bne UDP_PROC_2
;	lda INPACKET+$25
;	cmp #<TFTP_SRC_PORT
;	bne UDP_PROC_2
;	jmp TFTP_PROCESS
UDP_PROC_2
	;Check for incoming DHCP Replies
	lda INPACKET+$24
	cmp #>DHCP_SRC_PORT
	bne UDP_PROC_x
	lda INPACKET+$25
	cmp #<DHCP_SRC_PORT
	bne UDP_PROC_x
	jmp DHCP_PROCESS
UDP_PROC_x
	rts

;Before UDP_SEND
;Set Source Port
;Set Dest Port
;Set Data Len
;Copy Data 
;Set Dest IP
UDP_SEND
	jsr UDP_GEN_PSEUDO
	jsr UDP_SET_CSUM
	lda #IP_PROTOCOL_UDP
	jsr IP_SETPROTOCOL
	lda #<CARD_IP
	ldx #>CARD_IP
	jsr IP_SET_SRC

	lda UDP_BCAST
	beq UDP_SEND0
	lda #$01
	jsr IP_SET_BCAST
	jmp UDP_SEND1
UDP_SEND0
	lda #<UDP_DEST_IP
	ldx #>UDP_DEST_IP
	jsr IP_SETDEST
UDP_SEND1	
	lda #$80
	jsr IP_SETTTL

	;Copy UDP Header+Data to IP_DATA
	lda #<UDP_HEADER
	sta CPY_SRC
	lda #>UDP_HEADER
	sta CPY_SRC+1
	lda #<IP_DATA
	sta CPY_DST
	lda #>IP_DATA
	sta CPY_DST+1
	ldx UDP_LEN+1
	lda UDP_LEN
	jsr copyblock


	lda UDP_LEN
	ldx UDP_LEN+1
	jsr IP_SET_DATALEN

	jsr IP_SEND
	rts
	
UDP_SET_SRC_PORT ;expects source port in x:a
	stx UDP_SRC
	sta UDP_SRC+1
	rts
	
UDP_SET_DEST_PORT ;expects dest port in x:a
	stx UDP_DEST
	sta UDP_DEST+1
	rts

UDP_SET_DEST_IP ;expects pointer in x:a
	sta USDI_0+1
	stx USDI_0+2
	ldx #$00
USDI_0	lda $ffff,x
	sta UDP_DEST_IP,x
	inx
	cpx #$04
	bne USDI_0
	rts
	
UDP_SET_DATALEN ;Expects len in x:a
	stx UDP_LEN+1
	sta UDP_LEN
	clc
	adc #$08 ;Size of UDP Header
	sta UDP_LEN
	bcc UDP_SDL1
	inc UDP_LEN+1
UDP_SDL1
	lda UDP_LEN+1
	sta UDP_PLEN
	lda UDP_LEN
	sta UDP_PLEN+1

	rts	

UDP_GEN_PSEUDO
	ldx #$00
UDPGP_0
	lda CARD_IP,x
	sta UDP_PSEUDO_SRC,x
	lda UDP_DEST_IP,x
	sta UDP_PSEUDO_DEST,x
	inx
	cpx #$04
	bne UDPGP_0
	lda UDP_PLEN
	sta UDP_PSEUDO_LENGTH
	lda UDP_PLEN+1
	sta UDP_PSEUDO_LENGTH+1
	rts
	

UDP_SET_CSUM ;Routine by Doc Bacardi from RRNet Source
	; clear checksum field
	lda #0
	sta UDP_CSUM
	sta UDP_CSUM+$01
	; start to make checksum at start of UDP pseudo header
	lda #<(UDP_PSEUDO_HEADER)
	sta MakeChecksumZp_Ptr
	lda #>(UDP_PSEUDO_HEADER)
	sta MakeChecksumZp_Ptr+1

	; length of area to make checksum of is the $0c+LEN(UDP header+data)
	lda UDP_LEN
	sta MakeChecksumZp_Len
	lda UDP_LEN+1
	sta MakeChecksumZp_Len+1

	lda #$0c
	clc
	adc MakeChecksumZp_Len
	sta MakeChecksumZp_Len
	bcc UDP_SC0
	inc MakeChecksumZp_Len+1
UDP_SC0
	jsr MakeChecksum

	sta UDP_CSUM
	stx UDP_CSUM+1
	rts



	
