extends Panel


func _ready() -> void:
	if UserSettings.cfg.has_section_key('app_settings', 'last_server_connection'):
		hide()

func _on_play_button_pressed():
	clear_selections()
	self_modulate.a = 1.2
	%CircleSelection.hide_and_reset()
	$Play/Selection.show()
	$Timer.start()
	match owner.app_mode:
		Enums.AppMode.MOVE:
			if owner.active_path_index != null:
				owner.play()
				$Play.hide()
				$Pause/Selection.show()
				$Pause.show()
		Enums.AppMode.LOOP:
			%LoopControls.active = true
			owner.play()
			%LoopControls/Pause.hide()
			$Play.hide()
			$Pause/Selection.show()
			$Pause.show()
		Enums.AppMode.POSITION:
			%PositionControls.set_physics_process(true)
			%PositionControls.set_process_input(true)
			owner.play()
			$Play.hide()
			$Pause/Selection.show()
			$Pause.show()


func _on_pause_button_pressed():
	match owner.app_mode:
		Enums.AppMode.MOVE:
			clear_selections()
			self_modulate.a = 1.2
			%CircleSelection.hide_and_reset()
			$Pause/Selection.show()
			owner.pause()
			$Timer.stop()
			$Pause.hide()
			$Play/Selection.show()
			$Play.show()
		Enums.AppMode.LOOP:
			owner.pause()
			%LoopControls.active = false
			%LoopControls/Pause.show()
			%LoopControls.set_loop_bpm(0)
			$Play.show()
			$Play/Selection.show()
			$Pause.hide()
		Enums.AppMode.POSITION:
			%PositionControls.set_physics_process(false)
			%PositionControls.set_process_input(false)
			owner.pause()
			$Play.show()
			$Play/Selection.show()
			$Pause.hide()


func _on_speed_button_pressed():
	clear_selections()
	self_modulate.a = 1.2
	%CircleSelection.hide_and_reset()
	$Speed/Selection.show()
	%SpeedPanel.tween()
	$Timer.stop()
	hide()


func _on_range_button_pressed():
	clear_selections()
	self_modulate.a = 1.2
	%CircleSelection.hide_and_reset()
	$Range/Selection.show()
	%RangePanel.tween()
	$Timer.stop()
	hide()


func _on_menu_button_pressed():
	clear_selections()
	self_modulate.a = 1.2
	%CircleSelection.hide_and_reset()
	$Menu/Selection.show()
	%Menu.tween()
	$Timer.stop()
	hide()
	%Menu.show()


func _on_timer_timeout():
	self_modulate.a = 1
	clear_selections()


func clear_selections():
	for button in get_children():
		if button.has_node('Selection'):
			button.get_node('Selection').hide()
