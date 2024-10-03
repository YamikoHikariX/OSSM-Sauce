extends Node


var cfg: ConfigFile = ConfigFile.new()
var app_version_number: String = '1.1.0'

func _ready() -> void:
    cfg.load(Dirs.cfg_path)
    update_version()


func update_version() -> void:
    var cfg_version_number = cfg.get_value(
            'app_settings',
            'version_number',
            "")
    if cfg_version_number != app_version_number:
        cfg.clear()
        cfg.set_value(
                'app_settings',
                'version_number',
                app_version_number)
        cfg.save(Dirs.cfg_path)


func restore_window_size() -> void:
    if OS.get_name() != 'Android':
        if cfg.has_section_key('window', 'size'):
            print(cfg.get_value('window', 'size'))
            DisplayServer.window_set_size(cfg.get_value('window', 'size'))

func get_setting(section: String, key: String):
    if cfg.has_section_key(section, key):
        return cfg.get_value(section, key)

# class Setting:
#     var section: String
#     var key: String
#     var default_value: Variant
#     var value: Variant

#     func _init(section: String, key: String, default_value: Variant):
#         self.section = section
#         self.key = key
#         self.default_value = default_value

# var default_settings: Dictionary = {
#     'app_settings': {
#         'version_number': app_version_number,
#         'show_splash': true,
#         'mode': 0,
#         'smoothing_slider': 0.5,
#         'last_server_connection': '',
#     },
#     'window': {
#         'size': Vector2(1080, 1920),
#         'always_on_top': false,
#         'transparent_background': false,
#     },
#     'speed_slider': {
#         'max_speed': 100,
#         'position_percent': 0.6,
#     },
#     'accel_slider': {
#         'max_acceleration': 100,
#         'position_percent': 0.4,
#     },
#     'range_slider_min': {
#         'position_percent': 0,
#     },
#     'range_slider_max': {
#         'position_percent': 1,
#     },
#     'device_settings': {
#         'homing_speed': 100,
#     },
#     'stroke_settings': {
#         'min_duration': 0,
#         'max_duration': 1000,
#         'display_mode': 0,
#     },
# }
