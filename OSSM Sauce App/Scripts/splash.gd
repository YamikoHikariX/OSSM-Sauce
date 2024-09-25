extends Panel


func _ready():
	self_modulate.a = 2


func _on_accept_pressed():
	hide()


func _on_dont_show_toggled(toggled_on):
	owner.user_settings.set_value('app_settings', 'show_splash', !toggled_on)
