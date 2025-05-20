#Requires AutoHotkey v2.0

; -------------------------------------------
; CapsLock -> Esc when tapped, Ctrl when held
; -------------------------------------------

; on Capslock down, start a 200 ms timer
CapsLock:: {
	; Start a one-shot timer in 200ms
	SetTimer(_DoCtrl, -200)

	; If CapsLock is released within 0.2 ms
	if !KeyWait("CapsLock", 0.2) {
		; cancel the timer and send Escape
		SetTimer(_DoCtrl, "Off")
		Send "{Esc}"
	}
}

_DoCtrl() {
	; If still held after 200 ms, send Ctrl down
	Send "{Ctrl Down}"
	; Wait until it's released
	KeyWait "CapsLock"
	; Then send Ctrl up
	Send "{Ctrl up}"
}
