;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 8/24/2005 
;
;=============================================================================
;ETH64 CONSTANTS
ETH64_BASE    = $de10 	   	 ;ETH64 Base Address
ETH64_BANK    = ETH64_BASE+$0e   ;Bank select register             R/W (2B)

;Register bank 0 
ETH64_TCR     = ETH64_BASE       ;Transmition control register     R/W (2B)
ETH64_EPHSR   = ETH64_BASE+$02   ;EPH status register              R/O (2B)
ETH64_RCR     = ETH64_BASE+4     ;Receive control register         R/W (2B)
ETH64_ECR     = ETH64_BASE+6     ;Counter register                 R/O (2B)
ETH64_MIR     = ETH64_BASE+8     ;Memory information register      R/O (2B)
ETH64_MCR     = ETH64_BASE+$0a   ;Memory Config. reg.    +0 R/W +1 R/O (2B)

;Register bank 1 
ETH64_CR      = ETH64_BASE       ;Configuration register           R/W (2B)
ETH64_BAR     = ETH64_BASE+2     ;Base address register            R/W (2B)
ETH64_IAR     = ETH64_BASE+4     ;Individual address register      R/W (6B)
ETH64_GPR     = ETH64_BASE+$0a   ;General address register         R/W (2B)
ETH64_CTR     = ETH64_BASE+$0c   ;Control register                 R/W (2B)

;Register bank 2 
ETH64_MMUCR   = ETH64_BASE       ;MMU command register             W/O (1B)
ETH64_AUTOTX  = ETH64_BASE+1     ;AUTO TX start register           R/W (1B)
ETH64_PNR     = ETH64_BASE+2     ;Packet number register           R/W (1B)
ETH64_ARR     = ETH64_BASE+3     ;Allocation result register       R/O (1B)
ETH64_FIFO    = ETH64_BASE+4     ;FIFO ports register              R/O (2B)
ETH64_PTR     = ETH64_BASE+6     ;Pointer register                 R/W (2B)
ETH64_DATA    = ETH64_BASE+8     ;Data register                    R/W (4B)
ETH64_IST     = ETH64_BASE+$0c   ;Interrupt status register        R/O (1B)
ETH64_ACK     = ETH64_BASE+$0c   ;Interrupt acknowledge register   W/O (1B)
ETH64_MSK     = ETH64_BASE+$0d   ;Interrupt mask register          R/W (1B)

;Register bank 3 
ETH64_MT      = ETH64_BASE       ;Multicast table                  R/W (8B)
ETH64_MGMT    = ETH64_BASE+8     ;Management interface             R/W (2B)
ETH64_REV     = ETH64_BASE+$0a   ;Revision register                R/W (2B)
ETH64_ERCV    = ETH64_BASE+$0c   ;Early RCV register               R/W (2B)

;=============================================================================
;ETH64 SEND PACKET
ETH64_SEND
;bank 2
	lda #$02
	sta ETH64_BANK
;only allocate one block
	lda #$00
	ora #%00100000        ;Command 0010: Allocate Memory for TX
  	sta ETH64_MMUCR

;Wait for up to 200us
	ldx #8                 
lan91c96_send3                   
	lda ETH64_IST
  	and #%00001000        ;Check ALLOC_INT on status register
  	bne lan91c96_send4
  	dex
  	bne lan91c96_send3
	rts		      ;Choked, return (error?)
	
lan91c96_send4
;Acknowledge int.
	lda #%00001000        
  	sta ETH64_ACK

  	lda ETH64_ARR	      ;Get address from Allocation Result Register
  	sta ETH64_PNR	      ;And use it to set our packet address

  	lda #0
  	sta ETH64_PTR
  	lda #%01000000        ;AUTO INCR.
  	sta ETH64_PTR+1

  	lda #0                ;Status written by CSMA
 	sta ETH64_DATA
  	sta ETH64_DATA
;Packet size is $2a + overhead (6 bytes) = $30
	lda #$2f 	      ;packet length lo-byte
 	sta ETH64_DATA
  	lda #$00 	      ;packet length hi-byte
  	sta ETH64_DATA

;Write actual packet to Transmit 
	ldx #$00	
lan91c96_sendloop
	lda OUTPACKET,x
	sta ETH64_DATA
	inx
	cpx #$2a
	bne lan91c96_sendloop
  	lda #%00100000
  	sta ETH64_DATA        ;Control byte
  	lda #%11000000        ;ENQUEUE PACKET - transmit packet
  	sta ETH64_MMUCR
	rts


