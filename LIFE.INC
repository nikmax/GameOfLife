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
