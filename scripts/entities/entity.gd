class_name Entity
extends Node2D

enum ShapeType { SINGLE, TREE_STANDING, TREE_FALLEN, L_SHAPE, T_SHAPE }

# Grid & positions
var grid_pos: Vector2i
var visual_pos: Vector2
var local_positions: Array[Vector2i] = [Vector2i.ZERO]
var visual_position_modifier: Vector2
var rotation_state: int = 0

# State flags
var broken: bool = false
var pushable: bool = false
var cleaned_up: bool = false
var is_moving: bool = false

var animated_effect: String
# Exports
@export var shape_type: ShapeType = ShapeType.SINGLE
@export var tilemap_fences_layer: TileMapLayer 
@export var tilemap: TileMapLayer
@export var texture_path_name: String
@export var split: bool = true

@onready var sprite = $Sprite2D

var broken_up_texture: Texture
var unbroken_texture: Texture
var move_speed = 10
var free_after_move: bool 

var last_turn_result: DebrisAction

signal DebrisCleaned
signal DebrisBrokenUp
signal HitFence 


func _ready() -> void:
	add_to_group("debris")
	grid_pos = tilemap.local_to_map(position)
	initialize_shape(shape_type)
	
	var unbroken_asset_path = "res://art/" + texture_path_name + ".png"
	var broken_asset_path = "res://art/" + texture_path_name + "_broken_up" + ".png"
	unbroken_texture = load(unbroken_asset_path)
	broken_up_texture = load(broken_asset_path)
	
	sprite.texture = unbroken_texture
	visual_pos = tilemap.map_to_local(grid_pos)

func set_free_after_move():
	free_after_move = true 
	
func trigger_push_fail(directionFlag: DirectionalCharacter.Facing) -> Tween:
	
	var direction = Vector2i.ZERO
	direction = get_push_vector(directionFlag)
	var push_distance = 8.0
	var push_target = visual_pos + direction * push_distance
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)  # This gives the bounce-back effect
	tween.tween_property(self, "visual_pos", push_target, 0.25)
	tween.tween_property(self, "visual_pos", visual_pos, 0.26)
	
	# Optional wobble
	var rot_tween = create_tween()
	rot_tween.tween_property(self, "rotation_degrees", 5.0, 0.1)
	rot_tween.tween_property(self, "rotation_degrees", -5.0, 0.1)
	rot_tween.tween_property(self, "rotation_degrees", 0.0, 0.1)
	return tween

func _process(delta: float) -> void:
	if Vector2i(visual_pos) != grid_pos:
		var target = tilemap.map_to_local(grid_pos)
		visual_pos = visual_pos.move_toward(target + visual_position_modifier, move_speed * delta * 60)
		global_position = visual_pos
		is_moving = visual_pos.distance_to(target) > 1.0
	if !is_moving and free_after_move:
		queue_free()

# === SHAPE & POSITION SYSTEM ===

func initialize_shape(type: ShapeType) -> void:
	shape_type = type
	match type:
		ShapeType.SINGLE:
			local_positions = [Vector2i.ZERO]
		ShapeType.TREE_STANDING:
			local_positions = [Vector2i.ZERO]
		ShapeType.TREE_FALLEN:
			local_positions = [Vector2i.ZERO, Vector2i(1, 0)]
		ShapeType.L_SHAPE:
			local_positions = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1)]
		ShapeType.T_SHAPE:
			local_positions = [Vector2i.ZERO, Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]
	rotation_state = 0
	update_visuals_from_positions()


func get_world_positions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for local_pos in local_positions:
		result.append(grid_pos + local_pos)
	return result


func occupies(world_pos: Vector2i) -> bool:
	return world_pos in get_world_positions()


func normalize_positions() -> void:
	var offset = local_positions[0]
	if offset != Vector2i.ZERO:
		grid_pos += offset
		for i in local_positions.size():
			local_positions[i] -= offset


# === ROTATION & PIVOT ===

