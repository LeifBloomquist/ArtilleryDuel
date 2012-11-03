	MAC PRINT
	jsr prns
	dc.b {0},0
	ENDM

	MAC IPRINT
	jsr iprns
	dc.b {0},0
	ENDM
	
	MAC ERROR
	jsr prns
	dc.b 13,CG_RED,CG_RVS,{0},CG_NRM,CG_WHT,13,0
	ENDM

	MAC INPUT
	ldx #>{0}
	lda #<{0}
	ldy {2}
	jsr INPUT
	ENDM
	
	MAC ldxa
	ldx {0}+1
	lda {0}
	ENDM
	
	MAC ldax
	ldx #>{0}
	lda #<{0}
	ENDM
	
	MAC stax
	stx {0}+1
	sta {0}
	ENDM
	
	MAC staa
	sta {1}
	sta {1}+1
	ENDM
	
	MAC movax 
	ldax {1}
	stax {2}
	ENDM
	
	MAC pushax
	pha
	txa
	pha
	ENDM
	
	MAC popax
	pla
	tax
	pla
	ENDM
	
	MAC blt
	bcc {1}
	ENDM
	
	MAC bge
	bcs {1}
	ENDM
	