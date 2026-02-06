# Player.gd
class_name DirectionalCharacter
extends Entity

const  direction_hold_check_push: float = 0.15
const direction_hold_check_lava: float = 0.4  #seconds 

var turns: int 
var player_facing: Facing = Facing.RIGHT
var previous_facing: Facing = Facing.RIGHT
#while reversing facing and visual facing are opposite 
var visual_facing: Facing = Facing.RIGHT

#state flags 
var pushing: bool = false 
var moving_in_to_lava: bool = false
var pushed_last_turn: bool = false 
var reverse: bool = false 
var sunk: bool = false 
var turned: bool = false 
var broke_tutorial_rule: bool = false 

var arrow_hold_time: float = 0.0
var held_direction: Facing
var attempted_push_direction: Vector2i
var action_cancelled: bool

var map_data: Dictionary

enum Facing { UP, DOWN, LEFT, RIGHT, NONE}

const PIANO_NOTES: Dictionary[Variant, Variant] = {
	"C4": preload("res://sounds/448549__tedagame__c4.ogg"), 
	"D4": preload("res://sounds/448609__tedagame__d4.ogg"),
	"E4": preload("res://sounds/448613__tedagame__e4.ogg"),
	"F4": preload("res://sounds/448585__tedagame__f4.ogg"),
	"G4": preload("res://sounds/448552__tedagame__g4.ogg"),
	"A4": preload("res://sounds/448577__tedagame__a4.ogg"),
	"C2":  preload("res://sounds/448541__tedagame__c2.ogg"), 
}

const NOTE_SEQUENCE = ["C4", "D4", "E4","F4", "G4", "A4"]

var note_index = 0

@export var tracker: gameTracker
@export var times_up: bool 
@onready var backhoe = $backhoeSprites
@onready var state_label = $state
@export var ent_grid: EntityGrid

var push_fail_tween: Tween = null
var sink_tween: Tween = create_tween()
func _ready():
	add_to_group("player")
	tracker.connect("player_finished", _on_player_finished)
	tracker.connect("new_map_instance", _on_new_map)
	

func play_wrong_note():
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = PIANO_NOTES["C2"]
	player.pitch_scale = .9  # Slight pitch variation
	player.finished.connect(player.queue_free)
	player.volume_db = -15
	player.play()
	
	# Move to next note, wrap around
func play_next_note():
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = PIANO_NOTES[NOTE_SEQUENCE[note_index]]
	player.pitch_scale = .9  # Slight pitch variation
	player.finished.connect(player.queue_free)
	player.volume_db = -15
	player.play()
	
	# Move to next note, wrap around
	note_index = (note_index + 1) % (NOTE_SEQUENCE.size())
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
	map_data = data 	
	if sink_tween.is_valid():
		sink_tween.kill()
	print("player got new map")
	ent_grid = tracker.current_ent_grid
	global_position = data.player_pos as Vector2i  
	grid_pos = ent_grid.land.local_to_map(global_position)
	ent_grid.sync_position_to_grid_pos(self)
	visual_pos = ent_grid.land.map_to_local(grid_pos)
	var start_face = data.facing
	on_enter(data.retry)		
		
	player_facing = start_face
	previous_facing = start_face
	visual_facing = start_face
	update_visual_facing(start_face)

	update_animation(player_facing)

func add_push_strain():
	var strain = sin(Time.get_ticks_msec() * 0.03) * 2.0
	strain += randf_range(-1.5, 1.5)
	rotation_degrees = strain

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
	
	$bulldozer_sprite.animation = animation_name
	
