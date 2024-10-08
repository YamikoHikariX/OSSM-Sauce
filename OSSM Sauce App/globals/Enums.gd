extends Node

enum CommandType {
	RESPONSE,
	MOVE,
	LOOP,
	POSITION,
	PLAY,
	PAUSE,
	RESET,
	HOMING,
	CONNECTION,
	SET_SPEED_LIMIT,
	SET_GLOBAL_ACCELERATION,
	SET_RANGE_LIMIT,
	SET_HOMING_SPEED,
}

enum AppMode {
	IDLE,
	HOMING,
	MOVE,
	POSITION,
	LOOP,
}

enum FileListMode {
	PATH,
	PLAYLIST,
}