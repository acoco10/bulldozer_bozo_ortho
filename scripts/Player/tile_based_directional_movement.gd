# Player.gd
class_name DirectionalCharacter
extends Entity

var turns: int 
var player_facing: Facing = Facing.RIGHT
var visual_facing: Facing = Facing.RIGHT
var pushing: bool
var muddy: bool 
var invalid_push: bool 
var push_fail_tween: Tween = null
var push_strength: int 
var reverse: bool 
var scooped_debris: bool 
var last_animation
var push_power_up
var is_sinking: bool
var sunk: bool 

var sprites: Array
enum Facing { UP, DOWN, LEFT, RIGHT }

@export var tracker: gameTracker
@export var times_up: bool 
@onready var backhoe = $backhoeSprites
@onready var state_label = $state
@export var ent_grid: EntityGrid

var sink_tween: Tween = Tween.new()
func _ready():
	add_to_group("player")
	tracker.connect("player_finished", _on_player_finished)
	tracker.connect("new_map_instance", _on_new_map)
	
func sink():
	sink_tween = create_tween()

	backhoe.start_sinking()
	$bulldozer_sprite.start_sinking()
	sink_tween.tween_property(self, "global_position:y", global_position.y + 40,2.0)
	canned_animation = true 

		
func _on_player_finished():
	times_up = true 
	$bulldozer_sprite.stop()

func _on_new_map(data: Dictionary):
	backhoe.reset()
	$bulldozer_sprite.reset()
	
	if sink_tween.is_valid():
		sink_tween.kill()
	print("player got new map")
	print("map = %s", tracker.current_map.name)
	ent_grid = tracker.current_ent_grid
	global_position = data.player_pos as Vector2i  
	grid_pos = ent_grid.land.local_to_map(global_position)
	ent_grid.sync_position_to_grid_pos(self)
	visual_pos = ent_grid.land.map_to_local(grid_pos)
	var start_face = data.facing
	
	
	player_facing = start_face
	visual_facing = start_face
	
	update_animation(player_facing)
	on_enter()	

func _process(delta):
	if canned_animation:
		return 
	if !ent_grid:
		print("no tilemap on process")
		return
	if push_fail_tween and push_fail_tween.is_running():
		global_position = visual_pos
		is_moving = true  # Set the flag
		return

	# Visual smoothly catches up to logical position
	var target = ent_grid.land.map_to_local(grid_pos)
	if pushing:
		visual_pos = visual_pos.move_toward(target, 5* delta * 60)
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
	if !is_moving and sunk:
		call_deferred("sink")  # W
	

	
	

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
	if has_node("backhoeSprites"):
		$backhoeSprites.update_backhoe(grid_pos, visual_facing, player_facing)
	
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
	$bulldozer_sprite.animation = animation_name

func _unhandled_input(event):
	if !ent_grid:
		print("no tilemap on input recieved")
		return 
	if times_up:
		return
	if is_moving:
		return  

	var now_facing : Facing
	var dir = Vector2i.ZERO

	if event.is_action_pressed("ui_up"):
		now_facing = Facing.UP
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		now_facing = Facing.DOWN
		dir = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left"):
		now_facing = Facing.LEFT
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		now_facing = Facing.RIGHT
		dir = Vector2i(1, 0)

	if dir != Vector2i.ZERO:
		# Check if trying to go opposite direction of visual facing = toggle reverse
		if now_facing == visual_facing:
			reverse = false
		elif now_facing == get_opposite_facing(visual_facing):
			reverse = true 
		elif now_facing != visual_facing:
			visual_facing = now_facing
			reverse = false  # Turning cancels reverse
		
		# Update player_facing based on visual and reverse state
		player_facing = get_opposite_facing(visual_facing) if reverse else visual_facing
		
		if try_move(dir, visual_facing):
			turns += 1
			on_player_move()
		
		tracker.take_turn()
		update_animation(visual_facing)

	if event.is_action_pressed("ui_accept"):
		handle_backhoe_action(grid_pos, player_facing)
			


func get_opposite_facing(facing: Facing) -> Facing:
	match facing:
		Facing.UP: return Facing.DOWN
		Facing.DOWN: return Facing.UP
		Facing.LEFT: return Facing.RIGHT
		Facing.RIGHT: return Facing.LEFT
	return facing

	
func try_move(dir: Vector2i, now_facing:Facing) -> bool:
	if backhoe.is_carrying():
		if backhoe.carried_debris.push_power:
			push_power_up = true 
		else:
			push_power_up = false
	else:
		push_power_up = false 
	var target = grid_pos + dir
	if resolve_movement(target, now_facing):
		grid_pos = target
		return true
	trigger_push_fail(now_facing)
	return false 

func reset_player_flags():
	sunk = false 
	times_up = false 


func on_enter():
	reset_player_flags()
	if sink_tween.is_valid():
		sink_tween.kill()
	z_index = 4
	enter_animation()
	$bulldozer_sprite.play()
	$backhoeSprites.reset()

func resolve_movement(target: Vector2i, now_facing: Facing) -> bool:
	
	if ent_grid.lava.get_cell_source_id(target) != -1:
		return true
	else:
		return ent_grid.resolve_entity_interaction_with_player(self, target, now_facing)
		
func handle_backhoe_action(player_pos: Vector2i, facing: DirectionalCharacter.Facing):
	var scoop_offset = backhoe.get_scoop_offset(visual_facing)
	var scoop_pos = player_pos + scoop_offset
	
	if backhoe.is_carrying():
		# Try to release
		var debris = backhoe.carried_debris
		await backhoe.play_release_animation()
		
		if ent_grid.release_scooped_debris(debris, scoop_pos, facing):
			# Success - backhoe already cleared carried_debris
			pass
		else:
			# Failed to release, pick it back up (shouldn't happen often)
			backhoe.carried_debris = debris
			debris.scooped = true
			debris.visible = false
	else:
		# Try to scoop
		var scooped = ent_grid.scoop_debris_at(scoop_pos)
		if scooped != null:
			await backhoe.play_scoop_animation(scooped)
			# Check for power-ups, etc.
			if scooped.push_power:
				push_power_up = true
		else:
			backhoe.play_no_dirt_animation()
# Call this when player moves with carried debris
func on_player_move():
	if backhoe.is_carrying():
		var carry_pos = grid_pos + backhoe.get_scoop_offset(visual_facing)
		backhoe.update_carried_debris_visual(ent_grid.land, carry_pos)
