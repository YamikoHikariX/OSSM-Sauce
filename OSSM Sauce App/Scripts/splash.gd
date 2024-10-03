extends Panel


func _ready():
	self_modulate.a = 2
	if UserSettings.cfg.get_value('app_settings', 'show_splash', true):
		show()


func _on_accept_pressed():
	hide()


func _on_dont_show_toggled(toggled_on):
	UserSettings.cfg.set_value('app_settings', 'show_splash', !toggled_on)
