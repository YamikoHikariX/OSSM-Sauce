extends Panel

@onready var buttons: Array = [
	%PathControls/Up,
	%PathControls/Down,
	%PathControls/HBox/Play,
	%PathControls/HBox/Pause,
	%PathControls/HBox/Restart,
	%PathControls/HBox/Delete]

const TabIndexToMode = {
	0: Enums.AppMode.MOVE,
	1: Enums.AppMode.POSITION,
	2: Enums.AppMode.LOOP,
}

func _ready() -> void:
	set_min_stroke_duration(Settings.get_setting(Section.STROKE_SETTINGS, Key.MIN_DURATION))

	set_max_stroke_duration(Settings.get_setting(Section.STROKE_SETTINGS, Key.MAX_DURATION))

	set_stroke_duration_display_mode(Settings.get_setting(Section.STROKE_SETTINGS, Key.DISPLAY_MODE))

	select_mode(Settings.get_setting(Section.APP_SETTINGS, Key.MODE))

func _on_Back_pressed():
	tween(false)
	$Playlist.deselect_all()


func _on_Settings_pressed():
	%SettingsPage.show()
	hide()


func _on_Exit_pressed():
	Settings.save()
	get_tree().quit()


func _on_up_pressed():
	flash_button(%PathControls/Up)
	var selected_index = $Playlist.selected_index
	if selected_index > 0:
		$Playlist.move_item(selected_index, selected_index - 1)


func _on_down_pressed():
	flash_button(%PathControls/Down)
	var selected_index = $Playlist.selected_index
	if selected_index < $Playlist/Scroll/VBox.get_child_count() - 1:
		$Playlist.move_item(selected_index, selected_index + 1)


func _on_play_pressed():
	flash_button(%PathControls/HBox/Play)
	tween(false)
	%ActionPanel.clear_selections()
	%ActionPanel/Play.hide()
	%ActionPanel/Pause.show()
	var index = $Playlist.selected_index
	if Main.node.active_path_index == index:
		Main.node.play()
	else:
		Main.node.active_path_index = index
		Main.node.display_active_path_index()
		$Playlist/Scroll/VBox.get_child(index).set_active()
		if Main.node.connected_to_ossm:
			%CircleSelection.show_hourglass()
			%PositionControls.modulate.a = 0.05
			Main.node.home_to(0)
		else:
			%CircleSelection.show_play()


func _on_pause_pressed():
	Main.node.pause()
	%ActionPanel.clear_selections()
	%ActionPanel/Play.show()
	%ActionPanel/Pause.hide()
	refresh_selection()


func _on_restart_pressed():
	hide()
	%ActionPanel.show()
	flash_button(%PathControls/HBox/Restart)
	Main.node.display_active_path_index()
	refresh_selection()
	if Main.node.connected_to_ossm:
		%CircleSelection.show_hourglass()
		%PathTab.modulate.a = 0.05
		Main.node.home_to(0)
	else:
		%CircleSelection.show_play()


func _on_delete_pressed():
	flash_button(%PathControls/HBox/Delete)
	var selected_item = $Playlist.selected_index
	if Main.node.active_path_index == selected_item:
		Main.node.active_path_index = null
		%PathControls.hide()
		if not Main.node.paused:
			_on_pause_pressed()
	%PathTab/Paths.remove_child(%PathTab/Paths.get_child(selected_item))
	var pl_item = $Playlist/Scroll/VBox.get_child(selected_item)
	$Playlist/Scroll/VBox.remove_child(pl_item)
	Main.node.paths.remove_at(selected_item)
	Main.node.markers.remove_at(selected_item)
	$Playlist.selected_index = null
	if $Playlist/Scroll/VBox.get_child_count() == 0:
		$Main/PlaylistButtons/SavePlaylist.disabled = true
	refresh_selection()


func _on_load_playlist_pressed():
	%AddFile.show_playlists()
	hide()


func _on_save_playlist_pressed():
	hide_menu_buttons()
	$SavePlaylist.show()
	$Header.hide()


func _on_add_path_pressed():
	%AddFile.show_paths()
	hide()


func _on_add_delay_pressed():
	hide_menu_buttons()
	$AddDelay.show()
	$Header.hide()


func hide_menu_buttons():
	$Main/PlaylistButtons.hide()
	$Main/PathButtons.hide()
	%PathControls.hide()
	$Main/Mode.hide()


func refresh_selection():
	if $Main/Mode.selected != 0:
		return
	var selected_item = $Playlist.selected_index
	if selected_item != null:
		var item = $Playlist/Scroll/VBox.get_child(selected_item)
		$Playlist._on_item_selected(item)
	else:
		%PathControls.hide()


func show_play():
	%PathControls/HBox/Pause.hide()
	%PathControls/HBox/Play.show()
	%PathControls.show()


func show_pause():
	%PathControls/HBox/Pause.show()
	%PathControls/HBox/Play.hide()
	%PathControls.show()


func flash_button(button: Node):
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	var start_color: Color = Color.DARK_ORANGE
	var end_color: Color = Color.WHITE
	tween.tween_method(button.set_self_modulate, start_color, end_color, 0.6)


