extends Panel

@onready var scroll_item: Panel = $Scroll/VBox/ScrollItem

var selected_index

var drag_delta: float

var mode: Enums.FileListMode


func _ready():
	$Scroll/VBox.remove_child(scroll_item)

func _on_item_selected(item):
	if drag_delta > 7:
		return
	deselect_all()
	item.select()
	match mode:
		Enums.FileListMode.PATH:
			get_parent().get_node('HBox/AddPath').disabled = false
		Enums.FileListMode.PLAYLIST:
			get_parent().get_node('HBox/LoadPlaylist').disabled = false
	selected_index = item.get_index()
	var timer = item.get_node('Timer')
	if timer.time_left:
		match mode:
			Enums.FileListMode.PATH:
				get_parent()._on_add_path_pressed()
			Enums.FileListMode.PLAYLIST:
				get_parent()._on_load_playlist_pressed()
	else:
		timer.start()

func add_item(item_text: String):
	var item = scroll_item.duplicate()
	item.get_node('Label').text = item_text
	$Scroll/VBox.add_child(item)
	var item_button = item.get_node('Button')
	item_button.connect('pressed', _on_item_selected.bind(item))

func get_item_text(item_index) -> String:
	return $Scroll/VBox.get_child(item_index).get_node('Label').text

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
	for item in $Scroll/VBox.get_children():
		$Scroll/VBox.remove_child(item)
