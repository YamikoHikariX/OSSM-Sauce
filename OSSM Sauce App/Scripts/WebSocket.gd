extends Node

var server: WebSocketServer
var connected_clients: Array[int] = []

var port: int = 8008
var host: String = "0.0.0.0"

var server_started: bool
var ossm_connected: bool

func _ready():
	server = WebSocketServer.new()
	server.client_connected.connect(_on_client_connected)
	server.client_disconnected.connect(_on_client_disconnected)
	server.message_received.connect(_on_message_received)
	server.data_received.connect(_on_data_received)
	server.server_error.connect(_on_server_error)
	# Listen for position control events to notify clients
	%PositionControls.position_move_complete.connect(_on_position_move_complete)
	%PositionControls.position_queue_complete.connect(_on_position_queue_complete)


func start_server():
	server_started = server.start(port, host)
	if server_started:
		print("WebSocket server started successfully on port %d" % port)
	else:
		printerr("Failed to start WebSocket server on port %d" % port)
	
	update_server_status()


# Process signals from the main thread to listen for incoming messages
func _process(_delta: float) -> void:
	if server and server.is_listening():
		server.process()


func update_server_status():
	if server.is_listening():
		print("Server Status: Running on %s:%d" % [host, port])
		%WiFi.self_modulate = Color.WHITE
		%WiFi.show()
		server_started = true
	else:
		print("Server Status: Stopped")
		%WiFi.hide()
		server_started = false
		ossm_connected = false
	
	update_client_count()


func update_client_count():
	print("Connected Clients: %d" % server.get_client_count())


func _on_client_connected(client_id):
	print("Client connected: #%d" % client_id)
	connected_clients.append(client_id)
	update_client_count()


func _on_client_disconnected(client_id, code):
	print("Client disconnected: #%d (code: %d)" % [client_id, code])
	connected_clients.erase(client_id)
	update_client_count()


func _on_message_received(client_id, message):
	print("Text message from client %d: %s" % [client_id, message])

	var json = JSON.new()
	var result = json.parse(message)
	if result != OK:
		printerr("Failed to parse JSON message: %s" % json.error_string)
		return

	var data = json.data
	var ack: Dictionary = {"received": {}}

	if data.has("bpm"):
		await %LoopControls.send_command_by_bpm(data["bpm"])
		print("BPM command received: %f" % data["bpm"])
		if owner.paused:
			owner.play()
		ack.received.bpm = data["bpm"]

	if data.has("set_mode"):
		var mode = data["set_mode"]
		if mode == "loop":
			%Menu.select_mode(2)
		elif mode == "position":
			%Menu.select_mode(1)

		if %WebSocket.ossm_connected:
			await owner.homing_complete
		ack.received.set_mode = mode

	if data.has("position"):
		if data.has("duration"):
			%PositionControls.move_duration = data["duration"]

		if data.has("trans_type"):
			%PositionControls.move_trans_type = int(data["trans_type"])

		%PositionControls.move_slider_to(data["position"])
		ack.received.position = data["position"]
		if data.has("duration"): ack.received.position_duration = data["duration"]
		if data.has("trans_type"): ack.received.position_trans_type = data["trans_type"]
		if data.has("ease_type"): ack.received.position_ease_type = data["ease_type"]

	if data.has("queue_position"):
		var q_duration = data.get("duration", null)
		var q_trans = data.get("trans_type", null)
		var q_ease = data.get("ease_type", null)
		
		%PositionControls.queue_move_slider_to(data["queue_position"], q_duration, q_trans, q_ease)
		ack.received.queue_position = data["queue_position"]
		if q_duration != null: ack.received.queue_duration = q_duration
		if q_trans != null: ack.received.queue_trans_type = q_trans
		if q_ease != null: ack.received.queue_ease_type = q_ease

	if data.has("position_stop"):
		%PositionControls.stop()
		ack.received.position_stop = true

	if data.has("position_clear_queue"):
		%PositionControls.clear_queue()
		ack.received.position_clear_queue = true

	if data.has("position_range_min"):
		%RangePanel.set_actual_min_percent(data["position_range_min"])
		print("Min range position received: %f" % data["position_range_min"])
		ack.received.position_range_min = data["position_range_min"]

	if data.has("position_range_max"):
		%RangePanel.set_actual_max_percent(data["position_range_max"])
		print("Max range position received: %f" % data["position_range_max"])
		ack.received.position_range_max = data["position_range_max"]

	if data.has("stop"):
		await %LoopControls.send_command_by_bpm(0)
		print("Stop command received")
		if not owner.paused:
			owner.pause()
		ack.received.stop = true

	if data.has("pullout"):
		await %LoopControls.send_command_by_bpm(0)
		owner.home_to(0)
		owner.pause()
		print("Pullout command received")
		ack.received.pullout = true

	# Only send acknowledgement if something recognized was received
	if ack.received.size() > 0:
		_send_json_to_client(client_id, ack)


func _on_data_received(_client_id, data):
	if data[0] == OSSM.Command.RESPONSE:
		match data[1]:
			OSSM.Command.CONNECTION:
				%WiFi.self_modulate = Color.SEA_GREEN
				%WiFi.show()
				ossm_connected = true
				owner.apply_device_settings()
				owner.home_to(0)
			OSSM.Command.HOMING:
				%CircleSelection.hide()
				%CircleSelection.homing_lock = false
				var display = [
					%PositionControls,
					%LoopControls,
					%PathDisplay,
					%ActionPanel,
					%Menu]
				for node in display:
					node.modulate.a = 1
				owner.emit_signal("homing_complete")
				if AppMode.active == AppMode.MOVE:
					if owner.active_path_index != null:
						%CircleSelection.show_play()
				elif AppMode.active == AppMode.POSITION:
					owner.play()


func _on_position_move_complete(position: int):
	_broadcast_json({"event": "position_move_complete", "position": position})


func _on_position_queue_complete():
	_broadcast_json({"event": "position_queue_complete"})


func _on_server_error(error):
	printerr("Server error: %s" % error)


func _exit_tree():
	if server and server.is_listening():
		server.stop()


# Internal utility helpers -------------------------------------------------
func _send_json_to_client(client_id: int, data: Dictionary) -> void:
	if not server or not server.is_listening():
		return
	var json_text: String = JSON.stringify(data)
	server.send_text(client_id, json_text)
	

func _broadcast_json(data: Dictionary) -> void:
	if not server or not server.is_listening():
		return
	var json_text: String = JSON.stringify(data)
	for client_id in server.get_client_ids():
		server.send_text(client_id, json_text)
