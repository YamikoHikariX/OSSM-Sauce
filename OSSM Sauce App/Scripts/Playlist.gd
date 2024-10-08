extends Panel

@onready var Item: Panel = $Scroll/VBox/Item

var selected_index

var drag_delta: float


func _ready():
	$Scroll/VBox.remove_child(Item)


func _on_item_selected(item):
	if drag_delta > 7:
		return
	deselect_all()
	item.select()
	var index = item.get_index()
	selected_index = index
	var restart_button = %Menu/PathControls/HBox/Restart
	if Main.node.active_path_index == index and Main.node.frame > 0:
		restart_button.show()
	else:
		restart_button.hide()
	if not Main.node.paused and Main.node.active_path_index == index:
		%Menu.show_pause()
	else:
		%Menu.show_play()
	var timer = item.get_node('Timer')
	if timer.time_left:
		%Menu._on_play_pressed()
	else:
		timer.start()


func add_item(item_text: String):
	var item = Item.duplicate()
	item.get_node('Label').text = item_text
	$Scroll/VBox.add_child(item)
	var item_button = item.get_node('Button')
	item_button.connect('pressed', _on_item_selected.bind(item))
	%Menu/Main/PlaylistButtons/SavePlaylist.disabled = false


func move_item(current_index, new_index):
	var item = $Scroll/VBox.get_child(current_index)
	var path = %PathTab/Paths.get_child(current_index)
	$Scroll/VBox.move_child(item, new_index)
	%PathTab/Paths.move_child(path, new_index)
	selected_index = new_index
	
	var path_data = Main.node.paths[current_index]
	Main.node.paths.remove_at(current_index)
	Main.node.paths.insert(new_index, path_data)
	
	var marker_data = Main.node.markers[current_index]
	Main.node.markers.remove_at(current_index)
	Main.node.markers.insert(new_index, marker_data)
	
	var network_data = Main.node.network_paths[current_index]
	Main.node.network_paths.remove_at(current_index)
	Main.node.network_paths.insert(new_index, network_data)
	
	if Main.node.active_path_index == current_index:
		Main.node.active_path_index = new_index
	elif Main.node.active_path_index == new_index:
		Main.node.active_path_index = current_index


func get_items() -> Array:
	var items: Array
	for item in $Scroll/VBox.get_children():
		items.append(item.get_node('Label').text)
	return items


func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			drag_delta = 0
	if event is InputEventScreenDrag:
		drag_delta += abs(event.relative.y)
		$Scroll.scroll_vertical -= event.relative.y


func deselect_all():
	for item in $Scroll/VBox.get_children():
		item.deselect()


func clear():
	if Main.node.active_path_index != null:
		Main.node.active_path_index = null
		%Menu/PathControls.hide()
		if not Main.node.paused:
			%Menu._on_pause_pressed()
	Main.node.paths.clear()
	for item in $Scroll/VBox.get_children():
		$Scroll/VBox.remove_child(item)
	for path in %PathTab/Paths.get_children():
		%PathTab/Paths.remove_child(path)
	%PathTab/Ball.hide()
