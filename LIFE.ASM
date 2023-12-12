;  Anton Sander (c) 1995
ideal
	locals
ASSUME	CS:CSeg,DS:DSeg,ES:DSeg,SS:SSeg

SEGMENT	CSeg	PUBLIC
;	ORG	100h
start:
	mov	ax,DSeg
	mov	ds,ax
;	call	ZeigerAus

	lea	si,[GenerationsTabelle]
GenerationAnzeigen:
	lodsw
	call	ZelleSetzen
	cmp	si,[TabellenEnde]
	jne	GenerationAnzeigen
	jmp	warten
WeitereGeneration:
	call	RechnenKoord
	jc	FehlerEnde
	call	SortierenKoord
warten:	call	ZeigerAus

	mov	ah,0
	int	16h
	cmp	al,27
	jne	WeitereGeneration
FehlerEnde:
	call	ZeigerEin
	mov	ax,4C00h
	int	21h


PROC	WriteDecimal	NEAR
	Push	ax
	Push	cx
	Push	dx
	Push	si
	Mov	ax,dx
	Mov	si,10
	Xor	cx,cx
@@Cycle:
	Xor	dx,dx
	Div	si
	Push	dx
	Inc	cx
	Or	ax,ax
	Jne	@@Cycle
WriteDigitCycle:
	Pop	dx
	Call	WriteHexDigit
	Loop	WriteDigitCycle
	Pop	si
	Pop	dx
	Pop	cx
	Pop	ax
	Ret
ENDP	WriteDecimal
PROC	WriteHexDigit	NEAR
	push	ax
	Push	dx
	Add	dl,"0"
	Cmp	dl,"9"+1
	Jl	DigitLetter
	Add	dl,"A"-"0"-10
DigitLetter:
	mov	ah,6
	int	21h
	Pop	dx
	pop	ax
	Ret
ENDP	WriteHexDigit





;*********************************************
;   Ausrechnen aller moeglichen Kombinationen
;*********************************************
PUBLIC	ZelleEintragen
PROC	ZelleEintragen

	;***************************************************
	;* Es werden folgende Parameter an diese Prozedur  *
	;* uebergeben:					   *
	;* 	AH	= Koordinate X der aktuellen Zelle *
	;*	AL	= Koordinate Y	----  /  ----	   *
	;*						   *
	;*	DS:SI	= Anfangadresse der neuen Tabelle  *
	;*	ES:DI	= Endadresse  ----  /  ----	   *
	;***************************************************


	;***************************************************
	;* Folgender Parameter wird zurueckgegeben:	   *
	;*	ES:DI	= Neue Endadresse der neuen Tabelle*
	;***************************************************

	;***************************************************
	;* Inhalt der folgenden Register wird geaendert:   *
	;*						   *
	;***************************************************

	push	si			; unbedingt sichern!!
Schleife:				; DI - letzte Position
					; SI - laufende Posirion
	cmp	si,di			; Ist das Ende der Tabelle erreicht?
	je	Endschritt		; Ja. Das heisst- es wurde keine
					; gleiche Zelle gefunden.
	cmp	ah,[si+0]		; vergleichen der einzutragenden Zelle
	jne	NaechsteZelle		; mit der naechsten Zelle aus der
	cmp	al,[si+1]		; Tabelle
	je	Ende			; wenn gleich: Prozedur ist abgeschlossen
NaechsteZelle:
	add	si,3
	jmp	Schleife

Endschritt:
	mov	si,ax
	xchg	al,ah			; Zelle
	stosb				; abspeichern,
	mov	al,ah			; als
	stosb				; Erste
	mov	al,1			; initiallisieren
	stosb				; und
	mov	ax,si			;
	pop	si			; Prozedur
	ret				; verlassen. **********************

Ende:	inc	[BYTE PTR si+2]		; Gleich! Anzahl der Zelle erhoehen
	pop	si			; nicht vergessen, rauszuholen!!
	ret				; Prozedur verlassen **************
