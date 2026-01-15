class_name timer 
extends Node2D
const DayStart = 8 * 60
var current_minutes: int =  DayStart # 8:00 AM in minutes

func advance_time() -> bool:
	current_minutes += 2
	if current_minutes >= 17 * 60:  # 5:00 PM
		current_minutes = 8 * 60
		return true  # Day ended
	return false

func reset():
	current_minutes = DayStart

func get_time_string() -> String:
	var hours = current_minutes / 60
	var mins = current_minutes % 60
	var period = "AM" if hours < 12 else "PM"
	var display_hour = hours % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, mins, period]
	