func _process(delta):
	if canned_animation:
		return 
	if !ent_grid:
		print("no map or entity data in player process: blocking")
		return
	if push_fail_tween and push_fail_tween.is_running():
		print("animated tween running player process: blocking")
		global_position = visual_pos
		return
	
	update_animation(visual_facing)
	
	# Visual smoothly catches up to logical position
	var target: Vector2 = ent_grid.land.map_to_local(grid_pos)
	if global_position == target: #movement completed check before input
		is_moving = false 
		if sunk:	
			print("sunk flag on in player process: blocking")	
			call_deferred("sink")  
	if pushing || moving_in_to_lava:
		if action_cancelled:
			var previous_pos: Vector2 = ent_grid.land.map_to_local(grid_pos)
			visual_pos = visual_pos.move_toward(previous_pos, delta * 60)
		else:
			var possible_targ: Vector2 = ent_grid.land.map_to_local(grid_pos+attempted_push_direction)
			visual_pos = visual_pos.move_toward(possible_targ,  delta * 60)
	else:
		visual_pos = visual_pos.move_toward(target, move_speed * delta * 60)
		
	global_position = visual_pos
	
	if Input.is_action_pressed("ui_up") and held_direction == Facing.UP:
		arrow_hold_time += delta 
	elif Input.is_action_pressed("ui_down") and held_direction == Facing.DOWN:
		arrow_hold_time += delta 
	elif Input.is_action_pressed("ui_left") and held_direction == Facing.LEFT:
		arrow_hold_time += delta  
	elif Input.is_action_pressed("ui_right") and held_direction == Facing.RIGHT:
		arrow_hold_time += delta  
	else:
		#no input this frame path, cancel action if there was input previously
		if pushing || moving_in_to_lava and arrow_hold_time !=0:	
			update_visual_facing(previous_facing)
			pass
		arrow_hold_time = 0 
		action_cancelled = true 
		moving_in_to_lava = false 
		pushing = false 
		held_direction = Facing.NONE
		return 
	
	if arrow_hold_time > 0 and !pushing and !moving_in_to_lava:
		if map_data.reverse_only and !reverse and !turned and !backhoe.is_carrying():
			broke_tutorial_rule = true
			play_wrong_note()
		if ent_grid.land.get_cell_source_id(grid_pos+ attempted_push_direction):
			broke_tutorial_rule = true
			play_wrong_note()	
		elif map_data.tutorial:
			play_next_note()
		
		print("player at standard no push or lava input")
		pushed_last_turn = false 
		process_input_result(attempted_push_direction, held_direction)
		held_direction = Facing.NONE
		attempted_push_direction = Vector2i.ZERO
		arrow_hold_time = 0 
	elif moving_in_to_lava and arrow_hold_time > direction_hold_check_lava:
		print("player at moving in to lava input")
		process_input_result(attempted_push_direction, held_direction)
		held_direction = Facing.NONE
		attempted_push_direction = Vector2i.ZERO
		arrow_hold_time = 0  
		moving_in_to_lava = false  #
	elif pushing and (arrow_hold_time > direction_hold_check_push) || pushed_last_turn: #psuh
		var result: EntityGrid.Player_Action_Result = ent_grid.test_entity_interaction_with_player(self, grid_pos+attempted_push_direction, held_direction)
		#if there is a change of state, re - require long push 
		if result != EntityGrid.Player_Action_Result.NORMAL_PUSH:
			print("flipping pushed last turn since players action would result in state change")
			if pushed_last_turn:
				pushed_last_turn = false
				return
		print("player at pushing input") 
		process_input_result(attempted_push_direction, held_direction)
		pushed_last_turn = true 
		held_direction = Facing.NONE
		attempted_push_direction = Vector2i.ZERO
		arrow_hold_time = 0  
		pushing = false  #
		
func process_input_result(dir: Vector2i, now_facing: Facing):	
	if dir != Vector2i.ZERO:
		update_visual_facing(now_facing)
	
		if try_move(dir, visual_facing):
			turns += 1
			on_player_move()
			tracker.take_turn()
		else:
			print("try move returned fail for player")
		update_animation(visual_facing)
				