ENDP	ZelleEintragen

PUBLIC	RechnenKoord
PROC	RechnenKoord
	; GenerationsTabelle ist bereits vorhanden
	; DS soll korrekt geladen werden (auf den Datensegment zeigen)
	push	es				; register retten
	push	ax				;
	push	bx				;
	push	di				;
	push	si				;

	push	ds
	pop	es				; es=ds
	lea	si,[GenerationsTabelle]		; Tabellenadresse laden
	mov	di,[TabellenEnde]		; Tabellenende laden
	cmp	si,di
	je	EndeMitFehler
NextKoord:
	cmp	si,[TabellenEnde]		; wenn alle Zellen durch,
	je	BerechnungEnde			; beenden
	lodsb
	mov	ah,al				; AH 	=Koordinate X
	lodsb					; AL	=Koordinate Y

	;****************************
	;    Zellen eintragen	    *
	;****************************
	mov	bx,8*2
	push	si				; wird benutzt
	mov	si,[TabellenEnde]
	EintragSchleife:
		add	al,[AenderungsWerte+bx]
		jo	EndeMitFehler
		dec	bx
		add	ah,[AenderungsWerte+bx]
		jo	EndeMitFehler
		call	ZelleEintragen
		dec	bx
		jne	EintragSchleife
	pop	si

	jmp	NextKoord
BerechnungEnde:
	mov	[LaufPos],di
	pop	si
	pop	di
	pop	bx
	pop	ax
	pop	es
	clc
	ret
;******************************
; Falls Fehler aufgetreten sind
; beenden mit CF=1
;******************************
EndeMitFehler:
	pop	si
	pop	di
	pop	bx
	pop	ax
	pop	es
	stc
	ret
ENDP	RechnenKoord

PUBLIC	SortierenKoord
PROC	SortierenKoord
	push	es
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	si

	push	ds
	pop	es
	mov	si,OFFSET GenerationsTabelle
	mov	bx,si
	mov	dx,[TabellenEnde]
	mov	cx,[LaufPos]
	
;*************************************
; Zellen, die aussterben, ausstreichen
;*************************************
	cld
SuchSchleife:
	lodsw				; naechste alte Zelle laden
	mov	di,dx			; Adresse der Tabelle neuer Generation
HolNeu:	scasw				; vergleichen alte Zelle mit
	je	Gefunden		; laufender neuen Zelle
	inc	di			; nicht gleich!
	cmp	di,cx			; wurden alle Neuen durchgesucht?
	je	NichtGefunden		; ja ->komplett
	jmp	HolNeu			;
Gefunden:				; Gefunden!
					; [di] = Anzahl der Nachbarn
	cmp	[BYTE di],2		; Sind es weniger als 2?
	jc	NichtGefunden		; Ja -> streichen!
	cmp	[BYTE di],4		; Sind es Mehr als 3?
	jnc	NichtGefunden		; Ja -> streichen!
	mov	[BYTE di],0
	mov	[bx],ax			; die alte Zelle bleibt in
	inc	bx			; der naechsten Generation.
	inc	bx			; 
	jmp	NG2
NichtGefunden:				; Naechste Alte holen
	call	ZelleLoeschen; 	AUF DEM BILDSCHIRM SOFORT LOESCHEN
NG2:	cmp	si,dx			; Wurden alle Alten durchgesucht?
	jne	SuchSchleife		; Nein -> naechste bearbeiten!
;*************************************************
; Zellen, die entstehen, in die Tabelle einfuegen
;*************************************************
	mov	di,bx			; si bereits korrekt geladen
GeburtsSchleife:
	cmp	si,cx
	je	SortierenEnde
	lodsw
	mov	bx,ax
	lodsb
	cmp	al,3
	jne	GeburtsSchleife
	mov	ax,bx
	call	ZelleSetzen
	stosw
	jmp	GeburtsSchleife
