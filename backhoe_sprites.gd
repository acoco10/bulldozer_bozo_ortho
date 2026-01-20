extends Node2D

const BACKHOE_CONFIG = {
	DirectionalCharacter.Facing.RIGHT: {
		"normal": {"node": "rightbackhoe", "offset": Vector2i(-1, 0)},
	},
	DirectionalCharacter.Facing.LEFT: {
		"normal": {"node": "leftbackhoe", "offset": Vector2i(1, 0)},
	},
	DirectionalCharacter.Facing.DOWN: {
		"normal": {"node": "downbackhoe", "offset": Vector2i(0, -1)},
	},
	DirectionalCharacter.Facing.UP: {
		"normal": {"node": "upbackhoe", "offset": Vector2i(0, 1)},
	}
}

var has_dirt: Entity = null
var dragged_tree: Entity = null 
var facing_at_tree_drag: DirectionalCharacter.Facing
var connection_index: int

func check_dragged_collision(direction: Vector2i) ->bool:
	if dragged_tree != null:
		for pos in dragged_tree.get_world_positions():
			for debris in get_tree().get_nodes_in_group("debris"):
				if debris == dragged_tree:
					continue
				if debris.occupies(pos + direction + dragged_tree.grid_pos):
					return true
	return false


func update_backhoe(player_pos: Vector2i, visual_state: DirectionalCharacter.Facing, move_state: DirectionalCharacter.Facing):
	
	# Show the correct one based on facing and reverse state
	var bulldozer_size = Vector2i(64,64)
	var backhoe_texture: Texture
	var offset := Vector2.ZERO
	
	match visual_state:
		DirectionalCharacter.Facing.LEFT:
			backhoe_texture = preload("res://art/backhoeRight.png")
			offset = Vector2(60, 0)
		
		DirectionalCharacter.Facing.RIGHT:
			backhoe_texture = preload("res://art/backhoeLeft.png")
			offset = Vector2(-60, 0)
		
		DirectionalCharacter.Facing.UP:
			backhoe_texture = preload("res://art/backhoeup.png")
			offset = Vector2(0, 16)
		
		DirectionalCharacter.Facing.DOWN:
			backhoe_texture = preload("res://art/backhoeFront.png")
			offset = Vector2(0, -43)
	
	$backhoe.texture = backhoe_texture
	$backhoe.position = offset
	
	var scoop_pos = get_backhoe_config_offset(player_pos, move_state)
	update_dirt_position(scoop_pos)
	
	if dragged_tree != null:
		if facing_at_tree_drag != visual_state:
			release_debris(scoop_pos, visual_state)
		else:
			update_dragged_tree_position(scoop_pos)
	
	
func update_input(dir: Vector2i, player_pos: Vector2i, visual_state: DirectionalCharacter.Facing):
	var scoop_pos = get_backhoe_config_offset(player_pos, visual_state)
	if dragged_tree != null:
		if check_dragged_collision(dir):
			release_debris(scoop_pos, visual_state)
		

func get_backhoe_config_offset(player_pos: Vector2i, player_facing:DirectionalCharacter.Facing) -> Vector2i:
	var config_key = "normal"
	var backhoe_data = BACKHOE_CONFIG[player_facing][config_key]
	
	# Get backhoe node and position to check
	return player_pos + backhoe_data["offset"]


func scoop_debris(player_pos: Vector2i, player_facing:DirectionalCharacter.Facing) -> bool:
	var scoop_pos = get_backhoe_config_offset(player_pos, player_facing)
	var res = try_scoop_at(scoop_pos, player_facing)
	if res:
		$backhoe/AnimationPlayer.play("backHoe")
	return res 
	
	
func release_debris(pos: Vector2i, facing:DirectionalCharacter.Facing)->bool:
	if has_dirt || dragged_tree:
		for debris in get_tree().get_nodes_in_group("debris"):
			if debris == has_dirt:
				continue
			if !debris.occupies(pos):
				continue
			if debris.split and debris.broken:
				has_dirt.recombine_debris(has_dirt, debris)
			elif debris.split:
				has_dirt.push(facing)
			else:
				return false 
		if has_dirt != null:		
			has_dirt.visible = true 
			has_dirt.add_to_group("debris")
		has_dirt = null 
		dragged_tree = null 
		return true 
	return false 
		
		

	
func try_scoop_at(pos: Vector2i, facing:DirectionalCharacter.Facing) -> bool:
	if has_dirt || dragged_tree:
		release_debris(pos, facing)
		return true
	else:
		return attatch_debris(pos, facing)
	

func attatch_debris(pos: Vector2i, facing:DirectionalCharacter.Facing):
	for debris in get_tree().get_nodes_in_group("debris"):
		if debris.occupies(pos):
			debris = debris as Entity
			if debris.broken:
				if debris.local_positions.size() > 1: #trees
					var world_pos = debris.get_world_positions()
					for pos_index in len(world_pos):
						if world_pos[pos_index] == pos:
							connection_index = pos_index
					dragged_tree = debris
					facing_at_tree_drag = facing
				else:
					has_dirt = debris
			if debris.split and !debris.broken:
				has_dirt = debris.back_hoe_break_up_debris() #be careful here, this returns a copy but the orignal debris should not be removed from group 
			
			if has_dirt != null:
				has_dirt.remove_from_group("debris")
				has_dirt.visible = false 
			return true
	return false 

func find_connection_point(grid_pos: Vector2i) -> int:
	# Find which local position of the tree is adjacent to the player
	var tree_world_positions = dragged_tree.get_world_positions()
	
	for i in tree_world_positions.size():
		# Check if this position is adjacent to player
		var diff = tree_world_positions[i] - grid_pos
		if diff.length() == 1:  # Manhattan distance of 1
			return i
	
	return 0  # Fallback
	
func update_dirt_position(dirt_pos: Vector2i):
	if has_dirt != null:
		has_dirt.grid_pos = dirt_pos
		
func update_dragged_tree_position(dirt_pos: Vector2i):
	if dragged_tree == null:
		return
	
	# Calculate where grid_pos should be based on connection point
	var connection_world_pos = dirt_pos
	var connection_local_pos = dragged_tree.local_positions[connection_index]
	
	# Grid pos = where connection point is in world - its local offset
	dragged_tree.grid_pos = connection_world_pos - connection_local_pos
	
func mirror_direction(dir: DirectionalCharacter.Facing)-> DirectionalCharacter.Facing:
	if dir == DirectionalCharacter.Facing.UP:
		return DirectionalCharacter.Facing.DOWN
	elif dir == DirectionalCharacter.Facing.DOWN:
		return DirectionalCharacter.Facing.UP
	elif dir == DirectionalCharacter.Facing.LEFT:
		return DirectionalCharacter.Facing.RIGHT
	elif dir == DirectionalCharacter.Facing.RIGHT:
		return DirectionalCharacter.Facing.LEFT
	return dir 
func set_backhoe_muddy(muddy: bool) -> void:
	var texture = preload("res://art/backhoeRightMud.png") if muddy else preload("res://art/backhoeRight.png")
	$rightbackhoe.texture = texture
	$leftbackhoe.texture = texture
	# Add other backhoe directions if needed
