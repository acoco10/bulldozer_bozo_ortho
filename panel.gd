extends Panel

signal contract_accepted 

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		visible = false 
		contract_accepted.emit()
