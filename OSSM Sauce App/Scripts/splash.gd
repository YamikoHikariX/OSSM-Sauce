extends Panel


func _ready():
	self_modulate.a = 2
	if Settings.get_setting(Section.APP_SETTINGS, Key.SHOW_SPLASH):
		show()


func _on_accept_pressed():
	hide()


func _on_dont_show_toggled(toggled_on):
	Settings.set_setting(Section.APP_SETTINGS, Key.SHOW_SPLASH, !toggled_on)