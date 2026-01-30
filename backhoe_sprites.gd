# === Backhoe.gd (pure visual component) ===
extends Node2D

const BACKHOE_CONFIG = {
	DirectionalCharacter.Facing.RIGHT: {
		"normal": {"offset": Vector2i(-1, 0)},
	},
	DirectionalCharacter.Facing.LEFT: {
		"normal": {"offset": Vector2i(1, 0)},
	},
	DirectionalCharacter.Facing.DOWN: {
		"normal": {"offset": Vector2i(0, -1)},
	},
	DirectionalCharacter.Facing.UP: {
		"normal": {"offset": Vector2i(0, 1)},
	}
}

var current_sprite: AnimatedSprite2D
var carried_debris: Entity = null  # Just for visual position updates

@onready var animations: Array[AnimatedSprite2D] = [$up, $down, $left, $right]

func update_backhoe(_player_pos: Vector2i, visual_state: DirectionalCharacter.Facing, _move_state: DirectionalCharacter.Facing):
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

func get_scoop_offset(player_facing: DirectionalCharacter.Facing) -> Vector2i:
	var config_key = "normal"
	return BACKHOE_CONFIG[player_facing][config_key]["offset"]

func is_carrying() -> bool:
	return carried_debris != null

# Play scoop animation and hide debris at the right frame
func play_scoop_animation(debris: Entity) -> void:
	carried_debris = debris
	debris.remove_from_group("debris")
	debris.scooped = true
	
	play_all_animations("scoop")
	await play_current_animation("scoop")
	
	debris.visible = false

# Play release animation and show debris at the right frame
func play_release_animation() -> void:
	if carried_debris == null:
		return
	
	play_all_animations("release")
	await play_current_animation("release")
	
	carried_debris.visible = true
	carried_debris.add_to_group("debris")
	carried_debris.scooped = false
	carried_debris = null
	
func play_no_dirt_animation() -> void:
	play_all_animations("scoop_no_dirt")
	play_current_animation("scoop_no_dirt")
# Update visual position of carried debris (call this when player moves)
func update_carried_debris_visual(land_tilemap: TileMapLayer, grid_pos: Vector2i):
	if carried_debris != null:
		carried_debris.grid_pos = grid_pos
		carried_debris.visual_pos = land_tilemap.map_to_local(grid_pos)
		carried_debris.visual_target = carried_debris.visual_pos

func reset():
	for anim in animations:
		anim.animation = "scoop"
		anim.set_frame_and_progress(0, 0)
		anim.reset()
	carried_debris = null

# === ANIMATION HELPERS (private) ===
func start_sinking():
	current_sprite.start_sinking()

func play_all_animations(anim_name: String):
	for anim in animations:
		if anim != current_sprite:
			anim.play(anim_name)

func play_current_animation(anim_name: String):
	current_sprite.play(anim_name)
	var second_to_last = current_sprite.sprite_frames.get_frame_count(anim_name) - 2
	await wait_for_frame(current_sprite, second_to_last)

func wait_for_frame(sprite: AnimatedSprite2D, frame_num: int):
	await sprite.frame_changed
	while sprite.frame < frame_num:
		await sprite.frame_changed
