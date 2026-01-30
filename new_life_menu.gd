extends Control

@onready var continue_button = $results_panel/main_button
@onready var new_life_message = $results_panel/MarginContainer/VBoxContainer/message

var citizen_number_local = 0 

signal Continue

func _ready() -> void:
	continue_button.connect("pressed", func(): Continue.emit())

func update_message():
	new_life_message.text = "Greetings citizen %d. Harvest as many materials as you can." %citizen_number_local

func on_enter(updated_citizen_number: int) -> void:
	citizen_number_local = updated_citizen_number
	update_message()
	await get_tree().create_timer(0.2).timeout
	continue_button.grab_focus()
