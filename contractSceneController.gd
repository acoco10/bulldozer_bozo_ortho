extends Panel

signal contract_accepted 
var current_contract = 1 

func _unhandled_input(event: InputEvent) -> void:
	$MarginContainer/VBoxContainer/Title.text = "Training Gig %s" %current_contract
	if event.is_action_pressed("ui_accept"):
		contract_accepted.emit()
		current_contract+=1 
