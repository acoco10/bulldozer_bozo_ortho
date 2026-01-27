class_name EntityGrid extends Node2D

var entities: Dictionary[Vector2i, Entity] = {}
@export var lava: TileMapLayer
@export var land: TileMapLayer

func _ready():
	# Register all entities
	for child in get_children():
		if child is Entity:
			child.grid_pos  = land.local_to_map(child.position)
			sync_position_to_grid_pos(child)
			register(child)

func register(entity: Entity):
	entities[entity.grid_pos] = entity
	entity.tree_exiting.connect(func(): unregister(entity))

func unregister(entity: Entity):
	entities.erase(entity.grid_pos)

func get_debris_at(pos: Vector2i) -> Debris:
	var get_ent = entities.get(pos)
	return get_ent as Debris
	
func sync_position_to_grid_pos(entity: Entity):
	entity.visual_pos = land.map_to_local(entity.grid_pos)
	entity.visual_target = entity.visual_pos
	entity.global_position = entity.visual_pos

func has_entity_at(pos: Vector2i) -> bool:
	return entities.has(pos)

func lava_at(pos: Vector2i) -> bool:
	return lava.get_cell_source_id(pos) != -1

func push_entity(entity: Entity, direction: DirectionalCharacter.Facing, push_power: bool = false) -> bool:
	if entity is Debris:
		return push_debris(entity, direction, push_power)
	# Handle other entity types
	return false
	
func get_push_vector(direction: DirectionalCharacter.Facing) -> Vector2i:
	match direction:
		DirectionalCharacter.Facing.LEFT:
			return Vector2i(-1, 0)
		DirectionalCharacter.Facing.RIGHT:
			return Vector2i(1, 0)
		DirectionalCharacter.Facing.UP:
			return Vector2i(0, -1)
		DirectionalCharacter.Facing.DOWN:
			return Vector2i(0, 1)
		_:
			return Vector2i.ZERO
	
func back_hoe_break_up_debris(pos: Vector2i) -> Entity:
	var debris = get_debris_at(pos)
	if !debris.breakable:
		return null
	#breaks a debris into two in place and returns the copy for backhoe to carry rather than pushing apart
	else:
		debris.set_broken_flags()
		debris.sprite.texture = debris.broken_up_texture
		
		var copy = debris.duplicate()
		get_parent().add_child(copy)
		copy._ready()
		copy.set_broken_flags()
		copy.sprite.texture = debris.broken_up_texture
			
		return copy 
		
func push_debris(debris: Debris, direction: DirectionalCharacter.Facing, push_power: bool) -> bool:
	if !debris.pushable and !push_power:
		return false
		
	var push_vec = get_push_vector(direction)
	var target_pos = debris.grid_pos + push_vec
	
	if lava_at(target_pos):
		move(debris, target_pos)
		flash_and_free(debris)
		return true 
	
	var blocker = get_debris_at(target_pos)
	if blocker == null:
		move(debris, target_pos)
		return true
		
	
	if !blocker.pushable:
		return false
	
	# Build chain (includes blocker and everything behind it)
	var chain = get_push_chain(blocker, direction)
	
	if chain.size() > 0:
		var obstacle_pos = chain[-1].grid_pos + push_vec
		
		# Check if chain hits obstacle
		if has_solid_debris_at(obstacle_pos):
			# Include the pusher debris in recombination check
			if chain.size() >= 1 and debris.broken and chain[-1].broken:
				# Recombine pusher with last in chain
				recombine_debris(chain[-1], debris)
				chain.pop_back()  # Remove the one we just recombined into
			elif chain.size() >= 2:
				# Recombine within chain
				var last = chain.pop_back()
				var second_last = chain.pop_back()
				recombine_debris(last, second_last)
		
		# Push remaining chain
		if chain.size() > 0:
			for i in range(chain.size() - 1, -1, -1):
				if !push_debris(chain[i], direction, false):
					return true
	
	# Only move original if it wasn't recombined
	if is_instance_valid(debris) and !debris.is_queued_for_deletion():
		move(debris, target_pos)
	
	return true

func get_push_chain(start_debris: Entity, direction: DirectionalCharacter.Facing) -> Array[Entity]:
	var chain: Array[Entity] = [start_debris]
	var push_vec = get_push_vector(direction)
	var current = start_debris
	
	while true:
		var next_pos = current.grid_pos + push_vec
		var next_entity = get_debris_at(next_pos)
		if !has_entity_at(next_pos):
			break
		if next_entity is not Debris:
			break
		next_entity = next_entity as Debris
		if !next_entity.pushable:
			break
		chain.append(next_entity)
		current = next_entity
	
	return chain

func move(entity: Entity, new_pos: Vector2i):
	if get_debris_at(entity.grid_pos) == entity:
		#only erase last position entity is registered at that position 
		entities.erase(entity.grid_pos)
	entity.grid_pos = new_pos
	entities[new_pos] = entity
	set_visual_targ_to_new_grid_pos(entity)

func set_visual_targ_to_new_grid_pos(entity: Entity):
	entity.visual_target = land.map_to_local(entity.grid_pos)

func recombine_debris(existing: Debris, moving: Debris):
	if !existing.broken or !moving.broken:
		return
	existing.sprite.texture = existing.unbroken_texture
	existing.broken = false
	existing.pushable = false
	unregister(moving)		
	register(existing)

	moving.queue_free()

