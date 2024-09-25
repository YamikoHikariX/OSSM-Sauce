extends Control

@onready var slider: TextureRect = $MovementBar/Slider

@onready var max_range: float = $MovementBar/SliderTop.position.y
@onready var min_range: float = slider.position.y

@onready var target_pos: float = min_range
var deviation: float = 0.0

var smoothing: float
var last_position: int
var input_active: bool


func _ready():
	_on_smoothing_slider_value_changed($Smoothing/HSlider.value)
	owner.gamepad_position_drag.connect(_on_gamepad_position_drag)
	owner.gamepad_position_axis.connect(_on_position_axis)


func _physics_process(delta):
	var pos = lerp(slider.position.y, target_pos + deviation, delta * smoothing)
	slider.position.y = clamp(pos, max_range, min_range)
	var mapped_pos: int = int(remap(slider.position.y, min_range, max_range, 0, 10000))
	if owner.connected_to_server and last_position != mapped_pos:
		var command: PackedByteArray
		command.resize(5)
		command.encode_u8(0, Enums.CommandType.POSITION)
		command.encode_u32(1, mapped_pos)
		owner.websocket.send(command)
		last_position = mapped_pos

func _input(event):
	if input_active:
		process_target_pos(event.position.y)

func process_target_pos(y: float):
	if input_active:
		var offset = 265
		target_pos = y - offset
		target_pos = clamp(target_pos, max_range, min_range)

func _on_slider_gui_input(event):
	if event is InputEventScreenDrag:
		input_active = true
	else:
		input_active = false

func _on_gamepad_position_drag(position_change: float):
	target_pos = target_pos + position_change * 50.0
	target_pos = clamp(target_pos, max_range, min_range)
	# if target_pos / 5 == 0:
	# 	Input.start_joy_vibration(0, 0.5, 0.5, 0.1)

func _on_position_axis(position_axis: float):
	deviation = remap(-position_axis, 0.0, 1.0, 0.0, target_pos)

func _on_smoothing_slider_value_changed(value):
	var min_value = $Smoothing/HSlider.min_value
	var max_value = $Smoothing/HSlider.max_value
	smoothing = max_value - (value - min_value)
	owner.user_settings.set_value('app_settings', 'smoothing_slider', value)
