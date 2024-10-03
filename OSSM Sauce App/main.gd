extends Control

var app_version_number: String = "1.1.0"

const ANIM_TIME = 0.65

var websocket = WebSocketPeer.new()
var xtoys_websocket = WebSocketPeer.new()

var connected_to_server: bool
var connected_to_ossm: bool

var ticks_per_second: int

var path_speed: int = 30

var paused: bool = true

var active_path_index

var paths: Array
var markers: Array
var network_paths: Array

var frame: int

var app_mode: Enums.AppMode

var max_speed: int
var max_acceleration: int

var min_stroke_duration: float
var max_stroke_duration: float

signal homing_complete

@onready var PATH_TOP = %PathDisplay/PathArea.position.y
@onready var PATH_BOTTOM = PATH_TOP + %PathDisplay/PathArea.size.y

@onready var ossm_connection_timeout: Timer = %Settings/Network/ConnectionTimeout

var position_drag: float = 0.0
var position_axis: float = 0.0

signal gamepad_stick_input(position: float)
signal gamepad_axis_input(axis: float)

func _init():
    Main.node = self

    max_speed = 25000
    max_acceleration = 500000


func _ready():
    xtoys_websocket.connect_to_url("wss://webhook.xtoys.app/56rrHim4ouVh")

    var physics_ticks_setting_path = "physics/common/physics_ticks_per_second"
    ticks_per_second = ProjectSettings.get_setting(physics_ticks_setting_path)
    # set_process(false)
    %PositionControls.set_physics_process(false)
    
    min_stroke_duration = %Menu/LoopSettings/MinStrokeDuration/SpinBox.value
    max_stroke_duration = %Menu/LoopSettings/MaxStrokeDuration/SpinBox.value
    
    max_speed = int(%Settings/Sliders/MaxSpeed/TextEdit.text)
    max_acceleration = int(%Settings/Sliders/MaxAcceleration/TextEdit.text)
    
    for node in [%Menu, %Settings, %SpeedPanel, %RangePanel]:
        node.self_modulate.a = 1.65
    
    %PathDisplay/Ball.position.x = %PathDisplay/PathArea.size.x / 2
    
    check_root_directory()

    UserSettings.restore_window_size()
    center_window()

func center_window():
    if OS.get_name() != 'Android':
        var window_size = get_viewport().size
        var screen_size = DisplayServer.screen_get_size()
        var centered_position = Vector2(
            (screen_size.x - window_size.x) / 2,
            (screen_size.y - window_size.y) / 2)
        DisplayServer.window_set_position(centered_position)
        get_viewport().size_changed.connect(_on_window_size_changed)

var marker_index: int
func _physics_process(_delta):
    if app_mode == Enums.AppMode.POSITION:
        handle_position_mode_gamepad_input()

    if app_mode == Enums.AppMode.MOVE:
        handle_path_mode_physics()

var previous_position_drag: float = 0.0
var previous_position_axis: float = 0.0

func handle_position_mode_gamepad_input():
    position_axis = Input.get_action_strength("position_axis")
    position_drag = Input.get_axis("position_in", "position_out")
    position_drag = position_drag if abs(position_drag) > 0.02 else 0.0
    if not (previous_position_drag == 0.0 and position_drag == previous_position_drag): 
        gamepad_stick_input.emit(position_drag)
        previous_position_drag = position_drag
    if not (previous_position_axis == 0.0 and position_axis == previous_position_axis):
        gamepad_axis_input.emit(position_axis)
        previous_position_axis = position_axis

func handle_path_mode_physics():
    if paused or paths[active_path_index].is_empty(): return
    
    if frame >= paths[active_path_index].size() - 1:
        
        if network_paths.size() > active_path_index + 1:
            var overreach_index = marker_index - network_paths[active_path_index].size() + 1
            var next_path = network_paths[active_path_index + 1]
            websocket.send(next_path[overreach_index])
        
        if active_path_index < paths.size() - 1:
            var path_list = %Menu/Playlist/Scroll/VBox
            var next_index = active_path_index + 1
            var next_path = path_list.get_child(next_index)
            active_path_index = next_index
            display_active_path_index(false, false)
            %Menu/Playlist._on_item_selected(next_path)
            path_list.get_child(next_index).set_active()
        else:
            pause()
            %Menu.show_play()
            %CircleSelection.show_restart()
            paused = true
        
        return
    
    var marker_list = markers[active_path_index]
    var active_path = network_paths[active_path_index]
    var current_marker = marker_index - 6
    var current_marker_frame = int(marker_list.keys()[current_marker])
    if frame == current_marker_frame:
        if connected_to_server:
            if marker_index < active_path.size():
                websocket.send(active_path[marker_index])
            elif network_paths.size() > active_path_index + 1:
                var overreach_index = marker_index - active_path.size()
                var next_path = network_paths[active_path_index + 1]
                websocket.send(next_path[overreach_index])
        if current_marker < marker_list.size() - 1:
            marker_index += 1
    
    var depth: float = paths[active_path_index][frame]
    frame += 1

    %PathDisplay/Paths.get_child(active_path_index).position.x -= path_speed
    %PathDisplay/Ball.position.y = render_depth(depth)

