class_name Entity
extends Node2D

enum ShapeType { SINGLE, TREE_STANDING, TREE_FALLEN, L_SHAPE, T_SHAPE, PLATFORM}

# Grid & positions
var grid_pos: Vector2i
var visual_pos: Vector2
var local_positions: Array[Vector2i] = [Vector2i.ZERO]
var visual_position_modifier: Vector2
var rotation_state: int = 0

# State flags

var is_moving: bool = false
var canned_animation: bool = false 

var animated_effect: String
# Exports
@export var shape_type: ShapeType = ShapeType.SINGLE
@export var tilemap_fences_layer: TileMapLayer 
@export var tilemap: TileMapLayer
@export var texture_path_name: String
@export var change_z_on_enter: bool 


var debris_animator: DebrisAnimator = DebrisAnimator.new()
var broken_up_texture: Texture
var unbroken_texture: Texture
var move_speed = 10
var free_after_move: bool 
var last_turn_result: DebrisAction


func initialize_shape(type: ShapeType) -> void:
	shape_type = type
	match type:
		ShapeType.SINGLE:
			local_positions = [Vector2i.ZERO]
		ShapeType.PLATFORM:
			local_positions = [Vector2i(0, -1), Vector2i(-1, -1),  Vector2i(-2, -1), Vector2i(1,-1),
								Vector2i.ZERO, Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0), 
								Vector2i(0, 1), Vector2i(-1, 1),  Vector2i(-2, 1), Vector2i(1,1)]
	rotation_state = 0
	


func enter_animation():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	var final_position = global_position
	global_position += Vector2(-0, -1000)
	tween.tween_property(self, "global_position", final_position, 1.5)
	canned_animation = true 
	await  tween.finished
	canned_animation = false 
	if change_z_on_enter:
		z_index = 0
	

func _ready() -> void:
	add_to_group("entities")
	grid_pos = tilemap.local_to_map(position)
	visual_pos = tilemap.map_to_local(grid_pos)
	global_position = visual_pos
	initialize_shape(shape_type)

func get_world_positions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for local_pos in local_positions:
		result.append(grid_pos + local_pos)
	return result


func occupies(world_pos: Vector2i) -> bool:
	return world_pos in get_world_positions()

func _process(delta: float) -> void:
	if canned_animation:
		return
	if Vector2i(visual_pos) != grid_pos:
		var target = tilemap.map_to_local(grid_pos)
		visual_pos = visual_pos.move_toward(target + visual_position_modifier, move_speed * delta * 60)
		global_position = visual_pos
		is_moving = visual_pos.distance_to(target) > 1.0
	if !is_moving and free_after_move:
		queue_free()
	
# === SHAPE & POSITION SYSTEM ===


# === PUSH SYSTEM ===

func fence_at(pos: Vector2i) -> bool:
	if tilemap_fences_layer == null:
		return false  # No fences layer = no fences
	return tilemap_fences_layer.get_cell_source_id(pos) != -1




# === COLLISION HELPERS ===





# === ENTITY INTERACTIONS ===


func find_debris_at(pos: Vector2i) -> Entity:
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris.occupies(pos):
			return debris
	return null


func has_solid_debris_at(pos: Vector2i, ignore_chain: Array[Entity] = []) -> bool:
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris in ignore_chain or debris == self:
			continue
		if debris.occupies(pos):
			return !debris.pushable
	return false

func has_split_debris_at(pos: Vector2i) -> Entity:
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris == self:
			continue
		if debris.occupies(pos):
			if debris.broken:
				return debris
	return null

func sync_position_to_grid_pos():
	visual_pos = tilemap.map_to_local(grid_pos)
	global_position = visual_pos

func get_push_vector(push_direction: DirectionalCharacter.Facing) -> Vector2i:
	match push_direction:
		DirectionalCharacter.Facing.UP:
			return Vector2i(0, -1)
		DirectionalCharacter.Facing.DOWN:
			return Vector2i(0, 1)
		DirectionalCharacter.Facing.LEFT:
			return Vector2i(-1, 0)
		DirectionalCharacter.Facing.RIGHT:
			return Vector2i(1, 0)
	return Vector2i.ZERO


func update_vector_based_on_direction(input_vector: Vector2i, input_direction: DirectionalCharacter.Facing, push_strength: int = 1) -> Vector2i:
	return input_vector + get_push_vector(input_direction) * push_strength


func flash_and_free(entity: Node2D, flash_count: int = 3, flash_duration: float = 0.3) -> void:
	var tween = create_tween()
	
	for i in flash_count:
		tween.tween_property(entity, "modulate:a", 0.0, flash_duration)
		tween.tween_property(entity, "modulate:a", 1.0, flash_duration)
	
	await tween.finished
	entity.queue_free()