func rotate_cw() -> void:
	for i in local_positions.size():
		var p = local_positions[i]
		local_positions[i] = Vector2i(-p.y, p.x)
	rotation_state = (rotation_state + 1) % 4
	update_visuals_from_positions()


func rotate_ccw() -> void:
	for i in local_positions.size():
		var p = local_positions[i]
		local_positions[i] = Vector2i(p.y, -p.x)
	rotation_state = (rotation_state + 3) % 4
	update_visuals_from_positions()


func pivot_around(pivot_index: int, clockwise: bool) -> void:
	if pivot_index < 0 or pivot_index >= local_positions.size():
		return
	var pivot_local = local_positions[pivot_index]
	
	for i in local_positions.size():
		local_positions[i] -= pivot_local
	
	if clockwise:
		rotate_cw()
	else:
		rotate_ccw()
	
	var new_pivot_local = local_positions[pivot_index]
	grid_pos += pivot_local - new_pivot_local
	normalize_positions()
	update_position()


func get_pivot_clockwise(push_direction: DirectionalCharacter.Facing, pivot_index: int) -> bool:
	var push_vec = get_push_vector(push_direction)
	var pivot_pos = local_positions[pivot_index]
	
	var other_index = 0 if pivot_index != 0 else 1
	var other_pos = local_positions[other_index]
	var relative = other_pos - pivot_pos
	
	var cross = push_vec.x * relative.y - push_vec.y * relative.x
	return cross < 0


func try_pivot(push_direction: DirectionalCharacter.Facing) -> bool:
	if local_positions.size() < 2:
		return false
	
	var push_vec = get_push_vector(push_direction)
	var world_positions = get_world_positions()
	
	# Find blocked and free tiles
	var blocked_index = -1
	var free_index = -1
	
	for i in world_positions.size():
		if check_collision_at(world_positions[i] + push_vec, self):
			if blocked_index == -1:
				blocked_index = i
			else:
				return false  # Multiple blocked = no pivot
		else:
			free_index = i
	
	if blocked_index == -1 or free_index == -1:
		return false
	
	# The obstacle position (what we pivot around)
	var obstacle_pos = world_positions[blocked_index] + push_vec
	
	# Free tile moves in push direction
	var free_new = world_positions[free_index] + push_vec
	
	# Blocked tile slides to the side (perpendicular to push, away from obstacle)
	# It ends up adjacent to where free tile lands
	var blocked_to_free = world_positions[free_index] - world_positions[blocked_index]
	var blocked_new = free_new - blocked_to_free
	
	var perpendicular = blocked_to_free  # Direction from blocked to free
	blocked_new = world_positions[blocked_index] + push_vec + perpendicular
	
	free_new = blocked_new + push_vec
	
	# Check destinations are clear
	if check_collision_at(blocked_new, self):
		return false
	if check_collision_at(free_new, self):
		return false
	
	# Update positions - keep base at blocked (index 0) position
	grid_pos = blocked_new
	local_positions[0] = Vector2i.ZERO
	local_positions[1] = free_new - blocked_new
	
	update_visuals_from_positions()
	update_position()
	return true


# === VISUAL UPDATES ===

func update_visuals_from_positions() -> void:
	if local_positions.size() < 2:
		sprite.rotation = 0
		visual_position_modifier = Vector2.ZERO
		return
	
	var tail = local_positions[1]
	match tail:
		Vector2i(1, 0):
			sprite.rotation = PI
			visual_position_modifier = Vector2(32, 32)
		Vector2i(-1, 0):
			sprite.rotation = 0
			visual_position_modifier = Vector2(-32, 32)
		Vector2i(0, -1):
			sprite.rotation = PI / 2
			visual_position_modifier = Vector2(0, 0)
		Vector2i(0, 1):
			sprite.rotation = 3 * PI / 2
			visual_position_modifier = Vector2(0, 64)


func update_position() -> void:
	if !cleaned_up:
		for world_pos in get_world_positions():
			if tilemap.get_cell_atlas_coords(world_pos) == Vector2i(1, 0):
				cleaned_up = true
				DebrisCleaned.emit()
				flash_and_free(self)
				return


