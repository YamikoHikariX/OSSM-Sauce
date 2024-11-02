extends Control


func _on_add_delay_pressed():
	var duration: float = $Box/SpinBox.value
	Main.node.create_delay(duration)
	show_menu_buttons()


func show_menu_buttons():
	var buttons = [
		%Menu/Main/PlaylistButtons,
		%Menu/Main/PathButtons,
		%Menu/Main/LoopPlaylistButton,
		%Menu/PathControls,
		%Menu/Header,
		%Menu/Main/Mode]
	for button in buttons:
		button.show()
	%Menu.refresh_selection()
	hide()


func _on_back_pressed():
	show_menu_buttons()
