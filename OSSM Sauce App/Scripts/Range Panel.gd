extends Panel

var hard_min_range_pos: float
var hard_max_range_pos: float

# New: actual limits, as percent inside [hard_min..hard_max]
# 0%  -> exactly at hard_min
# 100% -> exactly at hard_max
var actual_min_percent: float = 0.0
var actual_max_percent: float = 100.0

@onready var hard_min_slider: TextureRect = $RangeBar/MinSlider
@onready var hard_max_slider: TextureRect = $RangeBar/MaxSlider

var shown: bool = false

func _ready():
	$LabelTop.self_modulate.a = 0
	$LabelBot.self_modulate.a = 0
	hard_min_slider.gui_input.connect(hard_min_slider_gui_input)
	hard_max_slider.gui_input.connect(hard_max_slider_gui_input)
	hard_min_range_pos = hard_min_slider.position.y
	hard_max_range_pos = hard_max_slider.position.y

	# Ensure ordering
	_if_fix_actual_bounds()

	# On load, send current effective limits to OSSM
	_send_effective_min_to_ossm()
	_send_effective_max_to_ossm()


#
# --- Input (hard sliders) ---
#
func hard_min_slider_gui_input(event):
	if 'relative' in event and event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_LEFT:
			var drag_pos = hard_min_slider.position.y + event.relative.y
			var max_range = hard_max_slider.position.y + hard_max_slider.size.y
			hard_min_slider.position.y = clamp(drag_pos, max_range, hard_min_range_pos)

			# Hard limits changed -> recompute & send effective actual limits
			_update_hard_min_bookkeeping()
			if %Mode.selected != 1:
				_send_effective_min_to_ossm()
				if AppMode.active == AppMode.VIBRATE:
					if %VibrationControls.pulse_active:
						%VibrationControls.pulse_controller()
					else:
						%VibrationControls.send_vibrate_command()


func hard_max_slider_gui_input(event):
	if 'relative' in event and event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_LEFT:
			var drag_pos = hard_max_slider.position.y + event.relative.y
			var min_range = hard_min_slider.position.y - hard_min_slider.size.y
			hard_max_slider.position.y = clamp(drag_pos, hard_max_range_pos, min_range)

			# Hard limits changed -> recompute & send effective actual limits
			_update_hard_max_bookkeeping()
			if %Mode.selected != 1:
				_send_effective_max_to_ossm()
				if AppMode.active == AppMode.VIBRATE:
					if %VibrationControls.pulse_active:
						%VibrationControls.pulse_controller()
					else:
						%VibrationControls.send_vibrate_command()


#
# --- Effective value helpers (map actual% into hard window) ---
#
func _hard_span() -> float:
	return hard_max_slider.position.y - hard_min_slider.position.y

func _pos_from_actual_percent(p: float) -> float:
	# p is 0..100 inside [hard_min..hard_max]
	var t := clampf(p, 0.0, 100.0) / 100.0
	return lerp(hard_min_slider.position.y, hard_max_slider.position.y, t)

func _range_map_from_pos(pos_y: float) -> int:
	# Device map: 0..10000 across current hard window
	return int(remap(pos_y, hard_min_range_pos, hard_max_range_pos, 0.0, 10000.0))

func _percent_label_from_pos(pos_y: float) -> float:
	# UI percent across hard window (0..100 for label)
	return remap(pos_y, hard_min_range_pos, hard_max_range_pos, 0.0, 100.0)


#
# --- Sending effective limits to OSSM (actual inside hard) ---
#
func _send_effective_min_to_ossm():
	_if_fix_actual_bounds()
	var effective_pos := _pos_from_actual_percent(actual_min_percent)
	var range_map := _range_map_from_pos(effective_pos)
	var label_pct := _percent_label_from_pos(effective_pos)

	if %WebSocket.ossm_connected:
		print("Sending effective min to OSSM: pos %f" % effective_pos)
		const MIN_RANGE = 0
		var command: PackedByteArray
		command.resize(4)
		command.encode_u8(0, OSSM.Command.SET_RANGE_LIMIT)
		command.encode_u8(1, MIN_RANGE)
		command.encode_u16(2, range_map)
		%WebSocket.server.broadcast_binary(command)

	var text_value = str(snapped(label_pct, 0.01))
	$LabelBot.text = "Min Position:\n" + text_value + "%"

