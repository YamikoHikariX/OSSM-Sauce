extends Control


func _ready():
    %Smoothing/HSlider.value_changed.connect(_on_smoothing_slider_value_changed)
    %PositionBar.position_changed.connect(_on_position_changed)
    %Menu.app_mode_changed.connect(_on_app_mode_changed)
    Main.gamepad_stick_input.connect(%PositionBar._on_stick_input)
    Main.gamepad_axis_input.connect(%PositionBar._on_axis_input)
    
    if UserSettings.cfg.has_section_key('app_settings', 'smoothing_slider'):
        %PositionControls/Smoothing/HSlider.set_value(UserSettings.cfg.get_value('app_settings', 'smoothing_slider'))

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

func _on_position_changed(new_position: float, istart: float, istop: float):
    set_ossm_position(int(new_position), istart, istop)

func set_ossm_position(new_position: int, istart: float, istop: float) -> void:
    var mapped_pos: int = int(remap(new_position, istart, istop, 0, 10000))
    if owner.connected_to_server:
        var command: PackedByteArray
        command.resize(5)
        command.encode_u8(0, Enums.CommandType.POSITION)
        command.encode_u32(1, mapped_pos)
        owner.websocket.send(command)
