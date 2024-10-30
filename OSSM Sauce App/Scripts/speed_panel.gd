extends BasePanel

var speed_slider_min_pos: float
var speed_slider_max_pos: float
@onready var speed_slider: TextureRect = $SpeedBar/Slider
@onready var speed_bottom: TextureRect = $SpeedBar/SliderBottom

var accel_slider_min_pos: float
var accel_slider_max_pos: float

func initialize_panel() -> void:
	slide_direction = SlideDirection.SLIDE_FROM_LEFT

	$LabelTop.self_modulate.a = 0
	$LabelBot.self_modulate.a = 0
	
	speed_slider.connect('gui_input', speed_slider_gui_input)
	speed_slider_max_pos = speed_slider.position.y
	speed_slider_min_pos = speed_bottom.position.y
	
	$AccelerationBar.value_changed.connect(_on_acceleration_changed)
	$AccelerationBar.set_output_range(1000, Main.node.max_acceleration)

	set_speed_slider_pos(Settings.get_setting(Section.SPEED_SLIDER, Key.POSITION_PERCENT))

	$AccelerationBar.set_starting_percentage(Settings.get_setting(Section.ACCEL_SLIDER, Key.POSITION_PERCENT))

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
	Settings.set_setting(Section.SPEED_SLIDER, Key.POSITION_PERCENT, percent)
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
	Settings.set_setting(Section.ACCEL_SLIDER, Key.POSITION_PERCENT, new_percentage)
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
			Settings.set_setting(Section.SPEED_SLIDER, Key.POSITION_PERCENT, slider_position_percent)
