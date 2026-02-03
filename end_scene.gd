extends Node2D

signal Continue
@onready var text_label = $Panel/Label

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		Continue.emit()


func on_enter(citizen_number: int, result: String):
	match result:
		"win":
			text_label.text = "Great job Team!\nWe're gonna make so much money 
			from cloning  the citizen %d line." %citizen_number
