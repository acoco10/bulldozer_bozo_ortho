class_name  Debris
extends Entity

@onready var sprite = $Sprite2D
@export var Platform: Entity

var broken: bool = false
var cleaned_up: bool = false

var scooped: bool = false 
@export var breakable: bool 
@export var mineral: bool 
@export var pushable: bool 
@export var scoopable: bool
@export var push_power: bool

func _ready() -> void:
	
	super._ready()
	
	add_to_group("debris")
	if breakable:
		var unbroken_asset_path = "res://art/" + texture_path_name + ".png"
		var broken_asset_path = "res://art/" + texture_path_name + "_broken_up" + ".png"
		
		unbroken_texture = load(unbroken_asset_path)
		broken_up_texture = load(broken_asset_path)
		sprite.texture = unbroken_texture


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



# === STATE CHANGES ===

func set_broken_flags() -> void:
	broken = true
	pushable = true


func bulldoze(push_direction: DirectionalCharacter.Facing) -> Array:
	var res = break_up_debris(push_direction)
	set_broken_flags()
	$Sprite2D.texture = broken_up_texture
	
	return res
	
func push(push_direction: DirectionalCharacter.Facing, push_power: bool = false) -> bool:
	if !pushable and !push_power:
		print("player cant move because colliding with non pushable")
		return false
	
	var push_vec = get_push_vector(push_direction)
	var world_positions = get_world_positions()
	var target_pos = grid_pos + push_vec
		
	if fence_at(target_pos):
		grid_pos = target_pos
		flash_and_free(self)
		return true 
		
	if has_solid_debris_at(target_pos):
		return false 
	push_debris_at(target_pos, push_direction)
	grid_pos = target_pos

	return true

func recombine_debris(existing_debris: Entity, moving_debris: Entity) -> void:
	if !existing_debris.broken or !moving_debris.broken:
		return
	existing_debris.sprite.texture = unbroken_texture
	existing_debris.broken = false
	existing_debris.pushable = false 
	moving_debris.queue_free()

func push_debris_at(target: Vector2i, push_direction: DirectionalCharacter.Facing) -> void:
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris == self:
			continue
		if not debris.occupies(target):
			continue
		
		if pushable and debris.pushable:
			# Check if there's a chain that ends at an obstacle
			var chain = get_push_chain(debris, push_direction)
			
			if chain.size() > 0:
				var push_vec = get_push_vector(push_direction)
				var obstacle_pos = chain[-1].grid_pos + push_vec
				
				if has_solid_debris_at(obstacle_pos, chain):
					# Recombine last two in chain
					if chain.size() >= 2: 
						var last = chain.pop_back()
						var second_last = chain.pop_back()
						recombine_debris(last, second_last)
				if chain.size() > 0:
					for chained_debris in chain:
						chained_debris.push(push_direction)
				return 
						
		debris.push(push_direction)


func get_push_chain(start_debris: Entity, push_direction: DirectionalCharacter.Facing) -> Array[Entity]:
	var chain: Array[Entity] = [self, start_debris]
	var push_vec = get_push_vector(push_direction)
	var current = start_debris
	var next_pos = current.grid_pos + push_vec
	var next_debris = find_debris_at(next_pos)
	
	while next_debris != null:
		chain.append(next_debris)
		next_pos = next_pos + push_vec
		next_debris = find_debris_at(next_pos)
	
	return chain
			
func resolve_entity_interaction_after_broken_up(newly_broken: Entity, target: Vector2i, break_direction: DirectionalCharacter.Facing) -> Vector2i:
	if fence_at(target):
		flash_and_free(self)
		return target
	for debris in get_tree().get_nodes_in_group("debris"):
		debris = debris as Entity
		if debris == newly_broken:
			continue
		if not debris.occupies(target):
			continue
		if !debris.broken:
			#if would land on invalid tile push to next tile and recheck interactions
			target = target + get_push_vector(break_direction)
			return resolve_entity_interaction_after_broken_up(newly_broken, target, break_direction)
		if debris.broken:
			recombine_debris(debris, newly_broken)
			return newly_broken.grid_pos
	return target


func back_hoe_break_up_debris() -> Entity:
	if !breakable || broken:
		return null
	#breaks a debris into two in place and returns the copy for backhoe to carry rather than pushing apart
	else:
		set_broken_flags()
		self.sprite.texture = broken_up_texture
		
		var copy = self.duplicate()
		get_parent().add_child(copy)
		copy._ready()
		copy.set_broken_flags()
		copy.sprite.texture = broken_up_texture
			
		return copy 

func break_up_debris(push_direction: DirectionalCharacter.Facing) -> Array[DebrisAction]:
	set_broken_flags()
	sprite.texture = broken_up_texture
	var actions: Array[DebrisAction] = []
	var copy = self.duplicate()
	get_parent().add_child(copy)
	copy._ready()
	copy.set_broken_flags()
	copy.sprite.texture = broken_up_texture
	

	var push_vec = Vector2i.ZERO
	var copy_push_vec = Vector2i.ZERO

	if push_direction == DirectionalCharacter.Facing.UP or push_direction == DirectionalCharacter.Facing.DOWN:
		push_vec = Vector2i(-1, 0)
		copy_push_vec = Vector2i(1, 0)
	else:
		push_vec = Vector2i(0, 1)
		copy_push_vec = Vector2i(0, -1)
		
	var new_pos = grid_pos+push_vec
	var new_copy_pos = copy.grid_pos + copy_push_vec

	while has_solid_debris_at(new_pos):
		new_pos += push_vec
		
	while copy.has_solid_debris_at(new_copy_pos):
		new_copy_pos += copy_push_vec
		
	var recombine = has_split_debris_at(new_pos)
	var recombine_copy = copy.has_split_debris_at(new_copy_pos)
	
	if recombine:
		recombine_debris(recombine, self)
	
	if recombine_copy:
		recombine_debris(recombine_copy, copy)
	
	grid_pos = new_pos
	copy.grid_pos = new_copy_pos
	copy.visual_pos = visual_pos
		
	return actions
