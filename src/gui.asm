gui_main:
	call	gui_draw_core
	draw_rectangle_outline 193, 24, 316, 221
	draw_rectangle_outline 237, 54, 274, 91
	draw_horiz 199, 36, 112
	set_normal_text
	print	string_file_information, 199, 27
	ld	a,(current_screen)
	cp	a,screen_programs
	jp	z,view_programs
	cp	a,screen_apps
	jp	z,view_apps
	;cp	a,screen_usb
	;jr	z,show_usb
	jp	exit_full

gui_draw_core:
	call	lcd_fill
	call	util_show_free_mem
	draw_rectangle 1, 1, 319, 21
	draw_rectangle_outline 1, 22, 318, 223
	set_inverted_text
	print string_cesium, 15, 7
	draw_sprite sprite_battery, 3, 7
	ld	a,0
battery_status := $-1
	sub	a,5
	cpl
	or	a,a
	ret	z
	ld	bc,4
	ld	de,(lcdWidth * 8) + 7
	jp	lcd_rectangle.computed

gui_show_description:
	push	bc
	push	hl
	call	gui_clear_status_bar
	pop	hl
	save_cursor
	set_inverted_text
	ld	bc,4
	ld	a,228
	call	util_string_xy
	set_normal_text
	restore_cursor
	pop	bc
	ret

; z flag set = option is on
gui_draw_option:
	push	af
	push	hl
	push	bc
	push	de
	call	lcd_rectangle_outline.computed
	pop	hl
	pop	bc
	dec	bc
	dec	bc
	dec	bc
	dec	bc				; bc - 4
	ld	a,h
	sub	a,4
	ld	(.recompute),a
	inc	l
	inc	l				; Ty + 2
	ld	h,lcdWidth / 2
	mlt	hl
	add	hl,hl
	pop	de
	add	hl,de
	ex	de,hl				; recompute offset
	pop	af
	ld	a,0
.recompute := $-1
	jp	nz,lcd_rectangle.computed
	ret

gui_clear_status_bar:
	draw_rectangle 1, 225, 319, 239
	ret
