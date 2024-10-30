extends Control

var stroke_duration: float

var slider_min_pos: float # these seem reversed
var slider_max_pos: float
@onready var slider: TextureRect = $StrokeDurationSlider/Slider
@onready var slider_stop: TextureRect = $StrokeDurationSlider/SliderStop

@onready var touch_pos: float = slider_min_pos

@onready var link_button: Button = get_node('../LinkSpeedSliders')

@onready var _in = get_node('../In')


func _ready():
	slider_min_pos = slider_stop.position.y
	slider_max_pos = slider.position.y


func _physics_process(delta):
	if not input_active:
		return
	var slider_resist = owner.slider_resist
	var pos = lerp(slider.position.y, touch_pos, delta * slider_resist)
	var clamped_pos = clamp(pos, slider_max_pos, slider_min_pos)
	slider.position.y = clamped_pos
	if link_button.button_pressed:
		_in.slider.position.y = clamped_pos
		_in.map_stroke_duration()
		_in.update_stroke_duration_text()
	map_stroke_duration()
	update_stroke_duration_text()
	owner.set_loop_from_sliders()


var input_active: bool
func _input(event):
	if input_active:
		var offset = 140
		if 'position' in event:
			touch_pos = event.position.x - offset


func _on_slider_gui_input(event):
	if event is InputEventScreenDrag:
		input_active = true
	elif event is InputEventScreenTouch and not event.pressed:
		input_active = false


func map_stroke_duration():
	var slider_position_percent = remap(
			slider.position.y,
			slider_max_pos,
			slider_min_pos,
			0,
			1)
	if slider_position_percent < 0.005:
		stroke_duration = 0
		return
	stroke_duration = snappedf(remap(
			slider.position.y,
			slider_min_pos,
			slider_max_pos,
			Main.node.min_stroke_duration,
			Main.node.max_stroke_duration), 0.01)


func reset_stroke_duration_slider():
	slider.position.y = slider_max_pos
	var stroke_duration = snappedf(remap(
		slider.position.y,
		slider_min_pos,
		slider_max_pos,
		Main.node.min_stroke_duration,
		Main.node.max_stroke_duration), 0.01)
	if Main.node.connected_to_server:
		owner.set_loop_from_sliders()
	update_stroke_duration_text()


func update_stroke_duration_text():
	var slider_position_percent = remap(
		slider.position.y,
		slider_max_pos,
		slider_min_pos,
		0,
		1)
	if slider_position_percent < 0.005:
		$StrokeDurationLabel.text = "OUT: OFF"
	else:
		var display_text: String
		# if %Menu/LoopSettings/DisplayMode/OptionButton.selected == 0:
		if true:
			display_text = "OUT: " + str(stroke_duration) + "s"
		else:
			var map = snappedf(remap(
				slider.position.y,
				slider_max_pos,
				slider_min_pos,
				1,
				100), 0.01)
			display_text = "OUT: " + str(map) + "%"
		$StrokeDurationLabel.text = display_text


func _on_transition_item_selected(index):
	if link_button.button_pressed:
		_in.get_node('AccelerationControls/Transition').select(index)
	owner.set_loop_from_sliders()
	# owner._on_bpm_button_pressed()


func _on_easing_item_selected(index):
	if link_button.button_pressed:
		_in.get_node('AccelerationControls/Easing').select(index)
	owner.set_loop_from_sliders()
	# owner._on_bpm_button_pressed()
