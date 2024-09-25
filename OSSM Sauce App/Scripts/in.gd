extends Control

var stroke_duration: float

var slider_min_pos: float # these seem reversed
var slider_max_pos: float
@onready var slider: TextureRect = $StrokeDurationSlider/Slider
@onready var slider_stop: TextureRect = $StrokeDurationSlider/SliderStop

@onready var touch_pos: float = slider_min_pos

@onready var link_button: Button = get_node('../LinkSpeedSliders')

@onready var out = get_node('../Out')


func _ready():
	slider_min_pos = slider_stop.position.y
	slider_max_pos = slider.position.y


func _physics_process(delta):
	if not input_active:
		return
	var slider_resist = get_parent().slider_resist
	var pos = lerp(slider.position.y, touch_pos, delta * slider_resist)
	var clamped_pos = clamp(pos, slider_max_pos, slider_min_pos)
	slider.position.y = clamped_pos
	if link_button.button_pressed:
		out.slider.position.y = clamped_pos
		out.map_stroke_duration()
		out.update_stroke_duration_text()
	map_stroke_duration()
	update_stroke_duration_text()
	get_parent().send_command()


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
			owner.min_stroke_duration,
			owner.max_stroke_duration), 0.01)


func reset_stroke_duration_slider():
	slider.position.y = slider_max_pos
	var stroke_duration = snappedf(remap(
			slider.position.y,
			slider_min_pos,
			slider_max_pos,
			owner.min_stroke_duration,
			owner.max_stroke_duration), 0.01)
	if owner.connected_to_server:
		get_parent().send_command()
	update_stroke_duration_text()


func update_stroke_duration_text():
	var slider_position_percent = remap(
		slider.position.y,
		slider_max_pos,
		slider_min_pos,
		0,
		1)
	if slider_position_percent < 0.005:
		$StrokeDurationLabel.text = "IN: OFF"
	else:
		var display_text: String
		if %Menu/LoopSettings/DisplayMode/OptionButton.selected == 0:
			display_text = "IN: " + str(stroke_duration) + "s"
		else:
			var map = snappedf(remap(
				slider.position.y,
				slider_max_pos,
				slider_min_pos,
				1,
				100), 0.01)
			display_text = "IN: " + str(map) + "%"
		$StrokeDurationLabel.text = display_text


func _on_transition_item_selected(index):
	if link_button.button_pressed:
		out.get_node('AccelerationControls/Transition').select(index)
	get_parent().send_command()


func _on_easing_item_selected(index):
	if link_button.button_pressed:
		out.get_node('AccelerationControls/Easing').select(index)
	get_parent().send_command()
