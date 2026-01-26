class_name tree 
extends Entity

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
func normalize_positions() -> void:
	var offset = local_positions[0]
	if offset != Vector2i.ZERO:
		grid_pos += offset
		for i in local_positions.size():
			local_positions[i] -= offset

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
