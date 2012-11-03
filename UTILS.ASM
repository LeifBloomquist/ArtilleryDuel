;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 8/24/2005 


getanykey
	PRINT 13,146,5,"PRESS ANY KEY TO CONTINUE",13 ;(LB)
gak0
	jsr GETIN
	beq gak0
	rts

px	dc.b $00
py	dc.b $00
pa	dc.b $00

prns	
	sta pa
	stx px
	sty py

	;jsr CLRCHN (LB) was causing problems with IDE64, also see iprns below
	pla
	sta addr$+1
	pla
	sta addr$+2
loop$	inc addr$+1
	bne addr$
	inc addr$+2
addr$	lda $aaaa
	beq out$
	jsr CHROUT
	jmp loop$
out$	lda addr$+2
	pha
	lda addr$+1
	pha

	lda pa
	ldx px
	ldy py

	rts

;print null terminated string found at x:a
pnts
	sta pnts_0+1
	stx pnts_0+2
	;jsr CLRCHN   (LB) was causing problems on IDE64, also see iprns below
	ldx #$00
pnts_0	lda $ffff,x
	beq pntsx
	jsr CHROUT
	jmp pnts_0
pntsx
	rts
	
;Duplicate PRNS used from IRQ to avoid crossover
ipx	dc.b $00
ipy	dc.b $00
ipa	dc.b $00
iprns	
	sta ipa
	stx ipx
	sty ipy

	;jsr CLRCHN
	pla
	sta iaddr$+1
	pla
	sta iaddr$+2
iloop$	inc iaddr$+1
	bne iaddr$
	inc iaddr$+2
iaddr$	lda $aaaa
	beq iout$
	jsr CHROUT
	jmp iloop$
iout$	lda iaddr$+2
	pha
	lda iaddr$+1
	pha

	lda ipa
	ldx ipx
	ldy ipy

	rts

as0	dc.b $00,$00
as1	dc.b $00,$00
res	dc.b $00,$00

add16 ;adds two 16-bit numbers (as0 + as1), returns 16-bit result in x:a
	clc
	lda as0
	adc as1
	pha
	lda as0+$01
	adc as1+$01
	tax
	pla
	rts
	
sub16 ;subtracts two 16-bit numbers (as0-as1), returns 16-bit result in x:a
	sec
	lda as0
	sbc as1
	pha
	lda as0+$01
	sbc as1+$01
	tax
	pla
	rts

copybytes ; takes y bytes at x:a and transfers it to address in as0 (lo:hi)
	stx copybytes1+$02
	sta copybytes1+$01
	sty copybytes2+$01
	lda as0
	sta as2+$01
	lda as0+$01
	sta as2+$02
	ldx #$00
copybytes1
	lda $ffff,x
as2	sta $ffff,x
	iny
	inx
copybytes2
	cpx #$ff
	bne copybytes1
	rts

CPY_LEN	dc.b $00,$00
copyblock ;src=CPY_SRC, dst=CPY_DST, len in x:a
	stx CPY_LEN+1
	sta CPY_LEN

	ldy #$00
	ldx CPY_LEN+1
	beq CPY_FRAG
CPY_PAGE
	lda (CPY_SRC),y
	sta (CPY_DST),y
	iny
	bne CPY_PAGE
	inc CPY_SRC+1	
	inc CPY_DST+1	
	dex		
	bne CPY_PAGE
CPY_FRAG
	cpy CPY_LEN+0	
	beq CPY_DONE	
	lda (CPY_SRC),Y	
	sta (CPY_DST),Y
	iny		
	bne CPY_FRAG
CPY_DONE
	rts

;Input a string and store it in x:a, terminated with a null byte.
;max # of chars in y returns num of chars entered in y, carry set if run/stop
ICOUNT	dc.b $00
INPUT
	stx INPUT_PTR+1
	sta INPUT_PTR
	sty INPUT_1+1
	lda #$00
	sta INPUT_Y
INPUT_G
	jsr STOP
	beq INPUT_3
	jsr GETIN
	beq INPUT_G
	ldy INPUT_Y
	
	cmp #160
	bcs INPUT_G
	cmp #$0d
	beq INPUT_2
	
INPUT_0	sta (INPUT_PTR),y
	jsr $ffd2
	
	inc INPUT_Y
	lda INPUT_Y
INPUT_1	cmp #$ff
	bne INPUT_G
