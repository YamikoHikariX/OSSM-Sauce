extends Node

var storage_dir: String
var paths_dir: String
var playlists_dir: String
var cfg_path: String


func _ready() -> void:
    if OS.get_name() == 'Android':
        storage_dir = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
    else:
        storage_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
    paths_dir = storage_dir + "/OSSM Sauce/Paths/"
    playlists_dir = storage_dir + "/OSSM Sauce/Playlists/"
    cfg_path = storage_dir + "/OSSM Sauce/UserSettings.cfg"