ETH64_READ
 	inc RXCOUNT
 	bne ETH64_Read1
 	inc RXCOUNT+$01
ETH64_Read1
	lda #0
 	sta ETH64_PTR
 	lda #%11100000               ;RCV,AUTO INCR.,READ
 	sta ETH64_PTR+1
 	lda ETH64_DATA               ;Status word
 	lda ETH64_DATA
 	sta IN_PACKET_STATUS            ;High byte only
 	lda ETH64_DATA               ;Total number of bytes
 
 	sta IN_PACKET_LENGTH
 	lda ETH64_DATA
 	sta IN_PACKET_LENGTH+1
 ; Last word contain 'last data byte' and $60 
 ; or 'fill byte' and $40 
 	clc
 	lda IN_PACKET_LENGTH+1
 	sbc #$06
 	bcc ETH64_Read2
 	dec IN_PACKET_LENGTH
ETH64_Read2
 ;The packet contains 3 extra words
 ;packet_length -= 6
 	lda IN_PACKET_STATUS
 	and #$10
 	beq ETH64_Read3
 	inc IN_PACKET_LENGTH+1
 	bne ETH64_Read3
 	inc IN_PACKET_LENGTH
ETH64_Read3
 ;Set zero-page pointer to our incoming packet area.
   	lda #<INPACKET
   	sta RECV_PTR
   	lda #>INPACKET
   	sta RECV_PTR+$01
 ;Read in packet to our incoming packet buffer
   	ldy #$00
   	ldx IN_PACKET_LENGTH+$01
   	beq ETH64_Read4      ;packet_length < 256
R5
   	lda ETH64_DATA
   	sta (RECV_PTR),y
   	iny
   	bne R5
   	inc RECV_PTR+1
   	dex
   	bne R5
ETH64_Read4
   	lda ETH64_DATA
   	sta (RECV_PTR),y
   	iny
   	cpy IN_PACKET_LENGTH
   	bne ETH64_Read4
 ;Remove and release RX packet from FIFO
 	lda #%10000000
   	sta ETH64_MMUCR
 	rts

;=============================================================================
;ETH64 POLL FOR PACKET

ETH64_POLL
	;Select Bank 2
	lda #$02
	sta ETH64_BANK
	lda ETH64_IST
	sta $0400
	and #%00000001                ;RCV INT
	bne ETH64_P0
	;No packet available 
	lda #$00
	clc
	rts
ETH64_P0 ;packet
	lda #$01
	clc
	rts



ETH64_INIT
	;Select Bank 0
	lda #$00
	sta ETH64_BANK
	; Reset ETH card 
	lda #%10000000             ;Software reset
	sta ETH64_RCR+1
	lda #0
	sta ETH64_RCR
	sta ETH64_RCR+1
	; delay 
	ldx #0
ETH64_init2:
	cmp ($ff,x)                ;6 cycles
	cmp ($ff,x)                ;6 cycles
	dex                        ;2 cycles
	bne ETH64_init2            ;3 cycles
                                   ;17*256=4352 => 4,4 ms
	; Enable transmit and receive 
	lda #%10000001             ;Enable transmit TXENA, PAD_EN
	sta ETH64_TCR
	lda #%00000010	 	   ;promisc mode
	sta ETH64_RCR
	lda #%00000011        	   ;Enable receive, strip CRC ???
	sta ETH64_RCR+1
	lda ETH64_CR+1
	ora #%00010000             ;No wait (IOCHRDY)
	sta ETH64_CR+1
	lda #%00001001             ;Auto release
	sta ETH64_CTR+1
	;Select Bank 1
	lda #$01
	sta ETH64_BANK
	; Set MAC address 
	lda CARD_MAC
	sta ETH64_IAR
	lda CARD_MAC+1
	sta ETH64_IAR+1
	lda CARD_MAC+2
	sta ETH64_IAR+2
	lda CARD_MAC+3
	sta ETH64_IAR+3
	lda CARD_MAC+4
	sta ETH64_IAR+4
	lda CARD_MAC+5
	sta ETH64_IAR+5
	;Set ETH64 Interrupt Mask
	lda #%00001111               ;RCV INT, ALLOC INT, TX INT, TX EMPTY
	sta ETH64_MSK
	clc
	rts
