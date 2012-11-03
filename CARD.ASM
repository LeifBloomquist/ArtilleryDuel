
;CARD LAYER===================================================================
;                                                       _,.-------.,_
;                                                   ,;~'             '~;,
;                                                 ,;                     ;,
;                                                ;                         ;
;                                               ,'        Style2006        ',
;                                              ,;                           ;,
;                                              ; ;      .           .      ; ;
;                                              | ;   ______       ______   ; |
;                                              |  `/~"     ~" . "~     "~\'  |
;                                              |  ~  ,-~~~^~, | ,~^~~~-,  ~  |
; Last Edits 1/26/2006                          |   |        }:{        |   |
; Six of Style                                  |   !       / | \       !   |
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
CARD_STATUS_IDLE = 0;
CARD_STATUS_READING = 1;
CARD_STATUS_WRITING = 2;


;DETECT CARD==================================================================
;Detects net card installed, sets card type, sets carry on error, clears on
;good
CARD_DETECT
	;Check for ETH64
	clc
	lda ETH64_BANK+1
	cmp #$33
	beq ETH_64_FOUND

	;Check for RRNET
	;switch on accessory connector
	lda $de01
	and #%10111000
	ora #%00000001
	sta $de01
	;check for the first 2 magic bytes
	ldy #0			
	jsr RRNET_READPAGE
	cmp #<RRNET_MAGIC
	bne NO_CARD_FOUND
	cpx #>RRNET_MAGIC
	;RR-Net found
	lda #$02
	sta CARD_TYPE
	clc
	rts
NO_CARD_FOUND
	lda #$00
	sta CARD_TYPE
	sec
	rts
ETH_64_FOUND
	lda #$01
	sta CARD_TYPE
	clc
	rts

;INITIALIZE CARD==============================================================
;Initializes detected card, carry set on error
CARD_INIT
	lda CARD_TYPE
	cmp #$01
	bne CARD_I0
	jmp ETH64_INIT
CARD_I0
	cmp #$02
	bne CARD_IE
	jmp RRNET_INIT
CARD_IE
	sec
	rts

	
;POLL FOR PACKET==============================================================
;Polls for packet, returns a=1 if packet available, a=0 if not, carry on error
CARD_POLL
	lda CARD_TYPE
	cmp #$01
	bne CARD_P0
	jmp ETH64_POLL
CARD_P0
	cmp #$02
	bne CARD_PE
	jmp RRNET_POLL
CARD_PE
	sec
	rts
	
;READ PACKET==================================================================
;Reads packet into INPACKET and puts length in IN_PACKET_LENGTH
CARD_READ
	lda CARD_TYPE
	cmp #$01
	bne CARD_R0
	jmp ETH64_READ
CARD_R0
	cmp #$02
	bne CARD_RE
	jmp RRNET_READ
CARD_RE
	sec
	rts
	

;SEND PACKET==================================================================
CARD_SEND
;	PRINT 13,"card send called",13
	lda CARD_TYPE
	cmp #$01
	bne CARD_S0
	jmp ETH64_SEND
CARD_S0
	cmp #$02
	bne CARD_SE
	jmp RRNET_SEND
CARD_SE
	sec
	rts


;DATA=========================================================================
;CARD_STATUS	dc.b $00
;
CONFIGURATION
;
;CFG_LOADED	dc.b $00
;CARD_TYPE	dc.b $02    ; 0=None, 1=ETH64, 2=RR-Net
;CARD_AUTO	dc.b $01    ; 0=auto, 1=static
;CARD_MAC	dc.b $00,$80,$10,$0c,$64,$00 
;CARD_IP		dc.b 192,168,1,66
;CARD_MASK	dc.b 255,255,255,0
;CARD_GATE	dc.b 192,168,1,1
;CARD_NS1	dc.b 0,0,0,0
CONFIG_END
;;end configuration file
;
;CARD_BCAST_IP	dc.b 255,255,255,255
;CARD_BCAST_MAC	dc.b 255,255,255,255,255,255
;CARD_NOMAC	dc.b 0,0,0,0,0,0
;CARD_GATE_MAC	dc.b 0,0,0,0,0,0
CARD_STATUS	dc.b $00
CARD_TYPE	dc.b $00 		     ; 0=None, 1=ETH64, 2=RR-Net
CARD_MAC	dc.b $00,$80,$10,$0c,$64,$06 

CARD_IP		dc.b 192,168,0,128

CARD_MASK	dc.b 255,255,255,0

CARD_GATE	dc.b 192,168,0,1
CARD_NS1	dc.b 216,68,4,10
CARD_BCAST_IP	dc.b 255,255,255,255

CARD_BCAST_MAC	dc.b 255,255,255,255,255,255
CARD_NOMAC	dc.b 0,0,0,0,0,0

CARD_GATE_MAC	dc.b $00,$00,$00,$00,$00,$00
