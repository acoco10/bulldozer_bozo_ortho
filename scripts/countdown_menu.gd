class_name countdown_ui
extends Control 

var almost_up_tween: Tween
var default_color

func _ready():
	# Capture the default modulate color on startup
	default_color = $panel/MarginContainer/VBoxContainer/time.modulate
func set_time_text(input: String, minutes_left: int):
	$panel/MarginContainer/VBoxContainer/time.text = input
	if minutes_left < 10:
		flash_red()
	elif almost_up_tween != null and almost_up_tween.is_valid():
		almost_up_tween.kill()
		almost_up_tween = null  # Clear the reference
		# Reset color to white when stopping
		$panel/MarginContainer/VBoxContainer/time.modulate = default_color

func flash_red():
	# Kill any existing tween first
	if almost_up_tween != null and almost_up_tween.is_valid():
		almost_up_tween.kill()
	
	almost_up_tween = create_tween()
	almost_up_tween.tween_property($panel/MarginContainer/VBoxContainer/time, "modulate", Color.RED, 0.2)
	almost_up_tween.tween_property($panel/MarginContainer/VBoxContainer/time, "modulate", Color.WHITE, 0.2)
	almost_up_tween.set_loops()  # Infinite loops