# === STATE CHANGES ===

func set_broken_flags() -> void:
	broken = true
	pushable = true


func uproot(push_direction: DirectionalCharacter.Facing) -> bool:
	if shape_type != ShapeType.TREE_STANDING:
		return false
	
	var push_vec = get_push_vector(push_direction)
	var temp_local_positions :Array[Vector2i] = [Vector2i.ZERO, push_vec]
	var targ = grid_pos + push_vec
	if fence_at(targ):
		return false 
	if fence_at(targ +push_vec):
		return false 
	var deb1 =  find_debris_at(targ) 
	var deb2 = find_debris_at(push_vec+targ)
	
	if deb1 != null:
		if deb1.broken and deb1.split:
			if push_direction == DirectionalCharacter.Facing.UP || push_direction == DirectionalCharacter.Facing.DOWN:
				deb1.push(DirectionalCharacter.Facing.LEFT)
			else:
				deb1.push(DirectionalCharacter.Facing.DOWN)
		else:
			return false
	if deb2 != null:
		if deb2.broken and deb2.split:
			if push_direction == DirectionalCharacter.Facing.UP || push_direction == DirectionalCharacter.Facing.DOWN:
				deb2.push(DirectionalCharacter.Facing.LEFT)
			else:
				deb2.push(DirectionalCharacter.Facing.DOWN)
		else:
			deb2.bulldoze(push_direction)
	
	grid_pos = targ
	local_positions = temp_local_positions		
	shape_type = ShapeType.TREE_FALLEN	
	update_visuals_from_positions()
	update_position()
	return true 


func bulldoze(push_direction: DirectionalCharacter.Facing) -> bool:
	if broken:
		return false
	var bulldozed = false
	if shape_type == ShapeType.TREE_STANDING:
		bulldozed =  uproot(push_direction)
	if split:
		break_up_debris(push_direction)
		bulldozed = true 
	if bulldozed:
		set_broken_flags()
		$Sprite2D.texture = broken_up_texture
	return bulldozed

# === PUSH SYSTEM ===

func fence_at(pos: Vector2i) -> bool:
	if tilemap_fences_layer == null:
		return false  # No fences layer = no fences
	return tilemap_fences_layer.get_cell_source_id(pos) != -1

func push(push_direction: DirectionalCharacter.Facing) -> bool:
	if !pushable:
		print("player cant move because colliding with non pushable")
		return false
	
	var push_vec = get_push_vector(push_direction)
	var world_positions = get_world_positions()
	
	# === PHASE 1: Validate all positions ===
	for world_pos in world_positions:
		var target_pos = world_pos + push_vec
		
		# Invalid tile
		if tilemap.get_cell_source_id(target_pos) == -1:
			print("player cant move because pushed object would resolve to invalid position")
			return false
		if fence_at(target_pos):
			print("push resulted in fence collision")
			enact_hit_fence(push_direction)
			return true 
		
		# Check entity collisions (without pushing yet)
		if !can_push_to(target_pos, push_direction):
			print("cannot push to targ after push has been called, returning false")
			if shape_type == ShapeType.TREE_FALLEN:
				return try_pivot(push_direction)
			return false
	
	# Push any debris in the way
	#only push after confirming all target positions are free 
	for world_pos in world_positions:
		var target_pos = world_pos + push_vec
		push_debris_at(target_pos, push_direction)
	
	grid_pos += push_vec
	update_position()
	return true
	
func enact_hit_fence(push_direction: DirectionalCharacter.Facing):
	print("emitting fence hit signal")
	HitFence.emit({"push_direction": push_direction, "coords": grid_pos+ get_push_vector(push_direction)})
	var target_pos = grid_pos 
	var recombined: bool
	var rebound_tween = trigger_push_fail(push_direction)
	await rebound_tween.finished
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris == self:
			continue
		if debris.grid_pos == target_pos and debris.split:
			print("recombining debris after fence bounce")
			self.grid_pos = target_pos
			recombine_debris(debris, self)
			recombined = true 
	if !recombined:
		grid_pos = target_pos