func _unhandled_input(event) -> void:
	var directional_actions: Array[String] = ["ui_up", "ui_down", "ui_left", "ui_right"]
	var any_arrow_released: bool = directional_actions.any(func(action): return event.is_action_released(action))
	if canned_animation:
		print("hit canned animation flag, blocking input")
		return
	if !ent_grid:
		print("no tilemap on input recieved")
		return 
	if times_up:
		print("hit player times up flag blocking input")
		return
	if any_arrow_released:
		print("logging release of arrow key")
		arrow_hold_time = 0
		attempted_push_direction = Vector2i.ZERO
		return	
	if event.is_action_pressed("ui_accept"):
		handle_backhoe_action(grid_pos, player_facing)
		return
	if event.is_action_pressed("ui_up"):
		held_direction = Facing.UP
		attempted_push_direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		held_direction = Facing.DOWN
		attempted_push_direction = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left"):
		held_direction = Facing.LEFT
		attempted_push_direction = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		held_direction = Facing.RIGHT
		attempted_push_direction = Vector2i(1, 0)
	
	if attempted_push_direction != Vector2i.ZERO:
		action_cancelled = false
		arrow_hold_time = 0 
		update_visual_facing(held_direction)

		if ent_grid.has_entity_at(grid_pos + attempted_push_direction) and arrow_hold_time < direction_hold_check_push || ent_grid.button.grid_pos == grid_pos + attempted_push_direction:
			print("setting pushing flag")
			pushing = true 
			return 
		else:
			pushed_last_turn = false
		
		if ent_grid.lava_at(grid_pos + attempted_push_direction) and arrow_hold_time < direction_hold_check_lava:
			print("setting moving in to lava flag")
			moving_in_to_lava = true 
			return	


func update_visual_facing(now_facing:Facing):
	
	if now_facing == Facing.NONE:
		print("blocking player facing getting set to none")
		return	
	previous_facing = player_facing
	if now_facing == visual_facing:
		reverse = false
		turned = false
	elif now_facing == get_opposite_facing(visual_facing):
		reverse = true 
	elif now_facing != visual_facing:
		turned = true 
		visual_facing = now_facing
		reverse = false  # Turning cancels reverse

	if reverse: 
		player_facing = get_opposite_facing(visual_facing)
	else:
		player_facing = visual_facing

	


func get_opposite_facing(facing: Facing) -> Facing:
	match facing:
		Facing.UP: return Facing.DOWN
		Facing.DOWN: return Facing.UP
		Facing.LEFT: return Facing.RIGHT
		Facing.RIGHT: return Facing.LEFT
	return facing

	
func try_move(dir: Vector2i, now_facing:Facing) -> bool:
	var target: Vector2i = grid_pos + dir
	if resolve_movement(target, now_facing):
		grid_pos = target
		
			
		return true
	trigger_push_fail(now_facing)
	return false 

func reset_player_flags():
	sunk = false 
	times_up = false
	pushing = false 
	moving_in_to_lava = false
	pushed_last_turn  = false 
	reverse = false
	broke_tutorial_rule = false 
	

func on_enter(retry: bool):
	reset_player_flags()
	if sink_tween.is_valid():
		sink_tween.kill()
	if retry:
		canned_animation = false 
	if !map_data.retry and !map_data.tutorial:
		z_index = 4
		enter_animation()
	$bulldozer_sprite.play()
	$backhoeSprites.reset()

func resolve_movement(target: Vector2i, now_facing: Facing) -> bool:
	
	if ent_grid.lava.get_cell_source_id(target) != -1:
		print("player moving in to lava on resolve movement")
		sunk = true 
		return true
	else:
		var result: EntityGrid.Player_Action_Result = ent_grid.resolve_entity_interaction_with_player(self, target, now_facing)
		if result == EntityGrid.Player_Action_Result.INVALID:
			print("invalid result returned from player entity interaction")
			return false	
	return true 
	
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
		else:
			backhoe.play_no_dirt_animation()
# Call this when player moves with carried debris
func on_player_move():
	if backhoe.is_carrying():
		var carry_pos = grid_pos + backhoe.get_scoop_offset(visual_facing)
		backhoe.update_carried_debris_visual(ent_grid.land, carry_pos)
	if ent_grid.button != null:
		if ent_grid.button.grid_pos == grid_pos:
			ent_grid.button.press()
	if ent_grid.completion_flag != null:
		if ent_grid.completion_flag.grid_pos == grid_pos:
			ent_grid.completion_flag.press()
		
