class_name gameTracker
extends Node2D

var cleanedDebris: int
var debris_queue: Array = []
var n_uncleared_debris: int 
var debris_in_contract

var maps: Array 
@export var starting_map_index: int = 0
@export var n_tutorials: int = 7 
var current_map: TileMapLayer
var current_map_node: map
var current_fences_map: TileMapLayer
var current_ent_grid: EntityGrid

var best_turns: int = 0 
var turns: int = 2
var elevator_countdown: int = -1

var died: bool = false 
var ready_to_leave: bool = false
var trigger_retry_end_of_move: bool = false  

#player over all state 
var demerits: int = 0
var retry_tokens: int = 0 
var bs_in_a_row: int = 0 

@export var timeTracker: countdown_ui
@export var player: DirectionalCharacter
@export var objective_ui: Training_Objective
@onready var turn_timer: turn_based_timer = $timer


var training_mode: bool = false 
signal new_map_instance
signal player_finished
signal end_of_tutorial

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	var dir = DirAccess.open("res://maps/")
	if dir:
		for file_name in dir.get_files():
			print(file_name)
			if "map" in file_name.to_lower() and file_name.ends_with(".tscn"):
				var scene = load("res://maps/".path_join(file_name))
				if scene:
					maps.append(scene)		
					
	load_cur_map(true)

func load_cur_map(retry: bool):
	print("loading map: %d" %starting_map_index)
	n_uncleared_debris = 0 
	if current_map_node:
		current_map_node.queue_free()
	
	current_map_node = maps[starting_map_index].instantiate()
	get_parent().add_child(current_map_node)
	current_ent_grid = current_map_node.ent_grid
	current_map = current_map_node.get_node("tilemap").get_node("tiles")
	
	var reverse_only: bool = false	
	if "reverse_only" in current_map_node:
		reverse_only = current_map_node.reverse_only
	var data: Dictionary[String, Variant] = {"player_pos":current_map_node.Player_start_pos.global_position, 
											"facing":current_map_node.Player_start_pos.Direction, 
											"retry": retry,
											"tutorial": starting_map_index< n_tutorials,
											"reverse_only": reverse_only}
	new_map_instance.emit(data)
	current_fences_map = current_map_node.fences
	configure_map_entities()	
	current_map_node._enter_map_scene(retry)
	timeTracker.visible = true 
	objective_ui.visible = false
	turn_timer.set_countdown_length(current_map_node.timeLimitHours * 60 + current_map_node.timeLimitMinutes)
	update_text(turn_timer.get_time_string())
	if current_map_node.ent_grid.button != null: 
		current_map_node.ent_grid.button.connect("button_press", elevator_called)
	
	if starting_map_index < n_tutorials:
		training_mode = true
		timeTracker.visible = false
		objective_ui.visible = true
		current_map_node.objective_completed.connect(on_objective_completed)
		current_map_node.ent_grid.completion_flag.connect("button_press", next_objective)
		if starting_map_index == 3:
			$"../CanvasLayer/controls".set_control_text_reverse()
		if starting_map_index == 8:
			$"../CanvasLayer/controls".set_control_text_scoop()	
		if starting_map_index == 9:
			$"../CanvasLayer/controls".set_control_text_scoop_free_move()	
	
	elif training_mode:
		$"../CanvasLayer/controls".set_control_text_final()	
		end_of_tutorial.emit()
		training_mode = false 
		
	starting_map_index += 1 

func on_objective_completed():
	objective_ui.objective_completed()
	current_map_node.ent_grid.completion_flag.activate()

func next_objective():
	if starting_map_index < n_tutorials:
		load_cur_map(false)
		objective_ui.next_objective()
	else:
		load_cur_map(false)
	
func elevator_called():
	ready_to_leave = true 
	
func configure_map_entities():
	for debris in current_map_node.ent_grid.get_children():
		debris = debris as Debris
		if debris != null and debris.mineral:
			n_uncleared_debris +=2
	
func leave_scene():
	turns = 0 

func reset_demerits():
	demerits = 0 
		
func enter_scene(retry: bool):
	died = false 
	if retry:
		starting_map_index = max(0, starting_map_index-1)		
	n_uncleared_debris = 0 
	load_cur_map(retry)
	cleanedDebris = 0 

func _process(_delta: float) -> void:
	for ent_pos in current_ent_grid.entities:
		if current_ent_grid.has_entity_at(ent_pos):
			var ent = current_ent_grid.entities[ent_pos]
			if ent.is_moving:
				return 
	if ready_to_leave: 
		ready_to_leave = false 
		trigger_leave_scene()
	if trigger_retry_end_of_move:
		trigger_retry_end_of_move = false 
		await get_tree().create_timer(0.2).timeout
		load_cur_map(true)
	
func take_turn() -> void : 
	if training_mode:
		if player.broke_tutorial_rule:
			starting_map_index -=1 
			trigger_retry_end_of_move = true 	
			return 
	update_text(turn_timer.get_time_string())
	var player_reached_elevator = current_map_node.elevator_platform.occupies(player.grid_pos)
	if turn_timer.current_minutes == 5:
		current_map_node.fences.ten_turns_left()
	if current_ent_grid.lava_at(player.grid_pos) and !player_reached_elevator:
			player.sunk = true 
			died = true 
			queue_ready_to_leave()
		
	if turn_timer.current_minutes == 0:
		current_map_node.advance_lava(0.15)	
	turn_timer.advance_time()
	
func queue_ready_to_leave():
	ready_to_leave = true 

func trigger_leave_scene():
	for key in current_map_node.ent_grid.entities:
		var debris = current_map_node.ent_grid.entities[key] 
		if debris as Debris:
			if current_map_node.elevator_platform.occupies(debris.grid_pos) and debris.mineral:
				if debris.broken:
					cleanedDebris +=1
				else:
					cleanedDebris +=2
	if player.backhoe.is_carrying():
		cleanedDebris+=1 
	current_map_node.ent_grid.trigger_elevator_leave(current_map_node.elevator_platform, player)
	player_finished.emit()

			
func update_text(timestring: String) -> void:
	timeTracker.set_time_text(timestring, turn_timer.current_minutes)
	
func save_best_score(level_name: String, turns_this_run: int):
	var config = ConfigFile.new()
	var save_path = "user://level_scores.cfg"

	# Load existing data if file exists
	config.load(save_path)

	# Only save if it's better than existing score (or first time)
	var current_best = config.get_value(level_name, "best_turns", INF)
	if turns_this_run < current_best:
		config.set_value(level_name, "best_turns", turns)
		config.save(save_path)

# Load the best score
func load_best_score(level_name: String) -> int:
	var config = ConfigFile.new()
	var err = config.load("user://level_scores.cfg")

	if err != OK:
		return -1  # No save file yet

	return config.get_value(level_name, "best_turns", -1)
