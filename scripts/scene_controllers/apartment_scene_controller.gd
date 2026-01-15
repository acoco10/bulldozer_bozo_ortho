extends Node2D

signal next_day

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		next_day.emit()
		
