extends Control

var active:bool

enum Trans {
    LINEAR,
    SINE,
    CIRC,
    EXPO,
    QUAD,
    CUBIC,
    QUART,
    QUINT
}

var tween_map:Dictionary = {
    Trans.LINEAR : 0,
    Trans.SINE : 1,
    Trans.CIRC : 8,
    Trans.EXPO : 5,
    Trans.QUAD : 4,
    Trans.CUBIC : 7,
    Trans.QUART : 3,
    Trans.QUINT : 2
}

var slider_resist:float = 0.8

var A:Vector2
var B:Vector2
var C:Vector2


func _ready():
    A.x = $Control.position.x
    A.y = $Control.position.y + $Control.size.y
    B.x = $Control.position.x + $Control.size.x / 2
    B.y = $Control.position.y
    C.x = $Control.position.x + $Control.size.x
    C.y = $Control.position.y + $Control.size.y
    _on_link_speed_sliders_toggled(true)

    $BPMSend.pressed.connect(set_loop_bpm)

    if UserSettings.cfg.has_section_key('stroke_settings', 'in_trans'):
        %LoopControls/In/AccelerationControls/Transition.select(UserSettings.cfg.get_value('stroke_settings', 'in_trans'))
    
    if UserSettings.cfg.has_section_key('stroke_settings', 'in_ease'):
        %LoopControls/In/AccelerationControls/Easing.select(UserSettings.cfg.get_value('stroke_settings', 'in_ease'))
    
    if UserSettings.cfg.has_section_key('stroke_settings', 'out_trans'):
        %LoopControls/Out/AccelerationControls/Transition.select(UserSettings.cfg.get_value('stroke_settings', 'out_trans'))
    
    if UserSettings.cfg.has_section_key('stroke_settings', 'out_ease'):
        %LoopControls/Out/AccelerationControls/Easing.select(UserSettings.cfg.get_value('stroke_settings', 'out_ease'))

    draw_easing()


func rmt(input:int):
    return tween_map[input]


func draw_easing():
    $Line2D.clear_points()
    var x_pos = A.x
    
    for i in 383:
        var w = Tween.interpolate_value(
            A.y,
            (B.y - A.y),
            float(i) / 383,
            1,
            rmt($In/AccelerationControls/Transition.selected),
            $In/AccelerationControls/Easing.selected)
        $Line2D.add_point(Vector2(x_pos, w - 25))
        x_pos += 1
    
    for i in 383:
        var w = Tween.interpolate_value(
            B.y,
            -(B.y - C.y),
            float(i) / 383,
            1,
            rmt($Out/AccelerationControls/Transition.selected),
            $Out/AccelerationControls/Easing.selected)
        $Line2D.add_point(Vector2(x_pos, w - 25))
        x_pos += 1

func set_loop_bpm(bpm: float):
    if %ActionPanel.get_node("Play").is_visible(): return
    if bpm <= 0:
        owner.pause()
        active = false
        return
    # var bpm: float = $BPMText.text.to_float()
    # print("BPM: ", bpm)
    $BPMText.text = str(bpm)
    draw_easing()
    var in_duration:float = 60.0 / bpm / 2.0
    var in_trans:int = $In/AccelerationControls/Transition.selected
    var in_ease:int = $In/AccelerationControls/Easing.selected
    var in_auxiliary:int
    var out_duration:float = 60.0 / bpm / 2.0
    var out_trans:int = $Out/AccelerationControls/Transition.selected
    var out_ease:int = $Out/AccelerationControls/Easing.selected
    var out_auxiliary:int
    UserSettings.cfg.set_value('stroke_settings', 'in_trans', in_trans)
    UserSettings.cfg.set_value('stroke_settings', 'in_ease', in_ease)
    UserSettings.cfg.set_value('stroke_settings', 'out_trans', out_trans)
    UserSettings.cfg.set_value('stroke_settings', 'out_ease', out_ease)
    
    print("In Duration: ", in_duration)
    print("Out Duration: ", out_duration)

    var loop_command:PackedByteArray
    loop_command.resize(19)
    
    loop_command.encode_u8(0, Enums.CommandType.LOOP)
    loop_command.encode_u32(1, in_duration * 1000)
    loop_command.encode_u16(5, 10000)
    loop_command.encode_u8(7, in_trans)
    loop_command.encode_u8(8, in_ease)
    loop_command.encode_u8(9, in_auxiliary)
    loop_command.encode_u32(10, out_duration * 1000)
    loop_command.encode_u16(14, 0)
    loop_command.encode_u8(16, out_trans)
    loop_command.encode_u8(17, out_ease)
    loop_command.encode_u8(18, out_auxiliary)
    if owner.connected_to_server:
        owner.websocket.send(loop_command)
        if in_duration + out_duration == 0:
            owner.pause()
            active = false
        elif not active:
            owner.play()
            active = true

