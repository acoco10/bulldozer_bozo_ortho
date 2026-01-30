extends Entity

@export var button: Button_Tile

func _ready() -> void:
	super._ready()
	if texture_path_name != "":
		var name = "res://art/mining_platform_%s.png" %texture_path_name
		$MiningPlatform.texture = load(name)

var player_parent
var player: Entity

func trigger_leave():
	print("triggering leave animation")
	await get_tree().create_timer(0.5).timeout
	for debris in get_tree().get_nodes_in_group("debris"):
		debris = debris as Debris
		if occupies(debris.grid_pos):
			debris.canned_animation = true 
			debris.reparent(self)
	player = get_tree().get_first_node_in_group("player")
	if occupies(player.grid_pos):
		if player_parent == null:
			player_parent = player.get_parent()
		print("player parent = ", player_parent)
		player.canned_animation = true 
		player.reparent(self)
	leave_animation()
	
func leave_animation():
	var tween = create_tween()
	var final_position = global_position + Vector2(-0, -1000)
	tween.tween_property(self, "global_position", final_position, 1)
	canned_animation = true 
	
	await  tween.finished
	await get_tree().create_timer(0.1).timeout
	player.canned_animation = false 
	player.reparent(player_parent)
	
