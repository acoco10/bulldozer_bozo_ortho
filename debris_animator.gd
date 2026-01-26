class_name DebrisAnimator
extends Node

const PUSH_DURATION = 0.2
const BOUNCE_DURATION = 0.3

@onready var tilemap: TileMapLayer  # Reference to your tilemap for world positions

func animate_action_sequence(actions: Array[DebrisAction]):
	for action in actions:
		await animate_action(action)

func animate_action(action: DebrisAction):
	match action.action:
		DebrisAction.ActionType.PUSHED:
			await animate_push(action)
		DebrisAction.ActionType.HIT_FENCE:
			await animate_fence_hit(action)
		_:
			# Skip other action types for now
			pass

# ===== PUSH ANIMATION =====
func animate_push(action: DebrisAction):
	var debris = action.debris
	var from_world = tilemap.map_to_local(action.from_pos)
	var to_world = tilemap.map_to_local(action.to_pos)
	
	# Slide tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(debris, "visual_pos", to_world, PUSH_DURATION)
	
	# Slight rotation wobble
	var wobble_tween = create_tween()
	wobble_tween.tween_property(debris, "rotation_degrees", 3.0, PUSH_DURATION / 2)
	wobble_tween.tween_property(debris, "rotation_degrees", 0.0, PUSH_DURATION / 2)
	
	await tween.finished

# ===== FENCE HIT ANIMATION =====
func animate_fence_hit(action: DebrisAction):
	action.debris.flash_and_free(action.debris)

# ===== HELPERS =====
func get_direction_vector(facing: DirectionalCharacter.Facing) -> Vector2:
	match facing:
		DirectionalCharacter.Facing.UP:
			return Vector2(0, -1)
		DirectionalCharacter.Facing.DOWN:
			return Vector2(0, 1)
		DirectionalCharacter.Facing.LEFT:
			return Vector2(-1, 0)
		DirectionalCharacter.Facing.RIGHT:
			return Vector2(1, 0)
	return Vector2.ZERO