func _process(_delta):
    xtoys_websocket.poll()
    var xtoys_state = xtoys_websocket.get_ready_state()

    if xtoys_state == WebSocketPeer.STATE_OPEN:
        if app_mode == Enums.AppMode.LOOP:
            if xtoys_websocket.get_available_packet_count() > 0:
                var packet: PackedByteArray = xtoys_websocket.get_packet()
                if xtoys_websocket.was_string_packet():
                    var message: String = packet.get_string_from_utf8()
                    var json: JSON = JSON.new()
                    json.parse(message)
                    var data = json.data
                    print(data)

                    if data.has("action") and data["action"] == "SetBPM":
                        if data.has("BPM"):
                            var bpm = data["BPM"].to_float()
                            %LoopControls.set_loop_bpm(bpm)
                    
                    # Process "SetDepth" action
                    if data.has("action") and data["action"] == "SetDepth":
                        if data.has("depth"):
                            var depth = data["depth"].to_float()
                            %RangePanel.update_max_range(depth)

    


    websocket.poll()
    var state = websocket.get_ready_state()
    if state == WebSocketPeer.STATE_OPEN:
        if not connected_to_server:
            UserSettings.cfg.set_value(
                'app_settings',
                'last_server_connection',
                %Settings/Network/Address/TextEdit.text)
            connected_to_server = true
            send_command(Enums.CommandType.CONNECTION)
            %Wifi.self_modulate = Color.WHITE
            %Wifi.show()
        while websocket.get_available_packet_count():
            var packet: PackedByteArray = websocket.get_packet()
            if packet[0] == Enums.CommandType.RESPONSE:
                match packet[1]:
                    
                    Enums.CommandType.CONNECTION:
                        connected_to_ossm = true
                        ossm_connection_timeout.emit_signal('timeout')
                        ossm_connection_timeout.stop()
                        %Wifi.self_modulate = Color.SEA_GREEN
                        %SpeedPanel.update_speed()
                        %SpeedPanel.update_acceleration()
                        %RangePanel.update_min_range()
                        %RangePanel.update_max_range()
                        %Settings.send_homing_speed()
                        %Menu.select_mode(%Menu/Main/Mode.selected)
                    
                    Enums.CommandType.HOMING:
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
                        emit_signal("homing_complete")
                        if %Menu/Main/Mode.selected == 0:
                            if active_path_index != null:
                                %CircleSelection.show_play()
                        elif %Menu/Main/Mode.selected == 1:
                            play()
    
    elif state == WebSocketPeer.STATE_CLOSING:
        pass # Keep polling to achieve proper close.
    elif state == WebSocketPeer.STATE_CLOSED:
        var code = websocket.get_close_code()
        var reason = websocket.get_close_reason()
        var text = "Webwebsocket closed with code: %d, reason %s. Clean: %s"
        print(text % [code, reason, code != -1])
        connected_to_server = false
        # set_process(false)
        %Wifi.hide()

func send_command(value: int):
    if connected_to_server:
        var command: PackedByteArray
        command.resize(1)
        command[0] = value
        websocket.send(command)


func home_to(target_position: int):
    if connected_to_ossm:
        %CircleSelection.show_hourglass()
        var displays = [
            %PositionControls,
            %LoopControls,
            %PathDisplay,
            %ActionPanel,
            %Menu]
        for display in displays:
            display.modulate.a = 0.05
        var command: PackedByteArray
        command.resize(5)
        command.encode_u8(0, Enums.CommandType.HOMING)
        command.encode_s32(1, target_position)
        websocket.send(command)


func play(_play_time_ms = null):
    var command: PackedByteArray
    if app_mode == Enums.AppMode.MOVE and active_path_index != null:
        paused = false
        #if play_time_ms != null:
            #command.resize(6)
            #command.encode_u8(0, CommandType.PLAY)
            #command.encode_u8(1, app_mode)
            #command.encode_u32(2, play_time_ms)
            #if connected_to_server:
                #websocket.send(command)
            #return
    command.resize(2)
    command.encode_u8(0, Enums.CommandType.PLAY)
    command.encode_u8(1, app_mode)
    if connected_to_server:
        websocket.send(command)


func pause():
    if connected_to_server:
        var command: PackedByteArray
        command.resize(1)
        command[0] = Enums.CommandType.PAUSE
        websocket.send(command)
    paused = true


func check_root_directory():
    var root_dir = DirAccess.open(Dirs.storage_dir)
    if not root_dir.dir_exists("OSSM Sauce"):
        root_dir.make_dir("OSSM Sauce")
    root_dir.change_dir("OSSM Sauce")
    for dir in ["Paths", "Playlists"]:
        if not root_dir.dir_exists(dir):
            root_dir.make_dir(dir)


func apply_user_settings():
    UserSettings.load()
    
    UserSettings.update_version()
    
    UserSettings.restore_window_size()
    
    UserSettings.start_server_connection()
    
    UserSettings.load_saved_settings()
    
    UserSettings.draw_easing()
    
    UserSettings.select_app_mode()
    