func can_push_to(target: Vector2i, push_direction: DirectionalCharacter.Facing) -> bool:
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris == self or !debris.occupies(target):
			continue
		
		# Only split broken debris can be in the way
		if !debris.broken or !debris.split:
			return false
	
	return true


func can_be_pushed(push_direction: DirectionalCharacter.Facing) -> bool:
	if !pushable:
		return false
	var push_vec = get_push_vector(push_direction)
	for world_pos in get_world_positions():
		var target = world_pos + push_vec
		if tilemap.get_cell_source_id(target) == -1:
			return false
		if !can_push_to(target, push_direction):
			return false
	return true


func push_debris_at(target: Vector2i, push_direction: DirectionalCharacter.Facing) -> void:
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris == self:
			continue
		if not debris.occupies(target):
			continue
		
		if split and broken and debris.broken and debris.split:
			# Check if there's a chain that ends at an obstacle
			var chain = get_push_chain(debris, push_direction)
			
			if chain.size() > 0:
				# Last debris in chain would hit obstacle
				var last = chain[-1]
				var push_vec = get_push_vector(push_direction)
				var obstacle_pos = last.grid_pos + push_vec
				
				if fence_at(obstacle_pos) or has_solid_debris_at(obstacle_pos, chain):
					# Recombine last two in chain
					if chain.size() >= 2:
						var second_last = chain[-2]
						print("Recombining end of chain: %v and %v" % [second_last.grid_pos, last.grid_pos])
						recombine_debris(second_last, last)
						chain.remove_at(chain.size() - 1) 
						chain.remove_at(chain.size()-2) # Remove last since it's gone
					
					# Push remaining chain
					for i in range(chain.size() - 1, -1, -1):  # Push from back to front
						chain[i].push(push_direction)
					return
			
			# No chain or no obstacle - normal push
			if debris.can_be_pushed(push_direction):
				debris.push(push_direction)
			else:
				# Can't push and no chain = recombine with immediate neighbor
				recombine_debris(self, debris)
		
		elif !split:
			if debris.can_be_pushed(push_direction):
				debris.push(push_direction)


func get_push_chain(start_debris: Entity, push_direction: DirectionalCharacter.Facing) -> Array[Entity]:
	var chain: Array[Entity] = [self, start_debris]
	var push_vec = get_push_vector(push_direction)
	var current = start_debris
	
	while true:
		var next_pos = current.grid_pos + push_vec
		var next_debris = find_debris_at(next_pos)
		
		if next_debris == null:
			break  # No more debris in chain
		if next_debris == self:
			break  # Don't include pusher
		if !next_debris.broken or !next_debris.split:
			break  # Hit solid debris, chain ends
		
		chain.append(next_debris)
		current = next_debris
	
	return chain


# === COLLISION HELPERS ===

func check_collision_at(pos: Vector2i, ignore_entity: Entity) -> bool:
	if tilemap.get_cell_source_id(pos) == -1:
		return true
	
	for entity in get_tree().get_nodes_in_group("debris"):
		if entity == ignore_entity:
			continue
		if entity.occupies(pos):
			return true
	
	return false


func check_for_debris_at_targ(target: Vector2i) -> bool:
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris.occupies(target):
			return true
	return false


# === ENTITY INTERACTIONS ===

func resolve_entity_interaction_after_push(movingEnt: Entity, target: Vector2i, push_direction: DirectionalCharacter.Facing) -> Vector2i:
	for debris in get_tree().get_nodes_in_group("debris"):
		debris = debris as Entity
		if debris == movingEnt:
			continue
		if not debris.occupies(target):
			continue
		if !debris.broken:
			return Vector2i.ZERO
		else:
			var push_possible = debris.push(push_direction)
			if !push_possible:
				return Vector2i.ZERO
	return target


