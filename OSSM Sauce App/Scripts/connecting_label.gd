extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if UserSettings.cfg.has_section_key('app_settings', 'last_server_connection'):
		show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