func load_path(file_name: String) -> bool:
    var file = FileAccess.open(Dirs.paths_dir + file_name, FileAccess.READ)
    if not file:
        return false
    var file_data = JSON.parse_string(file.get_line())
    if not file_data:
        return false
    var marker_data: Dictionary = file_data
    
    if marker_data.is_empty():
        return false
    
    var network_packets: Array
    for marker_frame in marker_data.keys():
        var ms_timing = round((float(marker_frame) / 60) * 1000)
        var depth = marker_data[marker_frame][0]
        var trans = marker_data[marker_frame][1]
        var easing = marker_data[marker_frame][2]
        var auxiliary = marker_data[marker_frame][3]
        
        var network_packet: PackedByteArray
        network_packet.resize(10)
        network_packet.encode_u8(0, Enums.CommandType.MOVE)
        network_packet.encode_u32(1, ms_timing)
        network_packet.encode_u16(5, round(remap(depth, 0, 1, 0, 10000)))
        network_packet.encode_u8(7, trans)
        network_packet.encode_u8(8, easing)
        network_packet.encode_u8(9, auxiliary)
        network_packets.append(network_packet)
        
        #adjusting for physics tick rate change from BounceX (60Hz to 50Hz)
        marker_data[round(int(marker_frame) / 1.2)] = marker_data[marker_frame]
        marker_data.erase(marker_frame)
    
    network_paths.append(network_packets)
    
    file.close()
    var previous_depth: float
    var previous_frame: int
    var marker_list: Array = marker_data.keys()
    var path: PackedFloat32Array
    var path_new: Dictionary
    var path_line: Line2D = Line2D.new()
    path_line.width = 15
    path_line.hide()
    marker_list.sort()
    for marker_frame in marker_list:
        var depth = marker_data[marker_frame][0]
        var trans = marker_data[marker_frame][1]
        var easing = marker_data[marker_frame][2]
        var _auxiliary = marker_data[marker_frame][3]
        if marker_frame > 0:
            var steps: int = marker_frame - previous_frame
            var duration = (float(steps) / ticks_per_second) * 1000
            var scaled_depth: int = round(clamp(depth, 0, 0.9999) * 10000)
            var headers: String = "M%sD%sT%sE%s"
            var message: String = headers % [scaled_depth, duration, trans, easing]
            path_new[previous_frame] = message
            for step in steps:
                var step_depth: float = Tween.interpolate_value(
                        previous_depth,
                        depth - previous_depth,
                        step,
                        steps,
                        trans,
                        easing)
                path.append(step_depth)
                var x_pos = (previous_frame * path_speed) + (step * path_speed)
                var y_pos = render_depth(step_depth)
                path_line.add_point(Vector2(x_pos, y_pos))
        previous_depth = depth
        previous_frame = marker_frame
    paths.append(path)
    markers.append(path_new)
    %PathDisplay/Paths.add_child(path_line)
    return true


func create_delay(duration: float):
    var delay_path: PackedFloat32Array
    var path_line: Line2D = Line2D.new()
    path_line.hide()
    var headers: String = "M%sD%sT%sE%s"
    var message: String = headers % [0, duration * 1000, 0, 2]
    for point in round(duration * ticks_per_second):
        delay_path.append(-1)
    paths.append(delay_path)
    markers.append({0: message})
    %PathDisplay/Paths.add_child(path_line)
    %Menu/Playlist.add_item("delay(%s)" % [duration])


func display_active_path_index(is_paused := true, send_buffer := true):
    paused = is_paused
    frame = 0
    marker_index = 0
    
    if send_buffer:
        if connected_to_server:
            send_command(Enums.CommandType.RESET)
            while marker_index < 6:
                websocket.send(network_paths[active_path_index][marker_index])
                marker_index += 1
    else:
        marker_index = 6
    
    %ActionPanel.clear_selections()
    if is_paused:
        %ActionPanel/Pause.hide()
        %ActionPanel/Play.show()
    for path in %PathDisplay/Paths.get_children():
        path.hide()
    var path = %PathDisplay/Paths.get_child(active_path_index)
    path.position.x = (%PathDisplay/PathArea.size.x / 2) + path_speed
    path.show()
    %PathDisplay/Ball.position.y = render_depth(paths[active_path_index][0])
    %PathDisplay/Ball.show()
    %PathDisplay.show()


func render_depth(depth) -> float:
    return PATH_BOTTOM + depth * (PATH_TOP - PATH_BOTTOM)


func _on_window_size_changed():
    if OS.get_name() != "Android":
        var window_size = DisplayServer.window_get_size()
        UserSettings.cfg.set_value('window', 'size', window_size)


func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        UserSettings.cfg.save(Dirs.cfg_path)
        if connected_to_server:
            const MIN_RANGE = 0
            var command: PackedByteArray
            command.resize(4)
            command.encode_u8(0, Enums.CommandType.SET_RANGE_LIMIT)
            command.encode_u8(1, MIN_RANGE)
            command.encode_u16(2, 0)
            websocket.send(command)
            home_to(0)