extends Control

signal next_day

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		next_day.emit()


func update_results(debris_retrieved: int, debris_possible: int, minutes_remaining: int, lost:bool):
	
	var rank = ""
	if debris_possible == debris_retrieved and minutes_remaining > 2:
		rank = "S"
	elif debris_possible == debris_retrieved:
		rank = "A"
	elif float(debris_retrieved)/float(debris_possible) >= 0.8:
		rank = "B"
	else:
		rank = "C"
		
	
	$results_panel/MarginContainer/VBoxContainer/outcome.visible = true
	$results_panel/MarginContainer/VBoxContainer/time_remaining.visible = true
	$results_panel/MarginContainer/VBoxContainer/title.visible = true
	$results_panel/MarginContainer/VBoxContainer/rank.visible = true
	$results_panel/MarginContainer/VBoxContainer/outcome.text = "Harvested %d of %d material" %[debris_retrieved, debris_possible]
	
	var time_string = get_time_string(minutes_remaining)
	$results_panel/MarginContainer/VBoxContainer/time_remaining.text = "Time Remaining = %s" %time_string
	$results_panel/MarginContainer/VBoxContainer/rank.text = "Rank: %s" %rank
	$results_panel/MarginContainer/VBoxContainer/you_lost.visible = false
	$results_panel/Button.text = "> Continue"
	
	


	if lost:
		$results_panel/MarginContainer/VBoxContainer/rank.visible = false
		$results_panel/MarginContainer/VBoxContainer/outcome.visible = false 
		$results_panel/MarginContainer/VBoxContainer/time_remaining.visible = false 
		$results_panel/MarginContainer/VBoxContainer/title.visible = false 
		$results_panel/MarginContainer/VBoxContainer/you_lost.visible = true 
		$results_panel/Button.text = "> Retry"

func get_time_string(remaining_minutes) -> String:
	var hours = remaining_minutes / 60
	var mins = remaining_minutes % 60
	return "%d:%02d" % [hours, mins]