func send_command():
    draw_easing()
    var in_duration:float = $In.stroke_duration
    var in_trans:int = $In/AccelerationControls/Transition.selected
    var in_ease:int = $In/AccelerationControls/Easing.selected
    var in_auxiliary:int
    var out_duration:float = $Out.stroke_duration
    var out_trans:int = $Out/AccelerationControls/Transition.selected
    var out_ease:int = $Out/AccelerationControls/Easing.selected
    var out_auxiliary:int
    UserSettings.cfg.set_value('stroke_settings', 'in_trans', in_trans)
    UserSettings.cfg.set_value('stroke_settings', 'in_ease', in_ease)
    UserSettings.cfg.set_value('stroke_settings', 'out_trans', out_trans)
    UserSettings.cfg.set_value('stroke_settings', 'out_ease', out_ease)
    
    var loop_command:PackedByteArray
    loop_command.resize(19)
    
    loop_command.encode_u8(0, Enums.CommandType.LOOP)
    loop_command.encode_u32(1, in_duration * 1000)
    loop_command.encode_u16(5, 10000)
    loop_command.encode_u8(7, in_trans)
    loop_command.encode_u8(8, in_ease)
    loop_command.encode_u8(9, in_auxiliary)
    loop_command.encode_u32(10, out_duration * 1000)
    loop_command.encode_u16(14, 0)
    loop_command.encode_u8(16, out_trans)
    loop_command.encode_u8(17, out_ease)
    loop_command.encode_u8(18, out_auxiliary)
    if owner.connected_to_server:
        owner.websocket.send(loop_command)
        if in_duration + out_duration == 0:
            owner.pause()
            active = false
        elif not active:
            owner.play()
            active = true


func _on_ttc_toggled(toggled_on):
    if toggled_on:
        $Controls/ttc.self_modulate = Color.SEA_GREEN
        $Controls/ttc.text = "Tap to Cycle: ON"
    else:
        $Controls/ttc.self_modulate = Color.WHITE
        $Controls/ttc.text = "Tap to Cycle: OFF"


var prev_ms:int
func _on_tap_pressed():
    if not $Controls/ttc.button_pressed:
        return
    var duration = $SpinBox.value * 1000
    var tap_time = Time.get_ticks_msec() - prev_ms
    if prev_ms and tap_time < duration:
        duration = tap_time
    prev_ms = Time.get_ticks_msec()
    if owner.connected_to_server and $ActiveSwitch.button_pressed:
        owner.websocket.send_text(
            'L' + str((duration) * 0.5) + 
            "T" + str($Controls/Transitions/In.selected) + 
            "E" + str($Controls/Easings/In.selected) + 
            "T" + str($Controls/Transitions/Out.selected) + 
            "E" + str($Controls/Easings/Out.selected) +
            "C")


func reset_stroke_duration_sliders():
    $In.reset_stroke_duration_slider()
    $Out.reset_stroke_duration_slider()


func update_stroke_duration_text():
    $In.update_stroke_duration_text()
    $Out.update_stroke_duration_text()


func _on_link_speed_sliders_toggled(toggled_on):
    if toggled_on:
        $LinkSpeedSliders/Label.set_modulate('00b97d')
    else:
        $LinkSpeedSliders/Label.set_modulate(Color.WHITE)
