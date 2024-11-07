extends NinePatchRect
class_name SliderBar

@export var show_deviation: bool = true
@export var show_target: bool = true

@export var slider_color: Color = Color(0.941176, 0.501961, 0.501961, 1)
@export var top_slider_color: Color = Color(0.941176, 0.501961, 0.501961, 1)


@export var custom_offset: int = 265
var slider_top_offset: int = 16
var slider_bottom_offset: int = 156

@onready var max_pos: float = slider_top_offset
@onready var min_pos: float = max(size.y, size.x) - slider_bottom_offset
@onready var starting_pos: float = min_pos

var ostart: float = 0.0
var ostop: float = 10000.0

@onready var target_pos: float = min_pos:
	get:
		return target_pos
	set(new_pos):
		target_pos = clamp(new_pos, max_pos, min_pos)

var deviation: float = 0.0

@export var smoothing_slider: HSlider
@export var stick_speed_slider: HSlider
var smoothing: float = 0.02
var stick_speed: float = 1.0

var axis_input_enabled: bool = false

var slider_position: float:
	get:
		return %Slider.position.y
	set(new_position):
		%Slider.position.y = clamp(new_position, max_pos, min_pos)
		
var last_slider_position: float
var input_active: bool

signal value_changed(new_position: float)

func _ready() -> void:
	if not show_deviation: %Deviation.hide()
	if not show_target: %Target.hide()
	%Slider.self_modulate = slider_color
	if smoothing_slider: smoothing_slider.value_changed.connect(_on_smoothing_slider_value_changed)
	if stick_speed_slider: stick_speed_slider.value_changed.connect(_on_stick_speed_slider_value_changed)
	%Slider.gui_input.connect(_on_slider_gui_input)
	reset()

func reset() -> void:
	print("Starting pos: ", starting_pos) if name == "PositionBar" else null
	print("Min pos: ", min_pos) if name == "PositionBar" else null
	if starting_pos != min_pos:
		print("Using Starting pos") if name == "PositionBar" else null
		target_pos = starting_pos
	else:
		print("Using Min pos") if name == "PositionBar" else null
		target_pos = min_pos
	slider_position = target_pos
	last_slider_position = slider_position
	# send_signal()

func _physics_process(delta: float) -> void:
	%Deviation.position.y = target_pos + deviation
	%Target.position.y = target_pos
	
	slider_position = lerp(slider_position, target_pos + deviation, delta / smoothing)
		
	if slider_position != last_slider_position:
		send_signal()

func send_signal() -> void:
	var mapped_pos = round(remap(slider_position, max_pos, min_pos, ostop, ostart))
	value_changed.emit(mapped_pos)
	last_slider_position = slider_position

func get_current_value() -> float:
	return round(remap(slider_position, max_pos, min_pos, ostop, ostart))

func _input(event) -> void:
	if input_active:
		process_target_pos(event.position.y - click_offset)
	# elif event is InputEventMouseButton:
	# 	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
	# 		target_pos += 100
	# 	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
	# 		target_pos -= 100
	
func set_output_range(new_ostart: float, new_ostop: float) -> void:
	ostart = new_ostart
	ostop = new_ostop
	reset()

func set_starting_percentage(new_percentage: float) -> void:
	starting_pos = remap(new_percentage, 1.0, 0.0, max_pos, min_pos)
	reset()

func set_target_pos(new_pos: float) -> void:
	target_pos = new_pos

func process_target_pos(y: float) -> void:
	target_pos = y - custom_offset

var click_offset: int = 0
var click_start: float = 0

func _on_slider_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			click_offset = event.position.y - %Slider.size.y / 2
			click_start = slider_position
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			click_offset = 0
			click_start = 0

	if event is InputEventScreenDrag:
		input_active = true
	else:
		input_active = false

func _on_smoothing_slider_value_changed(value: float) -> void:
	smoothing = value

func _on_stick_speed_slider_value_changed(value: float) -> void:
	stick_speed = value

func _on_stick_input(position_change: float) -> void:
	target_pos += position_change * 10.0 * stick_speed

func _on_axis_input(position_axis: float) -> void:
	if axis_input_enabled:
		deviation = remap(-position_axis, 0.0, 1.0, 0.0, target_pos)

func _on_trigger_toggled(active: bool) -> void:
	axis_input_enabled = active
	deviation = 0.0