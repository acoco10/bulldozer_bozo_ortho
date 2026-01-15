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
var map_index: int = 0
var current_map: TileMapLayer
var current_map_node: map
var current_fences_map: TileMapLayer


@export var timeTracker: timer
@export var TrackerLabel: Label
@export var ClearedDebris: Label
@export var ContractCompleted: Label
@export var QuittingTime: Label

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
	if current_map_node:
		current_map_node.queue_free()
	current_map_node = maps[map_index].instantiate()
	get_parent().add_child(current_map_node)
	current_map = current_map_node.get_node("tilemap").get_node("tiles")
	map_index += 1 
	new_map_instance.emit({"player_pos":current_map_node.Player_start_pos.global_position})
	current_fences_map = current_map_node.fences
	for debris in get_tree().get_nodes_in_group("debris"):
		debris = debris as Entity
		if current_map_node.fences:
			debris.tilemap_fences_layer = current_fences_map
		debris.tilemap = current_map
		debris.connect("DebrisBrokenUp", _on_debris_broken_up)
		if debris.split:
			n_uncleared_debris +=2
		else:
			n_uncleared_debris +=1


func leave_scene():
	ContractCompleted.visible = false 
	QuittingTime.visible = false 
	
func enter_scene():
	if current_contract_finished:
		n_uncleared_debris = 0 
		load_cur_map()
		current_contract +=1 
		current_contract_finished = false 
		cleanedDebris = 0 
	Day += 1 
	timeTracker.reset()

func _on_debris_cleaned():
	cleanedDebris+=1 
	debris_queue.append(true)
	_process_debris_queue()
	
		
func take_turn() -> bool: 
	update_text(Day, current_contract, cleanedDebris, timeTracker.get_time_string())
	if timeTracker.advance_time():
		QuittingTime.visible = true
		player_finished.emit()
		return true 
	return false 

func _process_debris_queue():
	if debris_queue.is_empty():
		if cleanedDebris == n_uncleared_debris and !current_contract_finished: 
			QuittingTime.text = "Looks like you finished the contract, call it a day and get out of here"
			QuittingTime.visible = true
			current_contract_finished = true 
			player_finished.emit()
		return
	if is_showing_label:
		return
	
	is_showing_label = true
	debris_queue.pop_front()
	
	var start_pos = ClearedDebris.position
	ClearedDebris.visible = true
	ClearedDebris.modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ClearedDebris, "position:y", ClearedDebris.position.y - 100, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(ClearedDebris, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	await tween.finished
	
	ClearedDebris.visible = false
	ClearedDebris.position = start_pos
	ClearedDebris.modulate.a = 1.0
	
	is_showing_label = false
	_process_debris_queue()


func _on_debris_broken_up():
	for debris in get_tree().get_nodes_in_group("debris"):
		if not debris.is_connected("DebrisCleaned", _on_debris_cleaned):
				debris.connect("DebrisCleaned", _on_debris_cleaned)
				
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.key_label == KEY_R:
			get_tree().reload_current_scene()
			
func update_text(current_day: int, current_contract: int, n_debris_cleaned: int, timestring: String) -> void:
	TrackerLabel.text = "Day %d\nTraining Gig:%d\nDebris Cleaned: %d/%d\n %s" %[current_day, current_contract, n_debris_cleaned, n_uncleared_debris, timestring]
