class_name Entity
extends Node2D

enum ShapeType { SINGLE, TREE_STANDING, TREE_FALLEN, L_SHAPE, T_SHAPE, PLATFORM}

# Grid & positions
var grid_pos: Vector2i
var visual_pos: Vector2
var visual_target: Vector2
var local_positions: Array[Vector2i] = [Vector2i.ZERO]
var visual_position_modifier: Vector2

var queued_animations: Array
# State flags

var is_moving: bool = false
var canned_animation: bool = false 

# Exports
@export var shape_type: ShapeType = ShapeType.SINGLE
@export var texture_path_name: String
@export var change_z_to_on_enter: int
@export var enter_with_elevator: bool 


var broken_up_texture: Texture
var unbroken_texture: Texture
var move_speed = 10
var free_after_move: bool 

func take_turn():
	pass

func initialize_shape(type: ShapeType) -> void:
	shape_type = type
	match type:
		ShapeType.SINGLE:
			local_positions = [Vector2i.ZERO]
		ShapeType.PLATFORM:
			local_positions = [Vector2i(0, -1), Vector2i(-1, -1),  Vector2i(-2, -1), Vector2i(1,-1),
								Vector2i.ZERO, Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(1, 0), 
								Vector2i(0, 1), Vector2i(-1, 1),  Vector2i(-2, 1), Vector2i(1,1)]

	
func enter_animation():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	var final_position = global_position
	global_position += Vector2(-0, -1000)
	tween.tween_property(self, "global_position", final_position, 1.5)
	canned_animation = true 
	await  tween.finished
	canned_animation = false 
	z_index = change_z_to_on_enter
	
func wobble_animation():
	queued_animations.append("wobble")
	
func apply_wobble():
	var rot_tween = create_tween()
	rot_tween.tween_property(self, "rotation_degrees", 5.0, 0.1)
	rot_tween.tween_property(self, "rotation_degrees", -5.0, 0.1)
	rot_tween.tween_property(self, "rotation_degrees", 0.0, 0.1)

func apply_queued_animation():
	for ani in queued_animations:
		match ani:
			"wobble":
				apply_wobble()

func _ready() -> void:
	add_to_group("entities")
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
		visual_pos = visual_pos.move_toward(visual_target, move_speed * delta * 60)
		global_position = visual_pos
		is_moving = visual_pos.distance_to(visual_target) > 1.0
	if !is_moving and free_after_move:
		queue_free()
	
