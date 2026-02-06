class_name Hub_Scene_Controller
extends Node2D

enum results_state {Retry_Token_Used, Continue, Continue_Death, Reset_Death}

@onready var dozerScene = $dozer
@onready var canvas_layer = $CanvasLayer
@onready var results = $CanvasLayer/results_panel
@onready var entrance = $entrance
@onready var new_life_menu = $CanvasLayer/new_life
@onready var clone_thoughts = $CanvasLayer/clone_thoughts_scene


#ENDING SCENES
@onready var death_loss = $CanvasLayer/deaths_loss_scene
@onready var mediocrity_loss = $CanvasLayer/mediocrity_loss_scene
@onready var all_puzzles_win = $CanvasLayer/winning_scene


var state_from_results: results_state
var need_new_contract: bool 
var day1: bool = true
var lost: bool = false 
var over: bool = false
var base_citizen_number = 9995
var too_mid_loss: bool = false 

var music_player: AudioStreamPlayer

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.key_label == KEY_R:
			state_from_results = results_state.Retry_Token_Used
			trigger_dozer_scene()
			
func _ready() -> void:
	#signals:
	dozerScene.connect("end_of_day", _on_end_of_day)
	entrance.connect("Leave", _on_enter)
	results.connect("Continue", _on_results_continue_control_flow)
	results.connect("Retry", _on_results_retry_control_flow)
	new_life_menu.connect("Continue", _on_new_life_continue)
	dozerScene.connect("end_of_tutorial", _on_end_of_tutorial)
	
	
	untrigger_new_life_scene()	
	untrigger_results_scene()
	untrigger_dozer_scene()

func _on_end_of_tutorial():
	if music_player == null:
			music_player = AudioStreamPlayer.new()
			add_child(music_player)
			music_player.stream = preload("res://sounds/saturn-3-music-claire-de-lune-debussy-piano-411227.mp3")
			music_player.play()
				
func _on_victory():
	trigger_ending_scene("win")
	
func _on_enter():
	entrance.queue_free()
	trigger_dozer_scene()

func _on_reset():
	get_tree().reload_current_scene()
	
func _on_end_of_day(data: Dictionary) -> void: 
	print("end of day recieved")
	
	lost = data.died
	if lost:
		state_from_results = results_state.Reset_Death
		trigger_dozer_scene()
		return
	too_mid_loss = data.too_mid
	over = data.win
	results.update_results(data, base_citizen_number)
	trigger_results_scene()
	untrigger_dozer_scene()
	
func _on_results_continue_control_flow():
	print("hub_scene recieved continue button event")
	untrigger_results_scene()
	if lost:
		base_citizen_number +=1
		if base_citizen_number >= 10000:
			trigger_ending_scene("bad")
		else:
			state_from_results = results_state.Continue_Death
			_on_new_life_results()
	elif over:
		_on_reset()	
	else:
		if too_mid_loss:
			trigger_ending_scene("mid") 
		else:
			state_from_results = results_state.Continue
			_on_next_day()

func _on_results_retry_control_flow():
	state_from_results = results_state.Retry_Token_Used
	print("hub_scene recieved retry button event")
	_on_next_day()

func _on_new_life_results():
	print("hub scene trigger new life after results menu")
	trigger_new_life_scene()
	
func _on_new_life_continue():
	print("hub scene recieved continue on new life event")
	untrigger_new_life_scene()
	_on_next_day()

func _on_next_day() -> void: 
	untrigger_results_scene()
	trigger_dozer_scene()


#dozer (main game scene)
func trigger_dozer_scene() -> void:
	if !day1:
		dozerScene.on_enter(state_from_results)
		lost = false
	dozerScene.first_enter()
	day1 = false 
	dozerScene.camera.enabled = true 
	dozerScene.visible = true
	dozerScene.process_mode = PROCESS_MODE_INHERIT
	
func untrigger_dozer_scene() -> void:
	dozerScene.camera.enabled = false 
	dozerScene.visible = false
	dozerScene.process_mode = PROCESS_MODE_DISABLED
	

#results
func trigger_results_scene() -> void:
	results.on_enter()
	results.process_mode = Node.PROCESS_MODE_INHERIT
	results.visible = true 

func untrigger_results_scene() -> void:
	results.process_mode = Node.PROCESS_MODE_DISABLED
	results.visible = false	
	
#new clone path
func trigger_new_life_scene() -> void:
	clone_thoughts.visible = true
	clone_thoughts.on_enter()
	await get_tree().create_timer(1.25).timeout
	clone_thoughts.visible = false 
	new_life_menu.on_enter(base_citizen_number)
	new_life_menu.process_mode = Node.PROCESS_MODE_INHERIT
	new_life_menu.visible = true
	
func untrigger_new_life_scene() -> void:
	new_life_menu.process_mode = Node.PROCESS_MODE_DISABLED
	new_life_menu.visible = false


#ending scenes 
func trigger_ending_scene(ending_type: String) ->void:
	var scene 
	match ending_type:
		"mid":
			scene = mediocrity_loss
		"bad":
			scene = death_loss
		"win":
			scene = all_puzzles_win
	
	scene.visible = true 
	scene.process_mode = Node.PROCESS_MODE_INHERIT
	scene.connect("Continue", _on_reset)
	scene.on_enter(base_citizen_number, ending_type)

	return 
