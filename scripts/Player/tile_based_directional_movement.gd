# Player.gd
class_name DirectionalCharacter
extends AnimatedSprite2D

var grid_pos: Vector2i = Vector2i(-10000,-10000)
var visual_pos: Vector2
var move_speed: float = 10.0
var is_moving: bool = false
var turns: int 
var player_facing: Facing = Facing.LEFT
var pushing: bool
var muddy: bool 
var invalid_push: bool 
var push_fail_tween: Tween = null
var push_strength: int 


enum Facing { UP, DOWN, LEFT, RIGHT }

@export var sprite: AnimatedSprite2D
@export var tracker: gameTracker
@export var times_up: bool 

@onready var backHoeSprite = $Sprite2D

var tilemap: TileMapLayer

func _ready():
	visual_pos = global_position
	tracker.connect("player_finished", _on_player_finished)
	tracker.connect("new_map_instance", _on_new_map)

func _on_player_finished():
	times_up = true 
	stop()

func _on_new_map(data: Dictionary):
	print("player got new map")
	print("map = %s", tracker.current_map.name)
	tilemap = tracker.current_map 
	global_position = data.player_pos as Vector2i  
	grid_pos = tilemap.local_to_map(global_position)
	visual_pos = tilemap.map_to_local(grid_pos)
	

func _process(delta):
	if !tilemap:
		print("no tilemap on process")
		return
		
	if push_fail_tween and push_fail_tween.is_running():
		global_position = visual_pos
		is_moving = true  # Set the flag
		return
		
	# Visual smoothly catches up to logical position
	var target = tilemap.map_to_local(grid_pos)
	if pushing:
		visual_pos = visual_pos.move_toward(target, 1* delta * 60)
		var strain = sin(Time.get_ticks_msec() * 0.03) * 2.0
		strain += randf_range(-1.5, 1.5)
		rotation_degrees = strain
	else:
		rotation_degrees = 0 
		visual_pos = visual_pos.move_toward(target, move_speed * delta * 60)
	global_position = visual_pos
	is_moving = visual_pos.distance_to(target) > 1.0
	if !is_moving and pushing:
		pushing = false 
	if !is_moving:
		#check if after turn resolution player got mudded on 
		#not a good way to have stable turn resolution 
		for debris in get_tree().get_nodes_in_group("debris"):
			if debris.grid_pos == grid_pos:
				print("player on same tile as debris after move completed ")
				debris = debris as Entity
				#kinda bad, not sure what I want to do the in this scenario with the game 
				#so its fine for making it not stall progress here 
				tracker.cleanedDebris += 1 
				debris.set_free_after_move()
				muddy =  true 
	update_animation(player_facing)
		

func trigger_push_fail(directionFlag: DirectionalCharacter.Facing):
	
	var direction = Vector2i.ZERO
	if directionFlag == Facing.LEFT:
		direction = Vector2i(-1,0)
	if directionFlag == Facing.RIGHT:
		direction = Vector2i(1,0)
	if directionFlag == Facing.DOWN:
		direction = Vector2i(0,1)
	if directionFlag == Facing.UP:
		direction = Vector2i(0,-1)
	var push_distance = 8.0
	var push_target = visual_pos + direction * push_distance
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)  # This gives the bounce-back effect
	tween.tween_property(self, "visual_pos", push_target, 0.15)
	tween.tween_property(self, "visual_pos", visual_pos, 0.15)
	
	# Optional wobble
	var rot_tween = create_tween()
	rot_tween.tween_property(self, "rotation_degrees", 5.0, 0.1)
	rot_tween.tween_property(self, "rotation_degrees", -5.0, 0.1)
	rot_tween.tween_property(self, "rotation_degrees", 0.0, 0.1)

func update_animation(state: Facing):
	var animation_name: String

	if state == Facing.UP:
		animation_name = "up"
	elif state == Facing.DOWN:
		animation_name = "down"
	elif state == Facing.LEFT:
		animation_name = "left"
	elif state == Facing.RIGHT:
		animation_name = "right"
	
	if muddy:
		animation_name += "_mud"
	
	self.animation = animation_name

func update_backhoe(state: Facing):
	if state == Facing.LEFT:
		if animation != "left":
			backHoeSprite.flip_h = true 
			var sprite_rect = backHoeSprite.get_rect()
			backHoeSprite.move_local_x(64+sprite_rect.size.x) 
	if state == Facing.RIGHT:
		if animation != "right":
			backHoeSprite.flip_h = false
			var sprite_rect = backHoeSprite.get_rect()
			backHoeSprite.move_local_x(-64-sprite_rect.size.x) 
func _unhandled_input(event):
	if !tilemap:
		print("no tilemap on input recieved")
		return 
	if times_up:
		return
	if is_moving:
		return  
	
	var now_facing : Facing
	var dir = Vector2i.ZERO

	if event.is_action_pressed("ui_up"):
		dir = Vector2i(0, -1)
		now_facing = Facing.UP
	elif event.is_action_pressed("ui_down"):
		dir = Vector2i(0, 1)
		now_facing = Facing.DOWN
	elif event.is_action_pressed("ui_left"):
		dir = Vector2i(-1, 0)
		now_facing = Facing.LEFT
	elif event.is_action_pressed("ui_right"):
		dir = Vector2i(1, 0)
		now_facing = Facing.RIGHT

	if dir != Vector2i.ZERO:
		if try_move(dir, now_facing, player_facing):
			turns +=1 
			player_facing = now_facing
		tracker.take_turn()
	
	if event.is_action_pressed("ui_accept"):
		$Sprite2D/AnimationPlayer.play("backHoe")		

func try_move(dir: Vector2i, now_facing:Facing, currently_facing:Facing) -> bool:
	var target = grid_pos + dir
	if resolve_movement(target, now_facing, currently_facing):
		grid_pos = target
	
		return true
	trigger_push_fail(now_facing)
	return false 

func resolve_movement(target: Vector2i, now_facing: Facing, currently_facing:Facing) -> bool:
	if (tilemap.get_cell_source_id(target) == -1 or 
	tilemap.get_cell_atlas_coords(target) == Vector2i(1,0) or 
	tilemap.get_cell_atlas_coords(target) == Vector2i(3,0) or
	tracker.current_fences_map.get_cell_source_id(target) != -1):
		print("player cant move becuase would place on invalid tile")
		return false 
	else:
		return resolve_entity_interaction_with_player(target, now_facing, currently_facing)

func resolve_entity_interaction_with_player(target: Vector2i, new_facing: Facing, currently_facing: Facing) -> bool:
	for debris in get_tree().get_nodes_in_group("debris"):
		# Check if target hits ANY tile of this entity
		debris = debris as Entity
		var hits_debris = false
		hits_debris = debris.occupies(target)
		if !hits_debris:
			continue
		if !can_push(new_facing, currently_facing):
			print("player cant move because no run up to push")
			return false
		if !debris.broken:
			pushing = true
			debris.bulldoze(currently_facing)
			return true
		if debris.broken:
			return debris.push(currently_facing)
	
	return true  # No debris at target



func can_push(new_facing: Facing, currently_facing:Facing) ->bool:
	return new_facing == currently_facing
