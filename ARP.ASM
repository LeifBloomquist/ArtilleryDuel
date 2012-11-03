;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 1/25/2006 
;
;ARP PROTOCOL=================================================================
;                                                       _,.-------.,_
;ARP PACKET FORMAT:                                 ,;~'             '~;,
;+----------+----------+--------+                 ,;                     ;,
;|$00-$0d   |$0e-$15   |$16-$29 |                ;                         ;
;+----------+----------+--------+               ,'        Style 2006       ',
;|MAC Header|ARP Header|ARP Data|              ,;                           ;,
;+----------+----------+--------+              ; ;      .           .      ; ;
;                                              | ;   ______       ______   ; |
;MAC Header Fields:                            |  `/~"     ~" . "~     "~\'  |
;$00 - Destination MAC                         |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
;$06 - Source MAC                               |   |        }:{        |   |
;$0c - Packet Type                              |   !       / | \       !   |
;                                               .~  (__,.--" .^. "--.,__)  ~.
;ARP Header Fields:                             |     ---;' / | \ `;---     |
;$0e - Hardware MAC Address Type                 \__.       \/^\/       .__/
;$10 - Protocol Address Type                      V| \                 / |V
;$12 - Hardware MAC Address Size                   | |T~\___!___!___/~T| |
;$13 - Protocol Address Size                       | |`IIII_I_I_I_IIII'| |
;$14 - Opcode                                      |  \,III I I I III,/  |
;                                                   \   `~~~~~~~~~~'    /
;ARP Data Fields                                      \   .       .   /
;$16 - Sender MAC Address                               \.    ^    ./
;$1c - Sender IP Address                                  ^~~~^~~~^
;$20 - Target MAC Address                                
;$26 - Target IP Address
;
ARP_STATE_IDLE  = $00
ARP_STATE_REQ   = $01
ARP_STATE_REPLY = $02

ARP_T_REQUEST = $01
ARP_T_REPLY   = $02

;size of an arp packet sans mac header
ARP_SIZE = $1c

ARP_ADDR_SRC_MAC = $00
ARP_ADDR_DST_MAC = $01
ARP_ADDR_SRC_IP = $02
ARP_ADDR_DST_IP = $03
ARP_ADDR_RES_MAC = $04

ARP_OPCODE_REQUEST = $01
ARP_OPCODE_REPLY   = $02

;ARP Engine State Holder
ARP_STATE	dc.b $00

;Resolved MAC when resolving
ARP_MAC	dc.b $00,$00,$00,$00,$00,$00

ARP_HEADER
ARP_HW_TYPE	dc.b $00,$01 ;Hardware Type <-STATIC
ARP_PROT_TYPE	dc.b $08,$00 ;Protocol Type <-STATIC
ARP_HW_SIZE	dc.b $06     ;HW Size       <-STATIC
ARP_PROT_SIZE	dc.b $04     ;Protocol Size <-STATIC
ARP_OPCODE	dc.b $00,$00

ARP_DATA
ARP_SRC_MAC	dc.b $00,$00,$00,$00,$00,$00
ARP_SRC_IP	dc.b $00,$00,$00,$00
ARP_DST_MAC	dc.b $00,$00,$00,$00,$00,$00
ARP_DST_IP	dc.b $00,$00,$00,$00

ARP_CACHE_I	dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		
ARP_CACHE_M	dc.b $00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00
		;broadcast
MAC_BCAST	dc.b 255,255,255,255,255,255

ARP_CACHE_DEPTH = 5;adjustable

;To Request a MAC-
;Init ARP Header <-Lots of this can be optimized out
;Set SRC MAC+IP <-Can be optimized out
;Set Dest MAC+IP
;call ARP_SEND

;=============================================================================
;Initialize ARP by setting it's state to idle
ARP_INIT
	lda #ARP_STATE_IDLE
	sta ARP_STATE
	rts

;=============================================================================	
;Process a packet which has been pre-determined to be an ARP packet
ARP_PROCESS
	;Is this an ARP Request?
	lda INPACKET+$15
	cmp #ARP_T_REQUEST
	bne notARPREQ
	;It is?  Well, let's reply to the damn thing, then.
	jsr ARP_RESPOND
notARPREQ
	;It's not a request.  Is it an ARP reply?
	lda INPACKET+$15
	cmp #ARP_T_REPLY
	bne ARP_Exit
	jsr ARP_PROCREPLY
ARP_Exit
	rts
;=============================================================================
;Send current ARP packet (expects MAC dst already set)
ARP_SEND 
;	PRINT 13,"arp send called",13

	jsr MAC_SETSRC ;<-This can be optimized out
	;set packet type to ARP ($0806)
	ldx #$08
	lda #$06
	jsr MAC_SETTYPE
	lda #<ARP_HEADER
	ldx #>ARP_HEADER
	jsr MAC_SETDATAADDR
	lda #ARP_SIZE
	ldx #$00
	jsr MAC_SETDATALEN
	jsr MAC_SEND
	rts
	
