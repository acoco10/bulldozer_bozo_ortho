extends Node2D

@onready var gTrack: gameTracker = $gametracker
signal end_of_day(contract_completed: bool)

func _ready() -> void:
	gTrack.connect("player_finished", _on_day_finished)
	
func _on_day_finished():
	await get_tree().create_timer(2.0).timeout
	gTrack.leave_scene()
	$CanvasLayer.visible = false 
	if gTrack.current_contract_finished:
		end_of_day.emit({"contract_completed":true})
	else:
		end_of_day.emit()
	
func on_enter():
	$Player.times_up = false 
	$Player.play()
	$CanvasLayer.visible = true 
	gTrack.enter_scene()
	
