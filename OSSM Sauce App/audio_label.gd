extends Label

func _ready() -> void:
	pass # Replace with function body.


# func _physics_process(delta: float) -> void:
# 	#  + AudioServer.get_time_since_last_mix()
# 	var audio_seconds:float = %AudioStreamPlayer.get_playback_position() + AudioServer.get_time_since_last_mix()

# 	var ms = fmod(audio_seconds, 1)
# 	# Display seconds with 3 decimal places
# 	var audio_text = str(int(audio_seconds)) + ":" + str(int(ms * 1000))

# 	var frame_ms = fmod(owner.frame, 50)
# 	var frame_text = str(int(owner.frame / 50)) + ":" + str(int(frame_ms))

# 	text = "Audio: " + audio_text + "\nFrame: " + frame_text
