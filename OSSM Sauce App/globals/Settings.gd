extends Node

var app_version_number: String = '1.1.0'
var cfg: ConfigFile = ConfigFile.new()

var default_settings: Dictionary = {
    Section.APP_SETTINGS: {
        Key.VERSION_NUMBER: app_version_number,
        Key.SHOW_SPLASH: true,
        Key.MODE: 2,
        Key.SMOOTHING_SLIDER: 0.02,
        Key.LAST_SERVER_CONNECTION: '',
    },
    Section.WINDOW: {
        Key.SIZE: Vector2(540, 950),
        Key.ALWAYS_ON_TOP: false,
        Key.TRANSPARENT_BACKGROUND: false,
    },
    Section.SPEED_SLIDER: {
        Key.MAX_SPEED: 25000,
        Key.POSITION_PERCENT: 0.6,
    },
    Section.ACCEL_SLIDER: {
        Key.MAX_ACCELERATION: 500000,
        Key.POSITION_PERCENT: 0.4,
    },
    Section.RANGE_SLIDER_MIN: {
        Key.POSITION_PERCENT: 0.0,
    },
    Section.RANGE_SLIDER_MAX: {
        Key.POSITION_PERCENT: 1.0,
    },
    Section.DEVICE_SETTINGS: {
        Key.HOMING_SPEED: 1000,
    },
    Section.STROKE_SETTINGS: {
        Key.MAX_DURATION: 10,
        Key.MIN_DURATION: 0.2,
        Key.DISPLAY_MODE: 0,
        Key.IN_TRANS: 1,
        Key.IN_EASE: 2,
        Key.OUT_TRANS: 1,
        Key.OUT_EASE: 2,
    },
}

func _ready() -> void:
    load_settings()
    update_version()

func load_settings() -> void:
    var err = cfg.load(Dirs.cfg_path)
    if err != OK:
        initialize_default_settings()
    else:
        merge_defaults()

func save() -> void:
    cfg.save(Dirs.cfg_path)

func initialize_default_settings() -> void:
    for section in default_settings.keys():
        for key in default_settings[section].keys():
            set_setting(section, key, default_settings[section][key])
    save()

func merge_defaults() -> void:
    var updated = false
    for section in default_settings.keys():
        for key in default_settings[section].keys():
            if not cfg.has_section_key(section, key):
                set_setting(section, key, default_settings[section][key])
                updated = true
    if updated:
        save()

func get_setting(section: String, key: String, default_value: Variant = null) -> Variant:
    # print("Getting setting for section: ", section, ", key: ", key)
    if cfg.has_section_key(section, key):
        var value = cfg.get_value(section, key)
        # print("Found setting: ", value)
        return value
    else:
        var value = default_value
        if default_value == null:
            value = default_settings.get(section, {}).get(key, null)
        # print("Setting not found, using default value: ", value)
        cfg.set_value(section, key, value)
        save()
        return value

func set_setting(section: String, key: String, value: Variant) -> void:
    # print("Setting value for section: ", section, ", key: ", key, ", value: ", value)
    cfg.set_value(section, key, value)
    save()
    # print("Value set and saved for section: ", section, ", key: ", key)

func has_setting(section: String, key: String) -> bool:
    return cfg.has_section_key(section, key)

func update_version() -> void:
    var cfg_version_number = get_setting(Section.APP_SETTINGS, Key.VERSION_NUMBER)
    if cfg_version_number != app_version_number:
        initialize_default_settings()

func restore_window_settings() -> void:
    if OS.get_name() != 'Android':
        var size = get_setting(Section.WINDOW, Key.SIZE)
        DisplayServer.window_set_size(size)
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, get_setting(Section.WINDOW, Key.ALWAYS_ON_TOP))
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, get_setting(Section.WINDOW, Key.TRANSPARENT_BACKGROUND))

        var window_size = get_viewport().size
        var screen_size = DisplayServer.screen_get_size()
        var centered_position = Vector2(
            (screen_size.x - window_size.x) / 2,
            (screen_size.y - window_size.y) / 2)
        DisplayServer.window_set_position(centered_position)
        Main.node.get_viewport().size_changed.connect(_on_window_size_changed)

func _on_window_size_changed() -> void:
    if OS.get_name() != "Android":
        var window_size = DisplayServer.window_get_size()
        set_setting(Section.WINDOW, Key.SIZE, window_size)