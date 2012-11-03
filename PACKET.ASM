;Source by Six of Style (Oliver VieBrooks)
;http://style64.org http://thedarkside.ath.cx mailto:six@darklordsofchaos.com
;
;Last Updated 8/24/2005 
;

LOOKUP100   ; Lookup table for below to spread values 0-100
  incbin "lookup100.bin"

PACKET_LOCAL		dc.b $00 ;Used to determine where to send packets (gateway or dest)
IN_PACKET_LENGTH	dc.w $0000
OUT_PACKET_LENGTH	dc.w $0000

IN_PACKET_STATUS	dc.w $0000

TXCOUNT			dc.w $0000

RXCOUNT			dc.w $0000

INPACKET		ds.b $0400 ; Maximum Packet Size
OUTPACKET		ds.b $0400
