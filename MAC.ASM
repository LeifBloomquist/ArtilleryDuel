;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 1/26/2006 
;
;MAC PROTOCOL=================================================================
;                                                       _,.-------.,_
;MAC PACKET FORMAT:                                 ,;~'             '~;,
;+----------+                                     ,;                     ;,
;|$00-$0d   |                                    ;                         ;
;+----------+                                   ,'        Style2006        ',
;|MAC Header|                                  ,;                           ;,
;+----------+                                  ; ;      .           .      ; ;
;                                              | ;   ______       ______   ; |
;MAC Header Fields:                            |  `/~"     ~" . "~     "~\'  |
;$00 - Destination MAC                         |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
;$06 - Source MAC                               |   |        }:{        |   |
;$0c - Packet Type                              |   !       / | \       !   |
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
;                                                        
MAC_STATUS_IDLE = 0;
MAC_STATUS_BUSY	= 1;

MAC_HEADER
MAC_DEST	dc.b $00,$00,$00,$00,$00,$00
MAC_SRC		dc.b $00,$00,$00,$00,$00,$00
MAC_TYPE	dc.w $00

MAC_DATALEN	dc.b $00,$00
MAC_DATAADDR	dc.b $00,$00
MAC_STATUS	dc.b $00

;Procedure for sending -
;Wait until MAC_STATUS = MAC_IDLE
;Set MAC_DEST
;Set MAC_SRC <- can be optimized out
;Set MAC_TYPE
;Set MAC_DATALEN
;Set MAC_DATAADDR
;jsr MAC_SEND


;=============================================================================	
MAC_INIT
	lda #MAC_STATUS_IDLE
	sta MAC_STATUS
	rts
;=============================================================================	
MAC_PROCESS
;First, is this an arp packet?
	lda INPACKET+$0c	
	cmp #$08
	bne UPT ;Unknown Packet Type
	lda INPACKET+$0d
	bne notIP

	jmp IP_PROCESS
notIP
	cmp #$06 ;Is it an ARP packet?
	bne UPT

	jmp ARP_PROCESS
UPT
	rts
;=============================================================================	
MAC_SEND ;expects nothing.
;	PRINT 13,"mac send called",13
	lda #MAC_STATUS_BUSY
	sta MAC_STATUS
	
	;set outpacket length = mac_datalen+$0e
	lda MAC_DATALEN+1
	sta OUT_PACKET_LENGTH+1
	lda MAC_DATALEN
	clc
	adc #$0e
	sta OUT_PACKET_LENGTH
	bcc MAC_SENDA
	inc OUT_PACKET_LENGTH+1
	
MAC_SENDA	
	;generate outpacket
	ldx #$00
MAC_SEND0
	lda MAC_HEADER,x
	sta OUTPACKET,x
	inx
	cpx #$0e
	bne MAC_SEND0

	;copy data into outpacket
	
	lda MAC_DATAADDR
	sta CPY_SRC
	lda MAC_DATAADDR+1
	sta CPY_SRC+1
	lda #<(OUTPACKET+$0e)
	sta CPY_DST
	lda #>(OUTPACKET+$0e)
	sta CPY_DST+1
	ldx MAC_DATALEN+1
	lda MAC_DATALEN
	jsr copyblock
	
	jsr CARD_SEND

	lda #MAC_STATUS_IDLE
	sta MAC_STATUS
	rts
;=============================================================================	
MAC_SETDATALEN ; expects data length in (x:a)
	sta MAC_DATALEN
	stx MAC_DATALEN+1
	rts
;=============================================================================	
MAC_SETDATAADDR ; expects data ADDR (x:a)
	sta MAC_DATAADDR
	stx MAC_DATAADDR+1
	rts
;=============================================================================	
MAC_SETDEST ; expects dest MAC in (x:a)
	
	sta MAC_SD1+$01
	stx MAC_SD1+$02
	ldx #$00
MAC_SD1
	lda $ffff,x
	sta MAC_DEST,x
	inx
	cpx #$06
	bne MAC_SD1
	rts
;=============================================================================	
MAC_SETSRC ;sets source to card_MAC
	
	lda CARD_MAC
	sta MAC_SRC
	lda CARD_MAC+1
	sta MAC_SRC+1
	lda CARD_MAC+2
	sta MAC_SRC+2
	lda CARD_MAC+3
	sta MAC_SRC+3
	lda CARD_MAC+4
	sta MAC_SRC+4
	lda CARD_MAC+5
	sta MAC_SRC+5
	rts
;=============================================================================	
MAC_SETTYPE ;Expects packet type in (x:a)
	stx MAC_TYPE
	sta MAC_TYPE+1
	rts
	
;That's all, folks.  Time for a beer
;
;        [~]
;        |=|
;      .-' '-.
;      |-----|  Warsteiner
;      | ~~~ |  "Die Konigen unter den bieren"
;      | ~~~ |
;      | WAR |
;      |-----|
;      '-----'
;
;
;
;Six of DLoC 2004
