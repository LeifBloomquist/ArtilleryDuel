;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated Feb/3/2006 
;
;ICMP PROTOCOL================================================================
;                                                       _,.-------.,_
;ICMP PACKET FORMAT:                                ,;~'             '~;,
;+----------+---------+-----------+               ,;                     ;,
;|$00-$0d   |$0e-$20  |$21-$      |              ;                         ;
;+----------+---------+-----------+             ,'       Style 2006        ',
;|MAC Header|IP Header|TCP Header |            ,;                           ;,
;+----------+---------+-----------+            ; ;      .           .      ; ;
;                                              | ;   ______       ______   ; |
;MAC Header Fields:                            |  `/~"     ~" . "~     "~\'  |
;$00 - Destination MAC                         |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
;$06 - Source MAC                               |   |        }:{        |   |
;$0c - Packet Type                              |   !       / | \       !   |
;                                               .~  (__,.--" .^. "--.,__)  ~.
;IP Header Fields:                              |     ---;' / | \ `;---     |
;$0e - IP Version                                \__.       \/^\/       .__/
;$0f - Type of Service                            V| \                 / |V
;$12 - Total Length of packet                      | |T~\___!___!___/~T| |
;$13 - Protocol Address Size                       | |`IIII_I_I_I_IIII'| |
;$14 - Opcode                                      |  \,III I I I III,/  |
;                                                   \   `~~~~~~~~~~'    /
;                                                     \   .       .   /
;                                                       \.    ^    ./
;                                                         ^~~~^~~~^
TCP_STATUS_IDLE		= 0

;client status
TCP_STATUS_CONNECTING    = 1   ;Sent SYN PACKET, waiting for SYN-ACK
TCP_STATUS_AWAITING_ACK  = 2   ;Sent Segments, awaiting ACK
TCP_STATUS_AWAITING_DATA = 3   ;Waiting for data (idle)
TCP_STATUS_ACKING        = 4   ;Received Data, sending ACK
TCP_STATUS_FIN_WAIT1     = 5   ;Sent FIN, awaiting ACK
TCP_STATUS_FIN_WAIT2	 = 6   ;Sent Last ACK, awaiting Server Last ACK
TCP_STATUS_TIME_WAIT     = 7   ;Waiting for FIN-RETRY, 


SOCKET_STATUS_CLOSED	   = 1
SOCKET_STATUS_LISTEN	   = 2
SOCKET_STATUS_SYN_SENT	   = 3
SOCKET_STATUS_SYN_RECEIVED = 4
SOCKET_STATUS_ESTABLISHED  = 5



TCP_CLIENT_LOCAL_PORT	dc.w $0064
TCP_CLIENT_REMOTE_PORT	dc.w $0000
TCP_CLIENT_REMOTE_IP	dc.b $00,$00,$00,$00
TCP_CLIENT_STATUS	dc.b $00

TCP_HEADER

TCP_SOURCE_PORT		dc.w $0000
TCP_DEST_PORT		dc.w $0000
TCP_SEQ_NUM		dc.w $0000,$0000
TCP_ACK_NUM		dc.w $0000,$0000
TCP_CONTROL_WORD	dc.w $0000
TCP_WINDOW		dc.w $0000
TCP_CHECKSUM		dc.w $0000
TCP_URGENT		dc.w $0000
TCP_OPTIONS		dc.w $0000,$0000
TCP_DATA		ds.b $400

TCP_PROCESS ;process incoming packet
	rts
;Before TCP_CONNECT
;
TCP_CONNECT


TCP_SEND
;Before TCP_SEND
;Set Source Port
;Set Dest Port
;Set Data Len
;Copy Data 
;Set Dest IP
	;Generate Checksum
	;jsr TCP_GEN_PSEUDO
	;jsr TCP_SET_CSUM

	;lda #IP_PROTOCOL_TCP
	;jsr IP_SETPROTOCOL

	;lda #<CARD_IP
	;ldx #>CARD_IP
	;jsr IP_SET_SRC

	;lda #<TCP_DEST_IP
	;ldx #>TCP_DEST_IP
	;jsr IP_SETDEST
	
	;lda #$80
	;jsr IP_SETTTL

	;Copy UDP Header+Data to IP_DATA
	;lda #<TCP_HEADER
	;sta CPY_SRC
	;lda #>TCP_HEADER
	;sta CPY_SRC+1
	;lda #<IP_DATA
	;sta CPY_DST
	;lda #>IP_DATA
	;sta CPY_DST+1
	;ldx TCP_LEN+1
	;lda TCP_LEN
	;jsr copyblock


	;lda TCP_LEN
	;ldx TCP_LEN+1
	;jsr IP_SET_DATALEN

	;jsr IP_SEND
	rts
	