func _send_effective_max_to_ossm():
	_if_fix_actual_bounds()
	var effective_pos := _pos_from_actual_percent(actual_max_percent)
	var range_map := _range_map_from_pos(effective_pos)
	var label_pct := _percent_label_from_pos(effective_pos)

	if %WebSocket.ossm_connected:
		print("Sending effective max to OSSM: pos %f" % effective_pos)
		const MAX_RANGE = 1
		var command: PackedByteArray
		command.resize(4)
		command.encode_u8(0, OSSM.Command.SET_RANGE_LIMIT)
		command.encode_u8(1, MAX_RANGE)
		command.encode_u16(2, range_map)
		%WebSocket.server.broadcast_binary(command)

	var text_value = str(snapped(label_pct, 0.01))
	$LabelTop.text = "Max Position:\n" + text_value + "%"


#
# --- Backwards-compatible “update_*_range” (called when hard sliders move) ---
#     These now recompute & send from ACTUAL percents inside the new hard window.
#
func update_min_range():
	_send_effective_min_to_ossm()

func update_max_range():
	_send_effective_max_to_ossm()


#
# --- Public setters ---
#
# Set hard sliders by percent across the *full* hard range (for programmatic control)
func set_min_slider_pos(percent):
	percent = clampf(percent, 0.0, 100.0)
	var slider_map = remap(percent, 0.0, 100.0, hard_min_range_pos, hard_max_range_pos)
	hard_min_slider.position.y = slider_map
	_update_hard_min_bookkeeping()
	update_min_range()

func set_max_slider_pos(percent):
	percent = clampf(percent, 0.0, 100.0)
	var slider_map = remap(percent, 0.0, 100.0, hard_min_range_pos, hard_max_range_pos)
	hard_max_slider.position.y = slider_map
	_update_hard_max_bookkeeping()
	update_max_range()

# New: set actual min/max as percents inside the current hard window
# Example from your note:
# hard_min=10, hard_max=100, actual_min=10 -> effective is 10% of span -> 19
func set_actual_min_percent(percent):
	print("Setting actual min percent to %f" % percent)
	actual_min_percent = clampf(percent, 0.0, 100.0)
	_if_fix_actual_bounds()
	_send_effective_min_to_ossm()

func set_actual_max_percent(percent):
	print("Setting actual max percent to %f" % percent)
	actual_max_percent = clampf(percent, 0.0, 100.0)
	_if_fix_actual_bounds()
	_send_effective_max_to_ossm()


#
# --- Persistence & sanity ---
#
func _update_hard_min_bookkeeping():
	# Save hard min slider’s *visual* percent for UI restoration if you need it
	var hard_min_pct := remap(hard_min_slider.position.y, hard_min_range_pos, hard_max_range_pos, 0.0, 100.0)
	owner.user_settings.set_value('range_slider_min', 'position_percent', hard_min_pct)

func _update_hard_max_bookkeeping():
	var hard_max_pct := remap(hard_max_slider.position.y, hard_min_range_pos, hard_max_range_pos, 0.0, 100.0)
	owner.user_settings.set_value('range_slider_max', 'position_percent', hard_max_pct)

func _if_fix_actual_bounds():
	# Ensure actual_min <= actual_max
	if actual_min_percent > actual_max_percent:
		var mid := (actual_min_percent + actual_max_percent) * 0.5
		actual_min_percent = mid
		actual_max_percent = mid


#
# --- UI animation (unchanged) ---
#
func tween(activating: bool = true):
	shown = activating
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel()
	var viewport_right_edge = get_viewport_rect().size.x
	var viewport_middle = get_viewport_rect().size.x / 2
	var outside_pos := Vector2(viewport_right_edge, position.y)
	var inside_pos := Vector2(viewport_middle, outside_pos.y)
	var positions: Array = [outside_pos, inside_pos]
	if not activating:
		positions.reverse()
	tween.tween_method(set_position, position, positions[1], owner.ANIM_TIME)
	var start_color: Color = Color.WHITE
	var end_color: Color = start_color
	start_color.a = 0
	end_color.a = 1
	var colors: Array = [start_color, end_color]
	if not activating:
		colors.reverse()
		tween.tween_callback(anim_finished).set_delay(owner.ANIM_TIME)
	var visuals = [$LabelBot, $LabelTop]
	for node in visuals:
		tween.tween_method(node.set_self_modulate, colors[0], colors[1], owner.ANIM_TIME)

func anim_finished():
	%ActionPanel/Range/Selection.hide()
	%ActionPanel.self_modulate.a = 1

func _on_back_button_pressed():
	if %WebSocket.ossm_connected and %Mode.selected == 1:
		# Re-send effective min/max before leaving
		%CircleSelection.show_hourglass()
		%PositionControls.modulate.a = 0.05
		owner.home_to(%PositionControls.last_position)
	_send_effective_min_to_ossm()
	_send_effective_max_to_ossm()
	tween(false)
	%ActionPanel.show()

func _input(event: InputEvent) -> void:
	if not shown: return
	if event is InputEventMouseButton and event.pressed:
		if not get_global_rect().has_point(event.position):
			_on_back_button_pressed()
