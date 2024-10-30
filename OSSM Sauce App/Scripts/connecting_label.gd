extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    if Settings.has_setting(Section.APP_SETTINGS, Key.LAST_SERVER_CONNECTION):
        show()