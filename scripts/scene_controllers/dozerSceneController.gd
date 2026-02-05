extends Node2D

@onready var gTrack: gameTracker = $gametracker
@onready var camera: Camera2D = $Player/bulldozer_sprite/Camera2D
@onready var time_ui: countdown_ui = $CanvasLayer/countdown_ui

signal end_of_day(debris_harvested: int, debris_available: int, time_remaining_minutes: int, lost: bool)
signal end_of_tutorial 

const max_demerits = 2 

func _ready() -> void:
	gTrack.connect("player_finished", _on_day_finished)
	gTrack.connect("end_of_tutorial", end_of_tutorial.emit)
	
func _on_day_finished():
	time_ui.visible = false 
	print("dozer scene publishing end of day")
	await get_tree().create_timer(1.6).timeout
	gTrack.leave_scene()
	$CanvasLayer.visible = false 
	var days_rank = calc_rank()
	var demerit_loss: bool
	var too_mid: bool 
	var all_puzzles = gTrack.starting_map_index >= gTrack.maps.size() and !gTrack.died
	
	match days_rank:
		"C":
			gTrack.demerits +=1 
			if gTrack.demerits >= 2:
				demerit_loss = true 
				gTrack.reset_demerits()
			gTrack.bs_in_a_row = 0 
		"A":
			if gTrack.retry_tokens < 3:
				gTrack.retry_tokens +=1 
			gTrack.bs_in_a_row = 0 
		"B":
			gTrack.bs_in_a_row += 1
			if gTrack.bs_in_a_row == 3:
				too_mid = true 
		
	end_of_day.emit({"debris_harvested": gTrack.cleanedDebris, 
					"debris_available": gTrack.n_uncleared_debris, 
					"time_remaining_minutes": gTrack.turn_timer.current_minutes,
					"died": gTrack.died,
					"demerit_loss": demerit_loss,
					"demerits": gTrack.demerits,
					"rank": days_rank,
					"retry_tokens": gTrack.retry_tokens,
					"too_mid": too_mid,
					"win": all_puzzles})
	
func on_enter(results_state: Hub_Scene_Controller.results_state):
	match results_state:
		Hub_Scene_Controller.results_state.Retry_Token_Used:
			print("entering dozer scene after using retry token")
			gTrack.enter_scene(true)
			gTrack.retry_tokens = max(0, gTrack.retry_tokens-1)
		Hub_Scene_Controller.results_state.Continue_Death:
			print("entering dozer scene after death")
			gTrack.enter_scene(true)
		Hub_Scene_Controller.results_state.Continue:
			print("entering dozer scene normally")
			gTrack.enter_scene(false)
		Hub_Scene_Controller.results_state.Reset_Death:
			gTrack.enter_scene(true)
		
		
	
	$CanvasLayer.visible = true 
	
func first_enter():
	$CanvasLayer.visible = true 

func _unhandled_input(event: InputEvent) -> void:			
	if event is InputEventKey:
		if event.key_label == KEY_Z:
			gTrack.turn_timer.set_countdown_to_1()
			
func calc_rank() -> String:
	var calculated_rank = ""
	
	print("Rank calc: uncleared=", gTrack.n_uncleared_debris, " cleaned=", gTrack.cleanedDebris)
	
	# Edge case: no debris cleaned at all
	if gTrack.cleanedDebris == 0:
		print("  No debris cleaned (cleanedDebris=0)")
		calculated_rank = "C"
	# Cleared nothing
	elif gTrack.n_uncleared_debris == 0:
		print("No debris to clear (n_uncleared_debris=0)")
		calculated_rank = "C"
	# Perfect clear
	elif gTrack.n_uncleared_debris == gTrack.cleanedDebris:
		print("  Perfect clear (uncleared == cleaned)")
		calculated_rank = "A"
	else:
		var ratio =  float(gTrack.cleanedDebris)/ float(gTrack.n_uncleared_debris)
		print("  Ratio: ", ratio)
		if ratio >= 0.8:
			calculated_rank = "B"
		else:
			calculated_rank = "C"
	
	print("  → Rank: ", calculated_rank)
	return calculated_rank
