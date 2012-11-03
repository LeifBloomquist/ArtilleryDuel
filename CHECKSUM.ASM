



MakeChecksumZp_Len	dc.w $0000
MakeChecksumZp_Sum	dc.w $0000

MakeChecksum:
	;clear sum
	ldy #0
	sty MakeChecksumZp_Sum
	sty MakeChecksumZp_Sum+1

MakeChecksum_Page:
	;less than a page to go?
	lda MakeChecksumZp_Len+1
	beq MakeChecksum_Rest	
	
	ldx #0 ;do full page
	jsr MakeChksum		 ;checksum current page
	
	inc MakeChecksumZp_Ptr+1 ;next page
	dec MakeChecksumZp_Len+1 ;one less page to do
	bne MakeChecksum_Page    ;If it's not the last page, do it again

MakeChecksum_Rest: ;checksum remaining <page bytes
	ldx MakeChecksumZp_Len	
	jsr MakeChksum

	;put sum in x:a, eor'ed by #$ffff
	lda MakeChecksumZp_Sum+1
	eor #$ff
	tax
	lda MakeChecksumZp_Sum
	eor #$ff
	rts


MakeChksum:
	clc
MakeChksum0:
	lda (MakeChecksumZp_Ptr),y
	adc MakeChecksumZp_Sum
	sta MakeChecksumZp_Sum
	iny
	dex
	beq MakeChksum2

	lda (MakeChecksumZp_Ptr),y
	adc MakeChecksumZp_Sum+1
	sta MakeChecksumZp_Sum+1
	iny
	dex
	bne MakeChksum0

MakeChksum1:
	lda #0
	adc MakeChecksumZp_Sum
	sta MakeChecksumZp_Sum
	bcc MakeChksum3
MakeChksum2:
	lda #0
	adc MakeChecksumZp_Sum+1
	sta MakeChecksumZp_Sum+1
	bcs MakeChksum1

MakeChksum3:
	rts

