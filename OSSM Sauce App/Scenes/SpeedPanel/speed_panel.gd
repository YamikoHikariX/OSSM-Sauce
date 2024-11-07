extends BasePanel

var accel_slider_min_pos: float
var accel_slider_max_pos: float

func initialize_panel() -> void:
	slide_direction = SlideDirection.SLIDE_FROM_LEFT

	$LabelTop.self_modulate.a = 0
	$LabelBot.self_modulate.a = 0

	$SpeedBar.value_changed.connect(_on_speed_changed)
	$SpeedBar.set_output_range(0, Main.node.max_speed)
	$SpeedBar.set_starting_percentage(Settings.get_setting(Section.SPEED_SLIDER, Key.POSITION_PERCENT))
	_on_speed_changed($SpeedBar.get_current_value())

	$AccelerationBar.value_changed.connect(_on_acceleration_changed)
	$AccelerationBar.set_output_range(1000, Main.node.max_acceleration)
	$AccelerationBar.set_starting_percentage(Settings.get_setting(Section.ACCEL_SLIDER, Key.POSITION_PERCENT))
	_on_acceleration_changed($AccelerationBar.get_current_value())

func reset():
	$SpeedBar.set_starting_percentage(Settings.get_setting(Section.SPEED_SLIDER, Key.POSITION_PERCENT))
	$SpeedBar.set_output_range(0, Main.node.max_speed)
	$AccelerationBar.set_starting_percentage(Settings.get_setting(Section.ACCEL_SLIDER, Key.POSITION_PERCENT))
	$AccelerationBar.set_output_range(1000, Main.node.max_acceleration)

func update_speed(speed_value: int):
	if Main.node.connected_to_server:
		var command: PackedByteArray
		command.resize(5)
		command.encode_u8(0, Enums.CommandType.SET_SPEED_LIMIT)
		command.encode_u32(1, speed_value)
		Main.node.ossm_websocket.send(command)
	update_speed_label(speed_value)

func update_speed_label(speed_value: int) -> void:
	print("speed_value: ", speed_value)
	$LabelTop.text = "Max Speed:\n" + str(speed_value) + " steps/sec"

func _on_speed_changed(new_value: float):
	update_speed(int(new_value))
	var new_percentage = remap(new_value, $SpeedBar.ostart, $SpeedBar.ostop, 0, 1)
	Settings.set_setting(Section.SPEED_SLIDER, Key.POSITION_PERCENT, new_percentage)

func _on_acceleration_changed(new_value: float):
	update_acceleration(int(new_value))
	var new_percentage = remap(new_value, $AccelerationBar.ostart, $AccelerationBar.ostop, 0, 1)
	Settings.set_setting(Section.ACCEL_SLIDER, Key.POSITION_PERCENT, new_percentage)

func update_acceleration(new_value: int) -> void:
	if Main.node.connected_to_server:
		var command: PackedByteArray
		command.resize(5)
		command.encode_u8(0, Enums.CommandType.SET_GLOBAL_ACCELERATION)
		command.encode_u32(1, new_value)
		Main.node.ossm_websocket.send(command)
	update_acceleration_label(new_value)

func update_acceleration_label(accel_value: int) -> void:
	$LabelBot.text = "Acceleration:\n" + str(accel_value) + " steps/sec²"
