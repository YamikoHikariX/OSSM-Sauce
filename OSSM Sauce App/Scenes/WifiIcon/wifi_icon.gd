extends Sprite2D


func _ready():
	self_modulate = Color.WHITE
	Main.node.connected_to_server_changed.connect(toggle)
	Main.node.connected_to_ossm_changed.connect(toggle_ossm_connection_status)

func toggle(enable: bool) -> void:
	if enable:
		show()
	else:
		hide()

func toggle_ossm_connection_status(enable: bool) -> void:
	if enable:
		self_modulate = Color.SEA_GREEN
	else:
		self_modulate = Color.WHITE