const ANIM_TIME = 0.35
func tween(activating: bool = true):
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel()
	var start_color: Color = modulate
	var end_color: Color = start_color
	start_color.a = 0
	end_color.a = 1
	var colors: Array = [start_color, end_color]
	if activating:
		refresh_selection()
	else:
		for button in buttons:
			button.disabled = true
		colors.reverse()
		%ActionPanel.show()
		tween.tween_callback(anim_finished).set_delay(ANIM_TIME)
	tween.tween_method(set_modulate, colors[0], colors[1], ANIM_TIME)


var loop_playlist:bool
func _on_loop_playlist_button_toggled(toggled_on: bool) -> void:
	loop_playlist = toggled_on
	if toggled_on:
		$Main/LoopPlaylistButton.text = "Loop Playlist: ON"
	else:
		$Main/LoopPlaylistButton.text = "Loop Playlist: OFF"

func anim_finished():
	for button in buttons:
		button.disabled = false
	%ActionPanel/Menu/Selection.hide()
	hide()


func set_min_stroke_duration(value):
	$LoopSettings/MinStrokeDuration/SpinBox.set_value(value)


func set_max_stroke_duration(value):
	$LoopSettings/MaxStrokeDuration/SpinBox.set_value(value)


func set_stroke_duration_display_mode(value):
	$LoopSettings/DisplayMode/OptionButton.select(value)
	_on_stroke_duration_display_mode_changed(value)

func _on_min_stroke_duration_changed(value):
	Main.node.min_stroke_duration = value
	%LoopControls.reset_stroke_duration_sliders()
	Settings.set_setting(Section.STROKE_SETTINGS, Key.MIN_DURATION, value)

func _on_max_stroke_duration_changed(value):
	Main.node.max_stroke_duration = value
	%LoopControls.reset_stroke_duration_sliders()
	Settings.set_setting(Section.STROKE_SETTINGS, Key.MAX_DURATION, value)

func _on_stroke_duration_display_mode_changed(index):
	Settings.set_setting(Section.STROKE_SETTINGS, Key.DISPLAY_MODE, index)
	%LoopControls.update_stroke_duration_text()

func select_mode(new_app_mode: Enums.AppMode):
	print("Selecting mode: ", new_app_mode)
	var new_tab_index = TabIndexToMode.find_key(new_app_mode)
	print("New tab index: ", new_tab_index)

	$Main/Mode.select(new_tab_index)
	_on_mode_selected(new_tab_index)


func _on_mode_selected(index: int):
	var mode_id: int = TabIndexToMode[index]

	Main.node.send_command(Enums.CommandType.RESET)
	Main.node.home_to(0)
	if Main.node.connected_to_ossm:
		await Main.node.homing_complete

	Main.node.app_mode = mode_id
	match mode_id:
		Enums.AppMode.MOVE:
			%LoopControls/In.set_physics_process(false)
			%LoopControls/Out.set_physics_process(false)
			%ActionPanel.clear_selections()
			%ActionPanel/Play.show()
			%ActionPanel/Pause.hide()
			%LoopControls.hide()
			$LoopSettings.hide()
			%PathTab/Paths.show()
			%PathTab/Ball.show()
			$Main/PlaylistButtons.show()
			$Main/LoopPlaylistButton.show()
			$Main/PathButtons.show()
			%PathControls.show()
			$Playlist.show()
			if Main.node.active_path_index != null:
				Main.node.display_active_path_index()
			refresh_selection()
		
		Enums.AppMode.POSITION:
			Main.node.paused = true
			%LoopControls/In.set_physics_process(false)
			%LoopControls/Out.set_physics_process(false)
			%ActionPanel.clear_selections()
			%ActionPanel/Play.hide()
			%ActionPanel/Pause.show()
			%LoopControls.hide()
			$LoopSettings.hide()
			%PathTab/Paths.hide()
			%PathTab/Ball.hide()
			$Main/PlaylistButtons.hide()
			$Main/LoopPlaylistButton.hide()
			$Main/PathButtons.hide()
			%PathControls.hide()
			$Playlist.hide()
			Main.node.play()
		
		Enums.AppMode.LOOP:
			Main.node.paused = true
			var stop_pos = %LoopControls/In.slider_max_pos
			%LoopControls/In.touch_pos = stop_pos
			%LoopControls/Out.touch_pos = stop_pos
			%LoopControls/In/StrokeDurationSlider/Slider.position.y = stop_pos
			%LoopControls/Out/StrokeDurationSlider/Slider.position.y = stop_pos
			%LoopControls/In.stroke_duration = 0
			%LoopControls/Out.stroke_duration = 0
			%LoopControls.update_stroke_duration_text()
			%LoopControls/In.set_physics_process(true)
			%LoopControls/Out.set_physics_process(true)
			%LoopControls/In.input_active = false
			%LoopControls/Out.input_active = false
			%LoopControls/Pause.hide()
			%ActionPanel.clear_selections()
			%ActionPanel/Play.hide()
			%ActionPanel/Pause.show()
			%LoopControls.show()
			$LoopSettings.show()
			%PathTab/Paths.hide()
			%PathTab/Ball.hide()
			$Main/PlaylistButtons.hide()
			$Main/LoopPlaylistButton.hide()
			$Main/PathButtons.hide()
			%PathControls.hide()
			$Playlist.hide()