func has_solid_debris_at(pos: Vector2i) -> bool:
	var debris_check = get_debris_at(pos)
	if debris_check == null:
		return false  
	return !debris_check.pushable
	
#visual effects 

func flash_and_free(entity: Node2D, flash_count: int = 3, flash_duration: float = 0.3) -> void:
	if !entity.is_queued_for_deletion():
		var tween = create_tween()
		
		for i in flash_count:
			tween.tween_property(entity, "modulate:a", 0.0, flash_duration)
			tween.tween_property(entity, "modulate:a", 1.0, flash_duration)
		
		await tween.finished
		entity.queue_free()
		
func flash(entity: Node2D, flash_count: int = 3, flash_duration: float = 0.3):
	var tween = create_tween()
		
	for i in flash_count:
		tween.tween_property(entity, "modulate:a", 0.0, flash_duration)
		tween.tween_property(entity, "modulate:a", 1.0, flash_duration)
	
func break_up_debris(debris: Debris, push_direction: DirectionalCharacter.Facing):
	debris.set_broken_flags()
	debris.sprite.texture = debris.broken_up_texture
	
	# Store original visual position FIRST
	var original_visual_pos = debris.visual_pos
	
	var copy = debris.duplicate()
	get_parent().add_child(copy)
	copy._ready()
	copy.set_broken_flags()
	copy.sprite.texture = copy.broken_up_texture
	
	# DON'T register yet - copy is at same grid_pos as debris
	
	var push_vec = Vector2i.ZERO
	var copy_push_vec = Vector2i.ZERO

	if push_direction == DirectionalCharacter.Facing.UP or push_direction == DirectionalCharacter.Facing.DOWN:
		push_vec = Vector2i(-1, 0)
		copy_push_vec = Vector2i(1, 0)
	else:
		push_vec = Vector2i(0, 1)
		copy_push_vec = Vector2i(0, -1)
	
	var new_pos = debris.grid_pos + push_vec
	var new_copy_pos = debris.grid_pos + copy_push_vec  # Use debris.grid_pos, not copy

	# Safety limits
	var max_checks = 50
	var checks = 0
	while has_solid_debris_at(new_pos) and checks < max_checks:
		new_pos += push_vec
		checks += 1
	
	checks = 0
	while has_solid_debris_at(new_copy_pos) and checks < max_checks:
		new_copy_pos += copy_push_vec
		checks += 1
	
	var recombine = get_debris_at(new_pos)
	var recombine_copy = get_debris_at(new_copy_pos)
	
	# Handle copy first
	if recombine_copy != null and recombine_copy.broken:
		recombine_debris(recombine_copy, copy)
	else:
		# Set position BEFORE registering/moving
		copy.grid_pos = new_copy_pos
		copy.visual_pos = original_visual_pos  # Start at original position
		copy.visual_target = land.map_to_local(new_copy_pos)  # Animate to new position
		register(copy)  # Now safe to register
	
	# Handle original
	if recombine != null and recombine.broken:
		recombine_debris(recombine, debris)
	else:
		move(debris, new_pos)
		debris.visual_pos = original_visual_pos  # Reset to start position
		
func resolve_entity_interaction_with_player(player: DirectionalCharacter, target: Vector2i, new_facing: DirectionalCharacter.Facing) -> bool:
	var debris_at_targ = get_debris_at(target)
	if debris_at_targ == null:
		return true 
	if player.reverse: 
		return	false 
	if debris_at_targ.pushable:
		return push_debris(debris_at_targ, new_facing, false)
	elif debris_at_targ.breakable:
		break_up_debris(debris_at_targ, new_facing)
		return true 
	elif player.push_power_up:
		return push_debris(debris_at_targ,new_facing,  true)
		
	return false
# === EntityGrid.gd (add these methods) ===

# Scoop debris at position, returns the entity or null
func scoop_debris_at(pos: Vector2i) -> Entity:
	var debris = get_debris_at(pos)
	if debris == null:
		return null
	if debris.breakable:
		if debris.broken:
			# Already broken, just pick it up
			unregister(debris)
			return debris
		else:
			# Break it and return the copy
			return back_hoe_break_up_debris(pos)
	elif debris.scoopable:
		unregister(debris)
		return debris
	
	return null

# Release scooped debris, returns true if successful
func release_scooped_debris(scooped_debris: Entity, release_pos: Vector2i, direction: DirectionalCharacter.Facing) -> bool:
	if scooped_debris == null:
		return false
	
	# Check what's at release position
	var existing = get_debris_at(release_pos)
	
	if existing != null:
		# Something's there
		if existing.broken and scooped_debris.broken:
			# Recombine broken pieces
			recombine_debris(existing, scooped_debris)
			return true
		else:
			# Try to push the existing debris
			if push_debris(existing, direction, false):
				# Push succeeded, place scooped debris
				scooped_debris.grid_pos = release_pos
				register(scooped_debris)
				set_visual_targ_to_new_grid_pos(scooped_debris)
				return true
			else:
				# Can't push, release fails
				return false
	else:
		# Empty space, just place it
		scooped_debris.grid_pos = release_pos
		register(scooped_debris)
		set_visual_targ_to_new_grid_pos(scooped_debris)
		return true
