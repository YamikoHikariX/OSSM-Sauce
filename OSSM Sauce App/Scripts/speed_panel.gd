extends Panel

var speed_slider_min_pos: float
var speed_slider_max_pos: float
@onready var speed_slider: TextureRect = $SpeedBar/Slider
@onready var speed_bottom: TextureRect = $SpeedBar/SliderBottom

var accel_slider_min_pos: float
var accel_slider_max_pos: float


func _ready():
	$LabelTop.self_modulate.a = 0
	$LabelBot.self_modulate.a = 0
	$BackTexture.self_modulate.a = 0
	$BackButton.hide()
	
	speed_slider.connect('gui_input', speed_slider_gui_input)
	speed_slider_max_pos = speed_slider.position.y
	speed_slider_min_pos = speed_bottom.position.y
	
	$AccelerationBar.value_changed.connect(_on_acceleration_changed)
	$AccelerationBar.set_output_range(1000, Main.node.max_acceleration)

	if UserSettings.cfg.has_section_key('speed_slider', 'position_percent'):
		set_speed_slider_pos(UserSettings.cfg.get_value('speed_slider', 'position_percent'))
	else:
		set_speed_slider_pos(0.6)

	if UserSettings.cfg.has_section_key('accel_slider', 'position_percent'):
		$AccelerationBar.set_starting_percentage(UserSettings.cfg.get_value('accel_slider', 'position_percent'))
		print("accel_slider: ", UserSettings.cfg.get_value('accel_slider', 'position_percent'))
	else:
		$AccelerationBar.set_starting_percentage(0.4)
		print("accel_slider: ", 0.4)


func reset():
	$AccelerationBar.reset()

func set_speed_slider_pos(percent):
	var slider_map = remap(
			percent,
			0,
			1,
			speed_slider_min_pos,
			speed_slider_max_pos)
	speed_slider.position.y = slider_map
	UserSettings.cfg.set_value('speed_slider', 'position_percent', percent)
	update_speed()


func update_speed():
	var speed_map = round(remap(
			speed_slider.position.y,
			speed_slider_min_pos,
			speed_slider_max_pos,
			0,
			Main.node.max_speed))
	if Main.node.connected_to_server:
		var command: PackedByteArray
		command.resize(5)
		command.encode_u8(0, Enums.CommandType.SET_SPEED_LIMIT)
		command.encode_u32(1, speed_map)
		Main.node.ossm_websocket.send(command)
	$LabelTop.text = "Max Speed:\n" + str(speed_map) + " steps/sec"

func _on_acceleration_changed(new_value: float):
	update_acceleration(int(new_value))
	var new_percentage = remap(new_value, 1000, Main.node.max_acceleration, 0, 1)
	UserSettings.cfg.set_value('accel_slider', 'position_percent', new_percentage)
	print("new_percentage: ", new_percentage)

func update_acceleration(new_value: int) -> void:
	print("new_value: ", new_value)
	if Main.node.connected_to_server:
		var command: PackedByteArray
		command.resize(5)
		command.encode_u8(0, Enums.CommandType.SET_GLOBAL_ACCELERATION)
		command.encode_u32(1, new_value)
		print(new_value)
		Main.node.ossm_websocket.send(command)
	$LabelBot.text = "Acceleration:\n" + str(new_value) + " steps/sec²"


func speed_slider_gui_input(event):
	if 'relative' in event and event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_LEFT:
			var drag_pos = speed_slider.position.y + event.relative.y
			var new_slider_pos = clamp(
					drag_pos,
					speed_slider_max_pos,
					speed_slider_min_pos)
			speed_slider.position.y = new_slider_pos
			update_speed()
			var slider_position_percent = remap(
					new_slider_pos,
					speed_slider_min_pos,
					speed_slider_max_pos,
					0,
					1)
			UserSettings.cfg.set_value(
					'speed_slider',
					'position_percent',
					slider_position_percent)


func tween(activating: bool = true):
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel()
	var outside_pos := Vector2(-size.x, position.y)
	var inside_pos := Vector2(0, outside_pos.y)
	var positions: Array = [outside_pos, inside_pos]
	if not activating:
		positions.reverse()
	tween.tween_method(set_position, position, positions[1], Main.node.ANIM_TIME)
	var start_color: Color = $BackTexture.self_modulate
	var end_color: Color = start_color
	start_color.a = 0
	end_color.a = 1
	var colors: Array = [start_color, end_color]
	if not activating:
		colors.reverse()
		$BackButton.hide()
		tween.tween_callback(anim_finished).set_delay(Main.node.ANIM_TIME)
	else:
		$BackButton.show()
	var visuals = [$BackTexture, $LabelTop, $LabelBot]
	for node in visuals:
		tween.tween_method(
			node.set_self_modulate,
			colors[0],
			colors[1],
			Main.node.ANIM_TIME)


func anim_finished():
	%ActionPanel/Speed/Selection.hide()
	%ActionPanel.self_modulate.a = 1
	$BackButton.hide()


func _on_back_button_pressed():
	tween(false)
	$BackButton.hide()
	%ActionPanel.show()
