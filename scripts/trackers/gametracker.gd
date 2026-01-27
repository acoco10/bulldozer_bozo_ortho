class_name gameTracker
extends Node2D

var cleanedDebris: int
var debris_queue: Array = []
var is_showing_label: bool = false
var n_uncleared_debris: int 
var current_contract: int = 1
var current_contract_finished: bool 
var Day: int = 1 
var debris_in_contract

var maps: Array 
var map_index: int = 1
var current_map: TileMapLayer
var current_map_node: map
var current_fences_map: TileMapLayer
var current_ent_grid: EntityGrid

var best_turns: int = 0 
var turns: int = 1 

var leave_button = Button_Tile
var elevator_countdown: int = -1

var lost: bool = false 

@export var timeTracker: countdown_ui
@export var ClearedDebris: Label
@export var timer: timer

@export var player: DirectionalCharacter

signal new_map_instance(player_start_pos:Vector2i)
signal player_finished

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
					
	load_cur_map()

func load_cur_map():
	print("loading map: %d", %map_index)
	n_uncleared_debris = 0 
	if current_map_node:
		current_map_node.queue_free()
	current_map_node = maps[map_index].instantiate()
	get_parent().add_child(current_map_node)
	current_ent_grid = current_map_node.ent_grid
	current_map = current_map_node.get_node("tilemap").get_node("tiles")
	map_index += 1 
	new_map_instance.emit({"player_pos":current_map_node.Player_start_pos.global_position, "facing":current_map_node.Player_start_pos.Direction})
	current_fences_map = current_map_node.fences
	
	configure_map_entities()
	
	current_map_node._enter_map_scene()
	best_turns = load_best_score(current_map_node.name)	
	timeTracker.visible = true 
	timer.set_countdown_length(current_map_node.timeLimitHours * 60 + current_map_node.timeLimitMinutes)
	update_text(timer.get_time_string())
	
func configure_map_entities():
	for debris in current_map_node.ent_grid.get_children():
		debris = debris as Debris
		if debris != null and debris.mineral:
			n_uncleared_debris +=2

		
func _on_leave_button():
	"trigger elevator count down"
	elevator_countdown = 3 
	
func leave_scene():
	turns = 0 
	
func enter_scene(retry: bool):
	current_contract_finished = false 
	if retry:
		lost = false 
		map_index-=1 
	else:
		Day += 1 
		current_contract +=1 
		
	n_uncleared_debris = 0 
	load_cur_map()
	cleanedDebris = 0 


func check_if_all_mineral_on_platform() -> bool:
	for key in current_map_node.ent_grid.entities:
		var debris = current_map_node.ent_grid.entities[key] 
		if debris as Debris:
			if !current_map_node.elevator_platform.occupies(debris.grid_pos) and debris.mineral:
				return false
	return true
	
func take_turn() -> bool: 
	turns += 1 
	update_text(timer.get_time_string())
	var player_reached_elevator = current_map_node.elevator_platform.occupies(player.grid_pos)
	if check_if_all_mineral_on_platform() and player_reached_elevator:		
			trigger_leave_scene()
			return false
	if timer.current_minutes == 0:
		if current_map_node.elevator_platform.occupies(player.grid_pos):
			trigger_leave_scene()
			return false
		current_map_node.advance_lava(0.15)
		if current_ent_grid.lava_at(player.grid_pos) and !player_reached_elevator:
			player.sink()
			lost = true 
			trigger_leave_scene()
			return false 
	timer.advance_time()
	
	return false 

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
	current_map_node.elevator_platform.trigger_leave()
	player_finished.emit()

			
func update_text(timestring: String) -> void:
	timeTracker.set_time_text(timestring, timer.current_minutes)
	
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
