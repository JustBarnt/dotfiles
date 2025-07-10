#Requires AutoHotkey v2.0
#Include %A_LineFile%\..\vim_ahk\vim.ahk

; -------------------------------------------
; CapsLock -> Esc when tapped, Ctrl when held
; -------------------------------------------

*CapsLock:: {
	Send "{LControl down}"
}

*CapsLock up:: {
	Send "{LControl up}"

	if (A_PriorKey == "CapsLock") {
		if (A_TimeSincePriorHotkey < 1000) {
			Suspend "1"
			Send "{Esc}"
			Suspend "0"
		}
	}
}