;=============================================================================
;Process an incoming ARP REPLY
ARP_PROCREPLY
	;Were we actually WAITING for a reply?
	lda ARP_STATE
	cmp #ARP_STATE_REQ
	bne ARP_Exit

	;Compare IP to ARP_IP
	lda INPACKET+$1c
	cmp ARP_DST_IP
	bne ARP_Exit
	lda INPACKET+$1d
	cmp ARP_DST_IP+$01
	bne ARP_Exit
	lda INPACKET+$1e
	cmp ARP_DST_IP+$02
	bne ARP_Exit
	lda INPACKET+$1f
	cmp ARP_DST_IP+$03
	bne ARP_Exit
	;I'll be damned.  It IS the one we were waiting for.
	;Copy it's MAC and we're done
	lda #<(INPACKET+$16)
	ldx #>(INPACKET+$16)
	ldy #ARP_ADDR_RES_MAC
	jsr ARP_SET_ADDR

	;ARP status is now idle again.
	lda #ARP_STATE_IDLE
	sta ARP_STATE
	rts


;=============================================================================
;Build a packet in response to an ARP request for our MAC
;
ARP_RESP_x
	rts
ARP_RESPOND
	;It is?  Well then, is it for our own IP?
	lda INPACKET+$26
	cmp CARD_IP
	bne ARP_RESP_x
	lda INPACKET+$27
	cmp CARD_IP+$01
	bne ARP_RESP_x
	lda INPACKET+$28
	cmp CARD_IP+$02
	bne ARP_RESP_x
	lda INPACKET+$29
	cmp CARD_IP+$03
	bne ARP_RESP_x
;First we must build the MAC header
;Copy Destination MAC to OUTPACKET:00
;We can get this from the packet we're responding to:
	lda #<(INPACKET+$16)
	ldx #>(INPACKET+$16)
	jsr MAC_SETDEST

;Set Opcode to ARP_REPLY
	lda #ARP_OPCODE_REPLY
	jsr ARP_SET_OPCODE

	;My MAC is the source MAC Address <-Can be optimized out
	lda #<CARD_MAC
	ldx #>CARD_MAC
	ldy #ARP_ADDR_SRC_MAC
	jsr ARP_SET_ADDR

	;My IP is the Source IP Address <- Can be optimized out
	lda #<CARD_IP
	ldx #>CARD_IP
	ldy #ARP_ADDR_SRC_IP
	jsr ARP_SET_ADDR

	;Set Dest MAC
	;The INPACKET has the request we're responding to, so let's pull from it.
	lda #<(INPACKET+$16)
	ldx #>(INPACKET+$16)
	ldy #ARP_ADDR_DST_MAC
	jsr ARP_SET_ADDR

	;Set MAC_DEST
	;The INPACKET has the request we're responding to, so let's pull from it.
	lda #<(INPACKET+$16)
	ldx #>(INPACKET+$16)
	jsr MAC_SETDEST

	;Set Dest IP 
	lda #<(INPACKET+$1c)
	ldx #>(INPACKET+$1c)
	ldy #ARP_ADDR_DST_IP
	jsr ARP_SET_ADDR

	;send
	jsr ARP_SEND
	rts
;=============================================================================
;Send a request for a MAC Expects IP at (x:a)
;
ARP_REQUEST
	;Set Dest IP 
	ldy #ARP_ADDR_DST_IP
	jsr ARP_SET_ADDR

	;Set MAC_DEST to Broadcast
	lda #<CARD_BCAST_MAC
	ldx #>CARD_BCAST_MAC
	jsr MAC_SETDEST

	;Set Opcode to ARP_REQUEST
	lda #ARP_OPCODE_REQUEST
	jsr ARP_SET_OPCODE

	;My MAC is the source MAC Address
	lda #<CARD_MAC
	ldx #>CARD_MAC
	ldy #ARP_ADDR_SRC_MAC
	jsr ARP_SET_ADDR

	;My IP is the Source IP Address
	lda #<CARD_IP
	ldx #>CARD_IP
	ldy #ARP_ADDR_SRC_IP
	jsr ARP_SET_ADDR

	;Set Dest MAC
	lda #<CARD_NOMAC
	ldx #>CARD_NOMAC
	ldy #ARP_ADDR_DST_MAC
	jsr ARP_SET_ADDR
	
	;send packet
	jsr ARP_SEND

	;set status
	lda #ARP_STATE_REQ
	sta ARP_STATE
	rts

;=============================================================================
ARP_SET_OPCODE
	sta ARP_OPCODE+1
	lda #$00
	sta ARP_OPCODE
	rts
;=============================================================================
ARP_SET_ADDR ;expects pointer in x:a,
	     ;y = 0 for SRC_MAC
	     ;y = 1 for DST_MAC
	     ;y = 2 for SRC_IP
	     ;y = 3 for DST_IP
	     
	sta ASSM_S+1
	stx ASSM_S+2

	lda ASSM_L,y
	sta ASSM_D+1
	lda ASSM_H,y
	sta ASSM_D+2
	lda ASSM_C,y
	sta ASSM_N+1
	
	ldx #$00
