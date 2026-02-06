class_name countdown_ui
extends Control 

var almost_up_tween: Tween
var default_color
@onready var siesmic_line: Line2D = $Line2D

func _ready():
	# Capture the default modulate color on startup
	default_color = $panel/MarginContainer/VBoxContainer/time.modulate

func set_time_text(input: String, minutes_left: int):
	$panel/MarginContainer/VBoxContainer/time.text = input
	
	# Calculate intensity based on time remaining (0.0 to 1.0)
	# More urgent as time gets lower
	var max_minutes = 60.0  # Adjust this to your game's max time
	var intensity = 1.0 - clamp(minutes_left / max_minutes, 0.0, 1.0)
	
	# Extra boost when under 10 minutes
	if minutes_left < 10:
		intensity = max(intensity, 0.7 + (10 - minutes_left) / 10.0 * 0.3)
		flash_red()
	elif almost_up_tween != null and almost_up_tween.is_valid():
		almost_up_tween.kill()
		almost_up_tween = null
		$panel/MarginContainer/VBoxContainer/time.modulate = default_color
	
	# Update seismic line intensity
	siesmic_line.set_intensity(intensity)

func flash_red():
	# Kill any existing tween first
	if almost_up_tween != null and almost_up_tween.is_valid():
		almost_up_tween.kill()
	
	almost_up_tween = create_tween()
	almost_up_tween.tween_property($panel/MarginContainer/VBoxContainer/time, "modulate", Color.RED, 0.2)
	almost_up_tween.tween_property($panel/MarginContainer/VBoxContainer/time, "modulate", Color.WHITE, 0.2)
	almost_up_tween.set_loops()  # Infinite loops