INPUT_2
	lda #$00
	sta (INPUT_PTR),y
	clc
	rts	
INPUT_3
	sec
	rts
	

; print hex  char $ of number in a
hexx	dc.b $00,$00
hexstr
	stx hexx
	pha
	and #$f0
	clc
	lsr
	lsr
	lsr
	lsr
	tax
	lda hexstring,x
	jsr $ffd2

	pla
	and #$0f
	tax
	lda hexstring,x
	jsr $ffd2
	ldx hexx
	rts

acc
 	dc.b $00,$00
aux
        dc.b $00,$00
ext
	dc.b $00,$00
decstr

         STA acc
         STX acc+1
         STY aux          ;Base
         LDX #00
         STX aux+1
decstrLOOP
	 JSR DIV16
         INX
         LDA ext
         PHA
         LDA acc
         ORA acc+1
         BNE decstrLOOP        ;Divide until result=0
decstrPOOP    PLA
         ORA #$30         ;Convert to chr$
         CMP #$3A
         BCC decstrPLOP
         ADC #$06         ;$3A->A $3B->B etc.
decstrPLOP    JSR $FFD2
         DEX
         BNE decstrPOOP
         RTS

DIV16    
         LDA #0
         STA ext+1
         LDY #$10
div16LOOP
	 ASL acc
         ROL acc+1
         ROL
         ROL ext+1
         PHA
         CMP aux
         LDA ext+1
         SBC aux+1
         BCC div16DIV2
         STA ext+1
         PLA
         SBC aux
         PHA
         INC acc
div16DIV2     PLA
         DEY
         BNE div16LOOP
         STA ext
         RTS

;
;Prints the mac address indicated by the six bytes at (x:a)
;destroys a,x, preserves y
;
printmac
	sty macprinty
	stx macprl+$02
	sta macprl+$01
	ldy #$00
macprl
	lda $FFFF,y
	jsr hexstr
	cpy #$05
	beq macpr2
	jsr prns
	dc.b ":",0
macpr2	iny
	cpy #$06
	bne macprl
	ldy macprinty
	rts
macprinty	dc.b $00

printipy dc.b $00
printip ;Address in x:a, preserves y
	sty printipy
	sta pipadr+$01
	stx pipadr+$02
	ldy #$00
printiploop
	tya
	pha

pipadr	lda $FFFF,y
	ldx #$00
	ldy #$0a
	jsr decstr

	pla
	tay
	pha

	cpy #$03
	beq printiploop2

	jsr prns
	dc.b ".",0

printiploop2
	pla
	tay
	iny
	cpy #$04
	bne printiploop

	ldy printipy
	rts

;Thank you, Steve Judd
printnum
	sta acc
	stx acc+1
	sty aux
	ldx #$00
	stx aux+1
pn_l	jsr DIV16
	inx
	lda ext
	pha
	lda acc
	ora acc+1
	bne pn_l
pn_l2	pla
	ora #$30
	cmp #$3a
	bcc pn_l3
	adc #$06
pn_l3	jsr CHROUT
	dex
	bne pn_l2
	rts
	
yesno ;returns 0 in a for no, 1 in a for yes, 2 for "quit"
	PRINT "(y/n/q)"
yn1	jsr GETIN
	beq yn1
	cmp #89 ;y
	beq yesnoyes
	cmp #217;Y
	beq yesnoyes
	cmp #78;n
	beq yesnono
	cmp #206;N
	beq yesnono
	cmp #81;q
	beq yesnoquit
	cmp #209;Q
	beq yesnoquit
	jmp yn1
yesnoyes
	lda #$01
	rts
yesnono
	lda #$00
	rts
yesnoquit
	lda #$02
	rts
	
gotmac	dc.b $00,$00,$00,$00,$00,$00
getmac
	PRINT 13,"mac: "
	jsr gethex
	sta gotmac
	PRINT ":"
	jsr gethex
	sta gotmac+1
	PRINT ":"
	jsr gethex
	sta gotmac+2
	PRINT ":"
	jsr gethex
	sta gotmac+3
	PRINT ":"
	jsr gethex
	sta gotmac+4
	PRINT ":"
	jsr gethex
	sta gotmac+5
	rts
	
ghr	dc.b $00
gethex
	jsr gethexdig
	txa
	asl 
	asl
	asl 
	asl
	sta ghr
	jsr gethexdig
	txa
	ora ghr
	rts


