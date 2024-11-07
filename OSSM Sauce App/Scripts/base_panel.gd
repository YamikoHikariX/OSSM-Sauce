extends Panel
class_name BasePanel

enum SlideDirection { SLIDE_FROM_LEFT, SLIDE_FROM_RIGHT }

var slide_direction: SlideDirection = SlideDirection.SLIDE_FROM_LEFT

var closed_pos: Vector2

func _ready():
	closed_pos = position
	set_process_input(false)
	initialize_panel()

func initialize_panel():
	pass

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if not get_global_rect().has_point(event.position):
			_on_outside_click()

func _on_outside_click():
	tween(false)

func tween(activating: bool = true):
	set_process_input(activating)
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel()
	
	var viewport_size = get_viewport_rect().size.x
	var open_pos
	match slide_direction:
		SlideDirection.SLIDE_FROM_LEFT:
			open_pos = Vector2(0, position.y)
		SlideDirection.SLIDE_FROM_RIGHT:
			open_pos = Vector2(size.x, position.y)

	var positions: Array = [open_pos, closed_pos]
	if activating:
		positions.reverse()
	tween.tween_method(set_position, position, positions[1], Main.node.ANIM_TIME)
	
	var visuals = [$LabelBot, $LabelTop]
	for node in visuals:
		tween.tween_method(
			node.set_self_modulate,
			Color(1, 1, 1, 0),
			Color(1, 1, 1, 1),
			Main.node.ANIM_TIME)

func open():
	tween(true)

func close():
	tween(false)
