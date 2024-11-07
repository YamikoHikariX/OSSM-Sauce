extends Control


func _on_add_delay_pressed():
	var duration: float = $Box/SpinBox.value
	Main.node.create_delay(duration)
	show_menu_buttons()


func show_menu_buttons():
	%Main.show()
	owner.refresh_selection()
	hide()


func _on_back_pressed():
	show_menu_buttons()