; Replaced with better version
;gotip
;	dc.b $00,$00,$00,$00

;getip
;	PRINT 13,"IP[0]: "
;	jsr getnum
;	sta gotip
;	PRINT 13,"IP[1]: "
;	jsr getnum
;	sta gotip+$01
;	PRINT 13,"IP[2]: "
;	jsr getnum
;	sta gotip+$02
;	PRINT 13,"IP[3]: "
;	jsr getnum
;	sta gotip+$03
;	rts

gny	dc.b $00
getnum ;max 3 digits
	lda #$00
	sta gns
	sta gns+$01
	sta gns+$02
	ldy #$00	
gn0	sty gny
	jsr getdigit ;returns dec value in a
	ldy gny
	cmp #$0d     ;abort on return
	beq gn1
	sta gns,y	
	iny
	cpy #$03
	beq gn3
	jmp gn0
	
gn1
	lda gny
	beq gnx
	
	lda gny
	cmp #$01 ;1 digit entered
	bne gn2
	lda gns
	rts

gn2
	lda gns ;mul gns+1 * 10 and store in gnr+1
        asl ;*2
        sta gnr
        asl ;*4        ;again multiply by 2 (*4)
      	asl ;*8        ;again multiply by 2 (*8)
        clc
        adc gnr
        sta gnr
        
        lda gnr
        clc
        adc gns+1
	rts	
	
gn3
	lda gns ;mul gns*100 and store in gnr
	asl ;*2 (*4 + *32 + *64)
	asl ;*4
	sta gnr
	asl ;*8
	asl ;*16
	asl ;*32
	pha
	clc
	adc gnr
	sta gnr
	pla
	asl ;*64
	clc
	adc gnr
	sta gnr
	
	lda gns+1 ;mul gns+1 * 10 and store in gnr+1
        asl ;*2
        sta gnr+1
        asl ;*4        ;again multiply by 2 (*4)
      	asl ;*8        ;again multiply by 2 (*8)
        clc
        adc gnr+1
        sta gnr+1
        
        lda gnr
        clc
        adc gnr+1
        clc
        adc gns+2
gnx
	rts
        

	
gns	dc.b $00,$00,$00
gnr	dc.b $00,$00

getdigit ;returns digit in a,value in x
	jsr GETIN
	beq getdigit
	cmp #$0d
	beq gd2
	ldx #$00
gd0
	cmp numstr,x
	beq gd1
	inx
	cpx #$0b
	beq getdigit
	jmp gd0
gd1
	pha
	jsr $ffd2
	pla
	sec
	sbc #$30
gd2
	rts

gethexdig ;returns hex digit in a,value in x
	jsr GETIN
	beq gethexdig
	cmp #$0d
	beq ghd2
	ldx #$00
ghd0
	cmp hexstring,x
	beq ghd1
	inx
	cpx #$10
	beq gethexdig
	jmp ghd0
ghd1
	pha
	jsr $ffd2
	pla
	sec
	sbc #$30
ghd2
	rts

ipm	dc.b $00,$00,$00,$00

IPMTemp	dc.b $00

	;IF CARD_IP AND CARD_MASK = DEST_IP AND CARD_MASK THEN LOCAL
IPMASK ; expects pointer to IP in x:a, 
       ; returns carry clear if local,
       ; carry set if not.
	sta IPM0+1
	stx IPM0+2

	ldy #$00
IPM0
	lda $FFFF,y
	and CARD_MASK,y
;	sta $0500,y

	sta IPMTemp

	lda CARD_IP,y
	and CARD_MASK,y

	cmp IPMTemp
	bne IPM_NL
	iny
	cpy #$04
	bne IPM0
	
	clc
	rts
IPM_NL
	sec
	rts
	
numstr	dc.b "0123456789"
	
hexstring
	dc.b "0123456789ABCDEF"

pet2asc ;petscii char in a returns ascii char in a
	;if a > 64 AND a <91 THEN a = a + 32
	;if a > 96 AND a <123 THEN a = a - 32
	cmp #97
	blt pet2asc0
	;it's greater than 96
	cmp #123
	bge pet2ascx
	sec
	sbc #$20
	rts
pet2asc0
	cmp #65
	blt pet2ascx
	cmp #91
	bge pet2ascx
	clc
	adc #$20
pet2ascx
	rts
	
