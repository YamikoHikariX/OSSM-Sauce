extends Control


func _ready():
    %SmoothingSlider/HSlider.value_changed.connect(_on_smoothing_slider_value_changed)
    %PositionBar.value_changed.connect(_on_position_changed)
    %PositionBar.set_output_range(0, 10000)
    %Menu.app_mode_changed.connect(_on_app_mode_changed)
    Main.node.gamepad_stick_input.connect(%PositionBar._on_stick_input)
    Main.node.gamepad_axis_input.connect(%PositionBar._on_axis_input)
    
    if UserSettings.cfg.has_section_key('app_settings', 'smoothing_slider'):
        %SmoothingSlider/HSlider.set_value(UserSettings.cfg.get_value('app_settings', 'smoothing_slider'))

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("D-pad Up"):
        %SpeedSlider/HSlider.value += %SpeedSlider/HSlider.step
    elif event.is_action_pressed("D-pad Down"):
        %SpeedSlider/HSlider.value -= %SpeedSlider/HSlider.step

func _on_app_mode_changed(new_mode: Enums.AppMode):
    $PositionBar.reset()

    if new_mode == Enums.AppMode.POSITION:
        enable()
        show()
    else:
        disable()
        hide()

func enable():
    set_physics_process(true)
    set_process_input(true)

func disable():
    set_physics_process(false)
    set_process_input(false)

func _on_smoothing_slider_value_changed(value: float):
    UserSettings.cfg.set_value('app_settings', 'smoothing_slider', value)

func _on_position_changed(new_position: float):
    set_ossm_position(int(new_position))

func set_ossm_position(new_position: int) -> void:
    if Main.node.connected_to_server:
        var command: PackedByteArray
        command.resize(5)
        command.encode_u8(0, Enums.CommandType.POSITION)
        command.encode_u32(1, new_position)
        print("Sending position command: ", new_position)
        Main.node.ossm_websocket.send(command)