ASSM_S	lda $ffff,x
ASSM_D	sta $ffff,x
	inx
ASSM_N	cpx #$06
	bne ASSM_S
	rts
ASSM_H
	dc.b #>ARP_SRC_MAC,#>ARP_DST_MAC,#>ARP_SRC_IP,#>ARP_DST_IP
	dc.b #>ARP_MAC
ASSM_L
	dc.b #<ARP_SRC_MAC,#<ARP_DST_MAC,#<ARP_SRC_IP,#<ARP_DST_IP
	dc.b #<ARP_MAC
ASSM_C
	dc.b 6,6,4,4,6
;=============================================================================
GET_ARP	;expects IP in x:a, returns carry clear if success,
        ;carry set if timeout or keyhit
        ;returns pointer to resolved MAC in x:a
	
	IPRINT CS_L,CS_R ;This does absolutely nothing, but I can't ping the 64 without it (LB)
	
	;Is this already cached?
	stx GA_x+1
	sta GA_a+1
	jsr ARP_CACHED
	bcs GA_x
	rts ;cache match found, pointer to mac in x:a
	
GA_x	ldx #$00
GA_a	lda #$00
	jsr ARP_REQUEST
	;wait until ARP_REPLY recieved, timeout at 60 seconds or user aborts
	lda #$00
	sta TIMEOUT
	lda $dc08
	sta TICKER
GA_d
	jsr GETIN      ;key hit?
	bne GA_TO
	lda ARP_STATE ;IF ARP_STATE has returned to 0 
	beq GA_X
	lda $dc08
	cmp TICKER ;Ticked?
	beq GA_d ;if not, loop
	sta TICKER
	inc TIMEOUT
	lda TIMEOUT
	cmp #100     ;Timed out?  (LB) was 100
	bne GA_d
GA_TO
	sec
	rts	
GA_X
	lda #<(INPACKET+$16)
	ldx #>(INPACKET+$16)
	jsr ARP_CACHEIT
	clc
	rts


;=============================================================================
ARP_CACHED ;expects pointer to IP in x:a, returns carry set if no match,
	   ;carry set, pointer in x:a to match if match found
	sta ARP_CACHED_2+1	   
	stx ARP_CACHED_2+2

	lda #<ARP_CACHE_I
	sta ARP_CACHED_1+1
	lda #>ARP_CACHE_I
	sta ARP_CACHED_1+2
	
	lda #<ARP_CACHE_M
	sta ARP_CACHED_a+1
	lda #>ARP_CACHE_M
	sta ARP_CACHED_x+1
	
	
	ldy #$00
ARP_CACHED_0	
	ldx #$00
ARP_CACHED_1
	lda ARP_CACHE_I,x
ARP_CACHED_2
	cmp $ffff,x
	bne ARP_CACHED_3
	inx
	cpx #$04
	bne ARP_CACHED_1
	;match was found!
	cpy #$00
	beq ARP_CACHED_x
ARP_CACHED_5
	lda #$06
	clc
	adc ARP_CACHED_a+1
	sta ARP_CACHED_a+1
	bcc ARP_CACHED_6
	inc ARP_CACHED_x+1
ARP_CACHED_6
	dey
	bne ARP_CACHED_5
ARP_CACHED_x
	ldx #$00
ARP_CACHED_a
	lda #$00
	clc
	rts
	
ARP_CACHED_3	
	lda #$04
	clc
	adc ARP_CACHED_1+1
	sta ARP_CACHED_1+1
	bcc ARP_CACHED_4
	inc ARP_CACHED_1+2
ARP_CACHED_4
	iny
	cpy ARP_CACHE_DEPTH
	bne ARP_CACHED_0

ARP_CACHED_NM ;no match found.
	sec
	rts	

;=============================================================================
ARP_CACHEIT 
	stx ARP_CACHEIT_x+1
	sta ARP_CACHEIT_a+1
	
	;rotate bottom 3 entries down by one
	ldx #8
ARP_CACHEIT_0
	lda ARP_CACHE_I,x
	sta ARP_CACHE_I+4,x
	dex
	cpx #$ff
	bne ARP_CACHEIT_0

	ldx #12
ARP_CACHEIT_1
	lda ARP_CACHE_M,x
	sta ARP_CACHE_M+6,x
	dex
	cpx #$ff
	bne ARP_CACHEIT_1

	ldx #$00
ARP_CACHEIT_2	
	lda ARP_DST_IP,x
	sta ARP_CACHE_I,x
	inx
	cpx #$04
	bne ARP_CACHEIT_2

	ldx #$00
ARP_CACHEIT_3	
	lda INPACKET+$16,x
	sta ARP_CACHE_M,x
	inx
	cpx #$06
	bne ARP_CACHEIT_3
ARP_CACHEIT_x	
	ldx #$00
ARP_CACHEIT_a	
	lda #$00
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
;Six of Style 2006