func resolve_entity_interaction_after_broken_up(newly_broken: Entity, target: Vector2i, break_direction: DirectionalCharacter.Facing) -> Vector2i:
	for debris in get_tree().get_nodes_in_group("debris"):
		debris = debris as Entity
		if debris == newly_broken:
			continue
		if not debris.occupies(target):
			continue
		if !debris.broken || !debris.split :
			#if would land on invalid tile push to next tile and recheck interactions
			target = target + get_push_vector(break_direction)
			return resolve_entity_interaction_after_broken_up(newly_broken, target, break_direction)
		if debris.broken:
			if debris.split:
				recombine_debris(debris, newly_broken)
			return target
	return target

func find_debris_at(pos: Vector2i) -> Entity:
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris.occupies(pos):
			return debris
	return null


func has_solid_debris_at(pos: Vector2i, ignore_chain: Array[Entity]) -> bool:
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris in ignore_chain or debris == self:
			continue
		if debris.occupies(pos):
			if !debris.broken or !debris.split:
				return true
	return false


func back_hoe_break_up_debris() -> Entity:
	#breaks a debris into two in place and returns the copy for backhoe to carry rather than pushing apart
	set_broken_flags()
	self.sprite.texture = broken_up_texture
	
	var copy = self.duplicate()
	get_parent().add_child(copy)
	copy._ready()
	copy.set_broken_flags()
	copy.sprite.texture = broken_up_texture
	
	update_position()
	copy.update_position()
	
	DebrisBrokenUp.emit()
	return copy 

func break_up_debris(push_direction: DirectionalCharacter.Facing) -> void:
	var copy = self.duplicate()
	get_parent().add_child(copy)
	copy._ready()
	copy.set_broken_flags()
	copy.sprite.texture = broken_up_texture
	
	var new_pos = Vector2i.ZERO
	var new_copy_pos = Vector2i.ZERO
	
	var after_break_push_direction
	var after_break_push_direction_copy
	
	if push_direction == DirectionalCharacter.Facing.UP or push_direction == DirectionalCharacter.Facing.DOWN:
		new_pos = grid_pos + Vector2i(-1, 0)
		new_copy_pos = grid_pos + Vector2i(1, 0)
		after_break_push_direction = DirectionalCharacter.Facing.LEFT
		after_break_push_direction_copy = DirectionalCharacter.Facing.RIGHT
	else:
		new_pos = grid_pos + Vector2i(0, -1)
		new_copy_pos = grid_pos + Vector2i(0, 1)
		after_break_push_direction = DirectionalCharacter.Facing.UP
		after_break_push_direction_copy = DirectionalCharacter.Facing.DOWN
	

	new_pos = resolve_entity_interaction_after_broken_up(self, new_pos, after_break_push_direction)
	new_copy_pos = resolve_entity_interaction_after_broken_up(copy, new_copy_pos, after_break_push_direction_copy)
	
	if fence_at(new_pos):
		print("orignal debris hit fence after break apart bulldoze")
		new_pos = grid_pos + get_push_vector(push_direction)
	if fence_at(new_copy_pos):
		new_copy_pos = grid_pos + get_push_vector(push_direction)

		
	grid_pos = new_pos
	copy.grid_pos = new_copy_pos
	copy.visual_pos = visual_pos
	
	update_position()
	copy.update_position()
	
	DebrisBrokenUp.emit()


func recombine_debris(existing_debris: Entity, moving_debris: Entity) -> void:
	if !existing_debris.split or !moving_debris.split:
		return

	existing_debris.sprite.texture = unbroken_texture
	existing_debris.broken = false
	moving_debris.queue_free()


# === UTILITIES ===

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
	if entity is Entity:
		entity.grid_pos = Vector2i(-10, -10)
	var tween = create_tween()
	
	for i in flash_count:
		tween.tween_property(entity, "modulate:a", 0.0, flash_duration)
		tween.tween_property(entity, "modulate:a", 1.0, flash_duration)
	
	await tween.finished
	entity.queue_free()
