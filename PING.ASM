;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 1/26/2006
;
;PING PROTOCOL================================================================
;                                                       _,.-------.,_
;ICMP PACKET FORMAT:                                ,;~'             '~;,
;+----------+---------+-----------+               ,;                     ;,
;|$00-$0d   |$0e-$21  |$22-$24    |              ;                         ;
;+----------+---------+-----------+             ,'        Style 2006       ',
;|MAC Header|IP Header|ICMP Header|            ,;                           ;,
;+----------+---------+-----------+            ; ;      .           .      ; ;
;|$26-$2a   |$2b->    |                        | ;   ______       ______   ; |
;+----------+---------+                        |  `/~"     ~" . "~     "~\'  |
;|PING Hdr  |PING Data|                        |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
;+----------+---------+                         |   |        }:{        |   |
;                                               |   !       / | \       !   |
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
;
;PING Fields:
;$27 - Identifier
;$29 - Sequence Number
;$2b-> - Ping payload

PING_STATE_IDLE	 = $00 ;doing nothing
PING_STATE_REQ   = $01 ;waiting for pong
PING_STATE_REPLY = $02 ;replying to ping
PING_STATE_DNU	 = $03 ;Destination unreachable (idle)

PING_STATE	dc.b $00
PING_MAC 	dc.b $00,$00,$00,$00,$00,$00
PING_IP		dc.b $00,$00,$00,$00

PING_HEADER
PING_IDENT	dc.b $00,$00
PING_SEQUENCE	dc.b $00,$00
PING_DATA	dc.b "sixnet 1.0 ping payload  http://thedarkside.ath.cx/sixnet c64 c64"
PING_DATAEND


PING_REPLYTOPING dc.b $01
PING_PONGTICK    dc.b $00

;Before ICMP_SEND
;Set Type
;Set Code
;Put Data in ICMP_Data and Set Data Length
;Set Dest IP

PING_PING ; PING (PING_IP,PING_MAC)
	;set type
	lda #ICMP_T_PING ;ICMP Echo Request
	jsr ICMP_SET_TYPE
	
	;set code	
	lda #$00
	jsr ICMP_SET_CODE
	
	;set data Expects data address in x:a, number of bytes in y	
	ldx #>PING_HEADER
	lda #<PING_HEADER
	ldy #(PING_DATAEND-PING_HEADER)
	jsr ICMP_COPY_DATA
	
	;set dest IP
	lda #<PING_IP
	ldx #>PING_IP
	jsr ICMP_SET_DEST_IP

	lda #PING_STATE_REQ
	sta PING_STATE
	jsr ICMP_SEND

	inc PING_IDENT
	bne PING_PING_x
	inc PING_IDENT+1
PING_PING_x
	rts

PING_PONG ; PONG (PING_IP)
	;set type
	lda #ICMP_T_PONG ;ICMP Reply
	jsr ICMP_SET_TYPE
	
	;set code
	lda #$00
	jsr ICMP_SET_CODE
	
	;set dest IP
	lda #<(INPACKET+$1a)
	ldx #>(INPACKET+$1a)
	jsr ICMP_SET_DEST_IP
	
	;Get length of ICMP Data by subtracting header size from INPACKET_LENGTH
	lda IN_PACKET_LENGTH
	sta as0
	lda IN_PACKET_LENGTH+$01
	sta as0+$01
	lda #$26 ;length of MAC+IP+ICMP headers
	sta as1
	lda #$00
	sta as1+$01
	jsr sub16
	tay ;screw stuff over 255 bytes
	
	;Copy ICMP Data from incoming packet to outgoing packet
	lda #<(INPACKET+$26)
	ldx #>(INPACKET+$26)
	jsr ICMP_COPY_DATA
	
	jsr ICMP_SEND
	rts

PING_DNU
	lda #PING_STATE_DNU
	sta PING_STATE
	rts

PING_PONGED ; process incoming pong
	;are we waiting for a pong?
	;Is this from the IP we pinged?
;	jsr prns
;	dc.b "PONG",13,0
	lda  #PING_STATE_IDLE
	sta PING_STATE
	rts

PING_PINGED ; Process incoming ping
	;is this ping for our IP?
;	jsr prns
;	dc.b "PINGED",13,0
	lda PING_REPLYTOPING
	beq pipid0
	jsr PING_PONG
pipid0	
	rts
	
