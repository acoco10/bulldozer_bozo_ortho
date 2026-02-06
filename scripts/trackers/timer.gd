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
	var coefficient: float
	var exponent: int
	
	# Determine scientific notation based on time remaining
	if current_minutes > 200:
		coefficient = 1.0
		exponent = -6
	elif current_minutes > 150:
		coefficient = 2.5
		exponent = -6
	elif current_minutes > 100:
		coefficient = 5.0
		exponent = -6
	elif current_minutes > 50:
		coefficient = 1.0
		exponent = -5
	elif current_minutes > 20:
		coefficient = 5.0
		exponent = -5
	elif current_minutes > 10:
		coefficient = 1.0
		exponent = -4
	else:  # < 10 minutes
		coefficient = 5.0
		exponent = -4
    
	return "Effusion Rate: %.1f×10⁻%d" % [coefficient, abs(exponent)]

func is_finished() -> bool:
	return current_minutes <= 0

func set_countdown_to_1():
	current_minutes = 1 
