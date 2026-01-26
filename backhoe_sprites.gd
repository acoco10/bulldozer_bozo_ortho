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

var current_sprite: AnimatedSprite2D

var has_dirt: Entity = null
var released_dirt: Entity = null 

@onready var animations: Array[AnimatedSprite2D] = [$up, $down, $left, $right]

func update_backhoe(player_pos: Vector2i, visual_state: DirectionalCharacter.Facing, move_state: DirectionalCharacter.Facing):
	

	for anim in animations:
		anim.visible = false
		
	match visual_state:
		DirectionalCharacter.Facing.LEFT:
			current_sprite = $left
			$left.visible = true 
		DirectionalCharacter.Facing.RIGHT:
			current_sprite = $right
			$right.visible = true 
		DirectionalCharacter.Facing.UP:
			current_sprite = $up
			$up.visible = true
		DirectionalCharacter.Facing.DOWN:
			current_sprite = $down
			$down.visible = true 

	
	var scoop_pos = get_backhoe_config_offset(player_pos, move_state)
	update_dirt_position(scoop_pos)
	
		

func get_backhoe_config_offset(player_pos: Vector2i, player_facing:DirectionalCharacter.Facing) -> Vector2i:
	var config_key = "normal"
	var backhoe_data = BACKHOE_CONFIG[player_facing][config_key]
	
	# Get backhoe node and position to check
	return player_pos + backhoe_data["offset"]


func scoop_debris(player_pos: Vector2i, player_facing:DirectionalCharacter.Facing) -> String:
	var scoop_pos = get_backhoe_config_offset(player_pos, player_facing)
	var res = try_scoop_at(scoop_pos, player_facing)
	if res != "na":
		#play all to keep synched only current sprite should use await asynch timing
		for anim in animations:
			if anim != current_sprite:
				match res:
					"scooped":
						anim.play("scoop")
					"released":
						anim.play("release")
		match res:
			"scooped":
				current_sprite.play("scoop")
				scoop_debris_async()
				if has_dirt.push_power:
					return "push_power_scooped"
				else:
					return res 
			"released":
				current_sprite.play("release")
				release_debris_async(scoop_pos, player_facing)
				return res
	return ""
	
func wait_for_frame(sprite: AnimatedSprite2D, frame_num: int):
	await sprite.frame_changed
	while sprite.frame < frame_num:
		await sprite.frame_changed

func reset():
	for anim in animations:
		anim.animation = "scoop"
		anim.set_frame_and_progress(0,0)

func scoop_debris_async():
	var second_to_last = current_sprite.sprite_frames.get_frame_count("scoop") - 2
	await wait_for_frame(current_sprite, second_to_last)
	has_dirt.visible = false
	
func release_debris_async(scoop_pos: Vector2i, player_facing:DirectionalCharacter.Facing ):
	var second_to_last = current_sprite.sprite_frames.get_frame_count("release") - 2
	await wait_for_frame(current_sprite, second_to_last)
	release_debris(scoop_pos, player_facing)
	
func release_debris(pos: Vector2i, facing:DirectionalCharacter.Facing)->bool:
	if has_dirt:
		update_dirt_position(pos)
		for debris in get_tree().get_nodes_in_group("debris"):
			if debris == has_dirt:
				continue
			if !debris.occupies(pos):
				continue
			if debris.broken:
				has_dirt.recombine_debris(has_dirt, debris)
			elif !debris.broken:
				has_dirt.push(facing)
		has_dirt.visible = true 
		has_dirt.add_to_group("debris")
		has_dirt.scooped = false 
		has_dirt = null 
		return true 
	return false 
	
func try_scoop_at(pos: Vector2i, facing:DirectionalCharacter.Facing) -> String:
	if has_dirt:
		return "released"
	else:
		if attatch_debris(pos, facing):
			return "scooped"
		else:
			return "na"
	

func attatch_debris(pos: Vector2i, facing:DirectionalCharacter.Facing):
	for debris in get_tree().get_nodes_in_group("debris"):
		debris = debris as Debris
		if !debris.occupies(pos):
			continue
		if debris.breakable:
			scoop_breakable_debris(debris)
		elif  debris.scoopable:
			has_dirt = debris
		if has_dirt != null:
			has_dirt.scooped = true 
			has_dirt.remove_from_group("debris")
		return true
	return false 

func scoop_breakable_debris(debris: Debris):
	if debris.broken:
		has_dirt = debris
	if !debris.broken:
		has_dirt = debris.back_hoe_break_up_debris() 
		#be careful here, this returns a copy but the orignal debris should not be removed from group 
		
func update_dirt_position(dirt_pos: Vector2i):
	if has_dirt != null:
		has_dirt.grid_pos = dirt_pos
		has_dirt.sync_position_to_grid_pos()
		
	
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
	
	# Add other backhoe directions if needed
