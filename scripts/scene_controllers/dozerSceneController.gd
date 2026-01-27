extends Node2D

@onready var gTrack: gameTracker = $gametracker
@onready var camera: Camera2D = $Player/bulldozer_sprite/Camera2D
@onready var time_tracker: timer = $timer
@onready var time_ui: countdown_ui = $CanvasLayer/countdown_ui
signal end_of_day(debris_harvested: int, debris_available: int, time_remaining_minutes: int, lost: bool)
signal reset

func _ready() -> void:
	gTrack.connect("player_finished", _on_day_finished)
	
func _on_day_finished():
	
	time_ui.visible = false 
	print("dozer scene publishing end of day")
	await get_tree().create_timer(1.6).timeout
	gTrack.leave_scene()
	$CanvasLayer.visible = false 
	end_of_day.emit({"debris_harvested": gTrack.cleanedDebris, 
					"debris_available": gTrack.n_uncleared_debris, 
					"time_remaining_minutes": time_tracker.current_minutes,
					"lost": gTrack.lost})
	
func on_enter(retry: bool):
	if gTrack.map_index >= gTrack.maps.size():
		reset.emit()
		return
	$CanvasLayer.visible = true 
	gTrack.enter_scene(retry)
	
func first_enter():
	$CanvasLayer.visible = true 

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.key_label == KEY_R:
			gTrack.enter_scene(true)
