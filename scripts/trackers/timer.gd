class_name turn_based_timer
extends Node2D

var countdown_length: int = 270  # Default countdown in minutes (4.5 hours = 270 mins)
var current_minutes: int = countdown_length

func set_countdown_length(minutes: int):
	countdown_length = minutes
	current_minutes = minutes

func advance_time() -> bool:
	current_minutes -= 1
	if current_minutes <= 0:
		current_minutes = 0
		return true  # Countdown finished
	return false

func reset():
	current_minutes = countdown_length

func get_time_string() -> String:
	@warning_ignore("integer_division")	
	var hours = current_minutes / 60
	var mins = current_minutes % 60
	return "%d:%02d" % [hours, mins]

func is_finished() -> bool:
	return current_minutes <= 0

func set_countdown_to_1():
	current_minutes = 1 
