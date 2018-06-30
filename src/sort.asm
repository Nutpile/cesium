; made by martin warmer, mmartin@xs4all.nl
; modified for ez80 architecture and hidden programs by matt waltz
;
; uses insertion sort to sort the vat alphabetically

sort_vat:
	res	sort_first_item_found,(iy + asm_Flag1)
	ld	hl,(progptr)
.sort_next:
	call	.find_next_item
	ret	nc
	bit	sort_first_item_found,(iy + asm_Flag1)
	jp	z,.first_found
	push	hl
	call	.skip_name
	pop	de
	push	hl					; to continue from later on
	ld	hl,(sort_first_item_found_pointer)
	jr	.search_next_start			; could speed up sorted list by first checking if it's the last item (not neccessary)
.search_next:
	call	.skip_name
	ld	bc,(endofsortedpartpointer)
	or	a,a					; reset carry flag
	push	hl
	sbc	hl,bc
	pop	hl
	jr	z,.location_found
	ld	bc,-6
	add	hl,bc
.search_next_start:
	push	hl
	push	de
	call	.compare_names
	pop	de
	pop	hl
	jr	nc,.search_next
.search_next_end:
	ld	bc,6
	add	hl,bc					; goto start of entry
.location_found:
	ex	de,hl
	ld	a,(hl)
	add	a,7
	ld	bc,6					; rewind six bytes
	add	hl,bc					; A=number of bytes to move
	ld	c,a					; HL->bytes to move
	ld	(vatentrysize),bc			; DE->move to location
	ld	(vatentrynewloc),de
	push	de
	push	hl
	or	a,a
	sbc	hl,de
	pop	hl
	pop	de
	jr	z,.no_move_needed
	push	hl
	ld	de,vatentrytempend
	lddr						; copy entry to move to vatentrytempend

	ld	hl,(vatentrynewloc)
	pop	bc
	push	bc
	or	a,a
	sbc	hl,bc
	push	hl
	pop	bc
	pop	hl
	inc	hl
	push	hl
	ld	de,(vatentrysize)
	or	a,a
	sbc	hl,de
	ex	de,hl
	pop	hl
	ldir

	ld	hl,vatentrytempend
	ld	bc,(vatentrysize)
	ld	de,(vatentrynewloc)
	lddr
	ld	hl,(endofsortedpartpointer)
	ld	bc,(vatentrysize)
	or	a,a
	sbc	hl,bc
	ld	(endofsortedpartpointer),hl
	pop	hl					; pointer to continue from
	jp	.sort_next				; to skip name and rest of entry

.no_move_needed:
	pop	hl
	ld	(endofsortedpartpointer),hl
	jp	.sort_next

.first_found:
	set	sort_first_item_found,(iy + asm_Flag1)		; to make it only execute once
	ld	(sort_first_item_found_pointer),hl
	call	.skip_name
	ld	(endofsortedpartpointer),hl
	jp	.sort_next

.skip_to_next:
	ld	bc,-6
	add	hl,bc
	call	.skip_name
	jp	find_next_item				; look for next item
.skip_name:
	ld	bc,0
	ld	c,(hl)					; number of bytes in name
	inc	c					; to get pointer to data type byte of next entry
	or	a,a					; reset carry flag
	sbc	hl,bc
	ret

.compare_names:						; hl and de pointers to strings output=carry if de is first
	res	sort_first_hidden,(iy + sort_flag)
	res	sort_second_hidden,(iy + sort_flag)

	dec	hl
	dec	de
	ld	b,64
	ld	a,(hl)
	cp	a,b
	jr	nc,first_not_hidden			; check if files are hidden
	add	a,b
	ld	(hl),a
	set	sort_first_hidden,(iy + sort_flag)
first_not_hidden:
	ld	a,(de)
	cp	a,b
	jr	nc,second_not_hidden
	add	a,b
	ld	(de),a
	set	sort_second_hidden,(iy + sort_flag)
second_not_hidden:
	push	hl
	push	de
	inc	hl
	inc	de
	ld	b,(hl)
	ld	a,(de)
	ld	c,0
	cp	a,b					; check if same length
	jr	z,.compare_names_continue
	jr	nc,.compare_names_continue		; b = smaller than a
	inc	c					; to remember that b was larger
	ld	b,a					; b was larger than a
.compare_names_continue:
	dec	hl
	dec	de
	ld	a,(de)
	cp	a,(hl)
	jr	nz,.match
	djnz	.compare_names_continue
	pop	de
	pop	hl
	call	.reset_hidden_flags
	dec	c
	ret	nz
	ccf
	ret
.match:
	pop	de
	pop	hl
.reset_hidden_flags:
	push	af
	bit	sort_first_hidden,(iy + sort_flag)
	jr	z,.first_not_hidden_check
	ld	a,(hl)
	sub	a,64
	ld	(hl),a
.first_not_hidden_check:
	bit	sort_second_hidden,(iy + sort_flag)
	jr	z,.second_not_hidden_check
	ld	a,(de)
	sub	a,64
	ld	(de),a
.second_not_hidden_check:
	pop	af
	ret

.find_next_item:					; carry=found nc=notfound
	ex	de,hl
	ld	hl,(ptemp)
	or	a,a					; reset carry flag
	sbc	hl,de
	ret	z
	ex	de,hl					; load progptr into hl
	ld	a,(hl)
	and	a,$1f					; mask out state bytes
	push	hl
	ld	hl,.sort_types
	ld	bc,2
	cpir
	pop	hl
	jp	nz,.skip_to_next			; skip to next entry
	dec	hl					; add check for folders here if needed
	dec	hl
	dec	hl					; to pointer
	ld	e,(hl)
	dec	hl
	ld	d,(hl)					; pointer now in de
	dec	hl
	ld	a,(hl)					; high byte now in a
	dec	hl					; add check: do I need to sort this program (not necessary)
	scf
	ret

.sort_types:
	db	progObj, protProgObj
