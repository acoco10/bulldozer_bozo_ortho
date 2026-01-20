class_name DebrisAction
extends RefCounted

enum ActionType {
	NONE,
	PUSHED,           # Debris moved normally
	RECOMBINED,       # Debris recombined with another
	RECOMBINED_INTO,  # This debris had another recombine into it
	HIT_FENCE,        # Debris bounced off fence
	PIVOTED,          # Multi-tile debris rotated
	UPROOTED,         # Tree changed from standing to fallen
	BROKE_APART       # Single debris split into two
}

var action: ActionType = ActionType.NONE
var debris: Entity
var other_debris: Entity = null  # For recombination
var push_direction: DirectionalCharacter.Facing
var from_pos: Vector2i
var to_pos: Vector2i
var fence_coord: Vector2i = Vector2i(-1, -1)

func _init(
	_debris: Entity,
	_action: ActionType,
	_push_direction: DirectionalCharacter.Facing,
	_from_pos: Vector2i,
	_to_pos: Vector2i
) -> void:
	debris = _debris
	action = _action
	push_direction = _push_direction
	from_pos = _from_pos
	to_pos = _to_pos

# Helper constructors
static func pushed(debris: Entity, direction: DirectionalCharacter.Facing, from: Vector2i, to: Vector2i) -> DebrisAction:
	return DebrisAction.new(debris, ActionType.PUSHED, direction, from, to)

static func recombined(debris1: Entity, debris2: Entity, direction: DirectionalCharacter.Facing) -> DebrisAction:
	var action = DebrisAction.new(debris1, ActionType.RECOMBINED, direction, debris1.grid_pos, debris2.grid_pos)
	action.other_debris = debris2
	return action

static func hit_fence(debris: Entity, direction: DirectionalCharacter.Facing, fence_pos: Vector2i) -> DebrisAction:
	var action = DebrisAction.new(debris, ActionType.HIT_FENCE, direction, debris.grid_pos, debris.grid_pos)
	action.fence_coord = fence_pos
	return action

static func pivoted(debris: Entity, direction: DirectionalCharacter.Facing, from: Vector2i, to: Vector2i) -> DebrisAction:
	return DebrisAction.new(debris, ActionType.PIVOTED, direction, from, to)

static func uprooted(debris: Entity, direction: DirectionalCharacter.Facing, from: Vector2i, to: Vector2i) -> DebrisAction:
	return DebrisAction.new(debris, ActionType.UPROOTED, direction, from, to)

static func broke_apart(debris: Entity, direction: DirectionalCharacter.Facing) -> DebrisAction:
	return DebrisAction.new(debris, ActionType.BROKE_APART, direction, debris.grid_pos, debris.grid_pos)
