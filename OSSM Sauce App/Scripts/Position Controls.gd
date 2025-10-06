extends Control
class_name PositionControls

signal position_move_complete(position: int)
signal position_queue_complete()

@onready var slider: TextureRect = $MovementBar/Slider

@onready var max_range: float = $MovementBar/SliderTop.position.y
@onready var min_range: float = slider.position.y

@onready var touch_pos: float = min_range

var smoothing: float

var last_position: int
var input_active: bool

# Timed movement state
var move_start_y: float
var move_elapsed: float = 0.0
var move_duration: float = 1.0:
	set(new_value):
		move_duration = clamp(new_value, 0.0, 20.0)

var move_active: bool = false

# Transition / easing for timed moves (re-uses LoopControls.Trans enum values)
var move_trans_type: Tween.TransitionType = Tween.TRANS_SINE
var move_ease: int = Tween.EASE_IN_OUT

# Queue of pending moves using PositionMove objects
var move_queue: Array[PositionMove] = []

class PositionMove:
	var dest_y: float
	var duration: float
	var duration_set: bool = false
	var trans_set: bool = false
	var trans_type: Tween.TransitionType
	var ease_set: bool = false
	var ease_type: Tween.EaseType

	func _init(p_dest_y: float, p_duration: Variant = null, p_trans_type: Variant = null, p_ease_type: Variant = null):
		dest_y = p_dest_y
		if p_duration != null:
			duration = float(p_duration)
			duration_set = true
		if p_trans_type != null:
			trans_set = true
			trans_type = p_trans_type
		if p_ease_type != null:
			ease_set = true
			ease_type = p_ease_type

func _ready():
	_on_smoothing_slider_value_changed($Smoothing/HSlider.value)

func _physics_process(delta):
	if move_active:
		move_elapsed += delta
		var t: float = move_elapsed / move_duration
		if t >= 1.0:
			t = 1.0
			move_active = false
		# Apply easing curve using Tween's interpolate_value to derive eased t
		var eased_t: float = Tween.interpolate_value(0.0, 1.0, t, 1.0, move_trans_type, move_ease)
		var new_y: float = lerp(move_start_y, touch_pos, eased_t)
		slider.position.y = clamp(new_y, max_range, min_range)
		if not move_active:
			_emit_move_complete_if_needed()
	else:
		var pos = lerp(slider.position.y, touch_pos, delta * smoothing)
		slider.position.y = clamp(pos, max_range, min_range)

	# If no active move, try to start the next queued move
	if not move_active and move_queue.size() > 0:
		_start_next_queued_move()
	elif not move_active and move_queue.size() == 0:
		# No active move and queue empty; emit queue complete
		# (This will also cover the case where the last queued move just finished)
		_emit_queue_complete_if_needed()

	var mapped_pos: int = int(remap(slider.position.y, min_range, max_range, 0, 10000))
	if %WebSocket.ossm_connected and last_position != mapped_pos:
		var command: PackedByteArray
		command.resize(5)
		command.encode_u8(0, OSSM.Command.POSITION)
		command.encode_u32(1, mapped_pos)
		%WebSocket.server.broadcast_binary(command)
		last_position = mapped_pos

func move_slider_to(value: int):
	# Remap from 0-100 to min_range-max_range
	var remapped_value: float = remap(value, 0, 100, min_range, max_range)

	if move_duration > 0.1:
		# Start a deterministic timed move (linear interpolation over 'duration' seconds)
		move_start_y = slider.position.y
		touch_pos = remapped_value
		move_elapsed = 0.0
		move_active = true
		print("Moving to %f over %f seconds with transition %d and ease %d" % [remapped_value, move_duration, move_trans_type, move_ease])
	else:
		# Immediate target change; smoothing/existing easing will bring it in
		touch_pos = remapped_value
		move_active = false

func queue_move_slider_to(value: int, duration: Variant = null, trans_type: Variant = null, ease_type: Variant = null) -> void:
	# Queue a move specifying only required position (0-100). Other params optional; if omitted, current settings persist.
	# duration: seconds (Variant) - if null uses existing move_duration at execution time; if provided overrides only for this move.
	# trans_type: Tween.TransitionType enum value or null to keep current.
	# ease_type: Tween.EASE_* constant or null to keep current.
	var remapped_value: float = remap(value, 0, 100, min_range, max_range)
	var move := PositionMove.new(remapped_value, duration, trans_type, ease_type)
	move_queue.append(move)
	if not move_active:
		_start_next_queued_move()

func queue_position_move(move: PositionMove) -> void:
	# Directly enqueue a pre-constructed PositionMove
	move_queue.append(move)
	if not move_active:
		_start_next_queued_move()

func clear_queue() -> void:
	# Clears pending moves only; active move (if any) continues.
	move_queue.clear()

func stop() -> void:
	# Immediately halts current movement and clears queue; leaves slider where it is.
	move_active = false
	move_elapsed = 0.0
	touch_pos = slider.position.y # Prevent smoothing from drifting
	move_queue.clear()
	_emit_queue_complete_if_needed()

func _start_next_queued_move() -> void:
	if move_queue.is_empty():
		return
	var next: PositionMove = move_queue.pop_front()
	move_start_y = slider.position.y
	touch_pos = next.dest_y
	# Only override attributes that are explicitly set in the queued move
	if next.duration_set:
		move_duration = clamp(next.duration, 0.0, 20.0)
	if next.trans_set:
		move_trans_type = next.trans_type
	if next.ease_set:
		move_ease = next.ease_type
	move_elapsed = 0.0
	if move_duration > 0.1:
		move_active = true
		print("[Queue] Moving to %f over %f seconds (trans %d ease %d)" % [touch_pos, move_duration, move_trans_type, move_ease])
	else:
		# Immediate move; update position and emit completion
		slider.position.y = clamp(touch_pos, max_range, min_range)
		_emit_move_complete_if_needed()
		if move_queue.is_empty():
			_emit_queue_complete_if_needed()

func _emit_move_complete_if_needed():
	# Determine current logical position (0-100) and emit
	var mapped_pos: int = int(remap(slider.position.y, min_range, max_range, 0, 100))
	position_move_complete.emit(mapped_pos)

var _queue_complete_announced: bool = false
func _emit_queue_complete_if_needed():
	if move_queue.is_empty() and not move_active:
		if not _queue_complete_announced:
			position_queue_complete.emit()
			_queue_complete_announced = true
	else:
		# Reset flag if queue refills
		_queue_complete_announced = false

func _input(event):
	if input_active:
		var offset = 265
		touch_pos = event.position.y - offset
		move_active = false # cancel timed movement on manual drag
	elif event is InputEventJoypadMotion:
		var input_position = Input.get_action_strength("right_trigger")
		touch_pos = remap(input_position, 0, 1, min_range, max_range)
		move_active = false # cancel timed movement on joystick input


func _on_slider_gui_input(event):
	if event is InputEventScreenDrag:
		input_active = true
		move_active = false
	else:
		input_active = false


func _on_smoothing_slider_value_changed(value):
	var min_value = $Smoothing/HSlider.min_value
	var max_value = $Smoothing/HSlider.max_value
	smoothing = max_value - (value - min_value)
	owner.user_settings.set_value('app_settings', 'smoothing_slider', value)


func activate(force_immediate: bool = false):
	touch_pos = min_range
	last_position = 0
	$MovementBar/Slider.position.y = min_range
	move_active = false
	if force_immediate:
		move_duration = 0.0
	set_physics_process(true)
	set_process_input(true)
	owner.play()
	show()


func deactivate():
	set_physics_process(false)
	set_process_input(false)
	hide()
