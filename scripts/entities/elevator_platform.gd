class_name Elevator
extends Entity

@export var button: elevator_button

func _ready() -> void:
	super._ready()
	if texture_path_name != "":
		var map_specific_texture_name = "res://art/mining_platforms/mining_platform_%s.png" %texture_path_name
		$MiningPlatform.texture = load(map_specific_texture_name)

#temp stores parent for leave animation 
var player_parent
var local_player: Entity

func trigger_leave(current_player: DirectionalCharacter):
	await get_tree().create_timer(0.5).timeout

	local_player = current_player
	player_parent = current_player.get_parent()
	if occupies(local_player.grid_pos):
		print("player parent = ", player_parent)
		local_player.canned_animation = true 
		local_player.reparent(self)
	leave_animation()
	
func leave_animation():
	var tween = create_tween()
	var final_position = global_position + Vector2(-0, -1000)
	tween.tween_property(self, "global_position", final_position, 1)
	canned_animation = true 
	await  tween.finished
	await get_tree().create_timer(0.1).timeout
	local_player.canned_animation = false 
	local_player.reparent(player_parent)
	
