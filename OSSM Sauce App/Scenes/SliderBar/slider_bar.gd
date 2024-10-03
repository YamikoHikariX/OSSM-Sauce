extends NinePatchRect
class_name SliderBar

var slider_top_offset: int = 16
var slider_bottom_offset: int = 156

@onready var max_pos: float = slider_top_offset
@onready var min_pos: float = max(size.y, size.x) - slider_bottom_offset

@onready var target_pos: float = min_pos
var deviation: float = 0.0

@export var smoothing_slider: HSlider
var smoothing: float = 0.05

var current_position: float:
	get:
		return %Slider.position.y
	set(new_position):
		%Slider.position.y = new_position
		
var last_position: float

var input_active: bool

signal position_changed(new_position: float, min_pos, max_pos)

func _ready() -> void:
	if smoothing_slider: smoothing_slider.value_changed.connect(_on_smoothing_slider_value_changed)
	reset()
	%Slider.gui_input.connect(_on_slider_gui_input)
	# owner.owner.gamepad_position_drag.connect(_on_stick_input)
	# owner.owner.gamepad_position_axis.connect(_on_axis_input)

func reset() -> void:
	target_pos = min_pos
	current_position = min_pos
	last_position = %Slider.position.y

func _physics_process(delta: float) -> void:
	%Deviation.position.y = target_pos + deviation
	%Target.position.y = target_pos

	var new_pos = lerp(%Slider.position.y, target_pos + deviation, delta / smoothing)
	current_position = clamp(new_pos, max_pos, min_pos)

	if current_position != last_position:
		position_changed.emit(current_position, min_pos, max_pos)
		last_position = current_position

func _input(event) -> void:
	if input_active:
		process_target_pos(event.position.y)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_target_pos_by(100)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_target_pos_by(-100)
	

func process_target_pos(y: float) -> void:
	var offset = 265
	target_pos = y - offset
	target_pos = clamp(target_pos, max_pos, min_pos)

func change_target_pos_by(position_change: float) -> void:
	target_pos += position_change
	target_pos = clamp(target_pos, max_pos, min_pos)

func _on_slider_gui_input(event) -> void:
	if event is InputEventScreenDrag:
		input_active = true
	else:
		input_active = false

func _on_smoothing_slider_value_changed(value: float) -> void:
	smoothing = value

func _on_stick_input(position_change: float) -> void:
	change_target_pos_by(position_change * 10.0)

func _on_axis_input(position_axis: float) -> void:
	deviation = remap(-position_axis, 0.0, 1.0, 0.0, target_pos)
	return