SortierenEnde:
	mov	[TabellenEnde],di

	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	es
	ret
ENDP	SortierenKoord

PROC	ZeigerBewegen
	mov	dl,[XZentrum]
	add	al,al
	add	dl,al
	mov	dh,[YZentrum]
	add	dh,ah
	mov	bh,0
	mov	ah,2
	int	10h
	ret
ENDP	ZeigerBewegen

PUBLIC	ZelleLoeschen
PROC	ZelleLoeschen
;**************************************************************
;* Diese Prozedur loescht die Zelle auf dem BS, die ausstirbt *
;**************************************************************

;*********************************************
;* AX enthaelt die Koordinaten dieser Zelle: *
;*	AH	= Koordinate Y		     *
;	AL	= Koordinate X		     *
;*********************************************

	push	ax
	push	bx
	push	cx
	push	dx
	call	ZeigerBewegen
	mov	ah,0Ah
	mov	al,' '
	mov	bh,0
	mov	cx,2
	int	10h
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
ENDP	ZelleLoeschen

PUBLIC	ZelleSetzen
PROC	ZelleSetzen
;***************************************************************
;* Diese Prozedur setzt die Zelle auf dem BS, die neu entsteht *
;***************************************************************

;*********************************************
;* AX enthaelt die Koordinaten dieser Zelle: *
;*	AH	= Koordinate Y		     *
;	AL	= Koordinate X		     *
;*********************************************

	push	ax
	push	bx
	push	cx
	push	dx
	call	ZeigerBewegen
	mov	ah,0Ah
	mov	al,'Û'
	mov	bh,0
	mov	cx,2
	int	10h
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	
	ret
ENDP	ZelleSetzen


PUBLIC	ZeigerEin
PROC	ZeigerEin
	mov	dx,3D4h
	mov	al,10
	out	dx,al
	inc	dx
	mov	al,13
	out	dx,al
	ret
ENDP	ZeigerEin

PUBLIC	ZeigerAus
PROC	ZeigerAus
	mov	dh,24
	mov	dl,0
	mov	bh,0
	mov	ah,2
	int	10h
	lea	dx,[GenerationStr]
	mov	ah,9
	int	21h
	mov	dx,[Generationen]
	call	WriteDecimal
	inc	[Generationen]
	ret
ENDP	ZeigerAus

ENDS	CSeg

SEGMENT	SSeg	PUBLIC	STACK
	DW	256 DUP('SS')
ENDS

SEGMENT	DSeg	PUBLIC
PUBLIC	AenderungsWerte
LABEL	AenderungsWerte	BYTE
	DB	 0		; NULL Position
	DB	 0,-1
	DB	 0,-1
	DB	-1, 0
	DB	-1, 0
	DB	 0, 1
	DB	 0, 1
	DB	 1, 0
	DB	 0,-1

PUBLIC	XZentrum,YZentrum
XZentrum	DB	39
YZentrum	DB	12
GenerationStr	DB	'Generation:$'
Generationen	DW	1
PUBLIC	LaufPos
LABEL	LaufPos		WORD
	DW	?			; Adresse der laufenden Position

PUBLIC	TabellenEnde
LABEL	TabellenEnde	WORD
	; ab 'TabellenEnde' begint die Arbeitstabelle 
	; zum berechnen der naechsten Generation
	; Format:
	; DB	XKord,YKoord,Anzahl
	DW	OFFSET EndT		; Adresse des Tabellenende

PUBLIC	GenerationsTabelle
LABEL	GenerationsTabelle	BYTE
	; Tabelle mit Koordinaten des aktuellen Zustandes
	; Format:
	; DB	XKoord,YKoord		; Displasement vom Zentrum

	DB	0,0,0,-1,1,-1,-1,0,0,1
LABEL EndT	BYTE


ENDS

END	start
