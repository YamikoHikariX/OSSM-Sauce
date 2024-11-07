extends Panel

@onready var address_input = $Network/Address/TextEdit

func _ready():
    var checkbox = $Window/TransparentBg/CheckBox
    checkbox.button_pressed = Settings.get_setting(Section.WINDOW, Key.TRANSPARENT_BACKGROUND)

    var always_on_top = $Window/AlwaysOnTop/CheckBox
    always_on_top.button_pressed = Settings.get_setting(Section.WINDOW, Key.ALWAYS_ON_TOP)

    $Network/Address/TextEdit.text = Settings.get_setting(Section.APP_SETTINGS, Key.LAST_SERVER_CONNECTION)
    _on_connect_pressed()
    $Network/ConnectionTimeout.start()

    await $Network/ConnectionTimeout.timeout
    %ActionPanel.show()
    %ConnectingLabel.hide()

    set_max_speed(Settings.get_setting(Section.SPEED_SLIDER, Key.MAX_SPEED))

    set_max_acceleration(Settings.get_setting(Section.ACCEL_SLIDER, Key.MAX_ACCELERATION))

    $HomingSpeed/SpinBox.value = Settings.get_setting(Section.DEVICE_SETTINGS, Key.HOMING_SPEED)
    send_homing_speed()

    if OS.get_name() == "Android":
        $Window.hide()
    var numeric_inputs: Array = [
        $Network/Port/TextEdit,
        $Sliders/MaxSpeed/TextEdit,
        $Sliders/MaxAcceleration/TextEdit]
    for node in numeric_inputs:
        node.text_changed.connect(_on_numeric_input_changed.bind(node))


func _on_connect_pressed():
    var server_address: String = address_input.text
    var address: String
    var port: String = "120"
    if ':' in server_address:
        var sections = server_address.split(':')
        address = sections[0]
        port = sections[1]
        if port == "120":
            $Network/Address/TextEdit.text = address
    else:
        address = server_address
    Main.node.ossm_websocket.connect_to_url("ws://" + address + ":" + port)
    print("Setting up connection to " + address + ":" + port)
    
    Main.node.set_process(true)


func _on_get_range_pressed():
    Main.node.ossm_websocket.send_text('G')


func _on_network_address_text_changed():
    if "\n" in address_input.text:
        address_input.text = address_input.text.replace("\n", "")
        _on_connect_pressed()


func _on_numeric_input_changed(input_node: Node):
    var regex = RegEx.new()
    regex.compile("[^0-9]")
    var filtered_text = regex.sub(input_node.text, "", true)
    if input_node.text != filtered_text:
        input_node.text = filtered_text
        input_node.set_caret_column(input_node.text.length())


func _on_Back_pressed():
    var speed_value = int($Sliders/MaxSpeed/TextEdit.text)
    speed_value = clamp(speed_value, 100, 200000)
    $Sliders/MaxSpeed/TextEdit.text = str(speed_value)
    var accel_value = int($Sliders/MaxAcceleration/TextEdit.text)
    accel_value = clamp(accel_value, 5000, 9000000)
    $Sliders/MaxAcceleration/TextEdit.text = str(accel_value)
    %Menu.show()
    hide()


func set_max_speed(value):
    $Sliders/MaxSpeed/TextEdit.text = str(value)
    _on_speed_input_changed()


func set_max_acceleration(value):
    $Sliders/MaxAcceleration/TextEdit.text = str(value)
    _on_acceleration_input_changed()

func _on_speed_input_changed():
    var value = int($Sliders/MaxSpeed/TextEdit.text)
    value = clamp(value, 100, 200000)
    Settings.set_setting(Section.SPEED_SLIDER, Key.MAX_SPEED, value)
    Main.node.max_speed = value

func _on_acceleration_input_changed():
    var value = int($Sliders/MaxAcceleration/TextEdit.text)
    value = clamp(value, 5000, 9000000)
    Main.node.max_acceleration = value
    Settings.set_setting(Section.ACCEL_SLIDER, Key.MAX_ACCELERATION, value)

func send_homing_speed():
    if Main.node.connected_to_server:
        var command: PackedByteArray
        command.resize(5)
        command.encode_u32(0, Enums.CommandType.SET_HOMING_SPEED)
        command.encode_u32(1, $HomingSpeed/SpinBox.value)
        Main.node.ossm_websocket.send(command)

func _on_homing_speed_changed(value):
    send_homing_speed()
    Settings.set_setting(Section.DEVICE_SETTINGS, Key.HOMING_SPEED, value)

func _on_always_on_top_toggled(toggled):
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, toggled)
    print("Setting always on top to: ", toggled)
    Settings.set_setting(Section.WINDOW, Key.ALWAYS_ON_TOP, toggled)

func _on_transparent_background_toggled(toggled):
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, toggled)
    Settings.set_setting(Section.WINDOW, Key.TRANSPARENT_BACKGROUND, toggled)