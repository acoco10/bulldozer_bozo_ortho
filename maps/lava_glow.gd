extends TileMapLayer
@export var glow_speed: float = 2.0
@export var min_brightness: float = 0.8
@export var max_brightness: float = 1.3
@export var new_lava_brightness: float = 2.0
@export var new_lava_fade_time: float = 1.0
var time: float = 0.0
var new_lava_tiles: Dictionary = {}
var danger_mode: bool = false  # Add this flag

func _process(delta: float) -> void:
	time += delta * glow_speed
	
	# Base pulsing effect
	var pulse = (sin(time) + 1.0) / 2.0
	var brightness = lerp(min_brightness, max_brightness, pulse)
	
	# Apply red tint if in danger mode, otherwise normal white glow
	if danger_mode:
		modulate = Color(brightness, brightness * 0.5, brightness * 0.3, 1.0)
	else:
		modulate = Color(brightness, brightness, brightness, 1.0)
	
	# Update new lava fade timers
	var coords_to_remove = []
	for coord in new_lava_tiles.keys():
		new_lava_tiles[coord] -= delta
		if new_lava_tiles[coord] <= 0:
			coords_to_remove.append(coord)
	
	# Remove faded tiles
	for coord in coords_to_remove:
		new_lava_tiles.erase(coord)
		_remove_glow_sprite(coord)

func ten_turns_left() -> void:
	danger_mode = true

func add_new_lava(coords: Array) -> void:
	for coord in coords:
		new_lava_tiles[coord] = new_lava_fade_time
		_add_glow_sprite(coord)

func _add_glow_sprite(coord: Vector2i) -> void:
	var glow = ColorRect.new()
	glow.name = "Glow_" + str(coord)
	glow.size = tile_set.tile_size
	glow.position = map_to_local(coord) - tile_set.tile_size / 2.0
	glow.color = Color(1.0, 0.9, 0.6, 0.6)
	glow.modulate.a = 1.0
	add_child(glow)
	
	var tween = create_tween()
	tween.tween_property(glow, "modulate:a", 0.0, new_lava_fade_time)
	tween.tween_callback(glow.queue_free)

func _remove_glow_sprite(coord: Vector2i) -> void:
	var glow_name = "Glow_" + str(coord)
	if has_node(glow_name):
		get_node(glow_name).queue_free()
		
