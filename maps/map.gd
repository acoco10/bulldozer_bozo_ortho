class_name map 
extends Node2D

@onready var fences = $tilemap/fences
@onready var land_tiles = $tilemap/tiles
@export var Player_start_pos: Marker2D
@export var elevator_platform: Node2D
@export var timeLimitMinutes: int
@export var timeLimitHours: int
@export var n_minerals: int
@export var ent_grid: EntityGrid
@export var button: elevator_button


const LAVA_ATLAS_COORDS = Vector2i(4, 0)
const DIRECTIONS = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]

func _ready() -> void:
	for child in get_children():
		var ent = child as Debris
		if ent:
			n_minerals +=2

func _enter_map_scene():
	$"interactables/elevator_platform".enter_animation()
	for entity_id in $interactables.entities:
		var entity = $interactables.entities[entity_id]
		if entity.enter_with_elevator:
			entity.enter_animation()


func is_tile_bordering_lava(tile_pos: Vector2i) -> bool:
	for direction in DIRECTIONS:
		var neighbor_pos = tile_pos + direction
		var lava_tile = fences.get_cell_atlas_coords(neighbor_pos)
		if lava_tile == LAVA_ATLAS_COORDS:
			return true
	return false

func advance_lava(probability_of_lava: float = 1.0):
	var tiles_to_convert = []
	
	# Check all land tiles
	for tile_pos in land_tiles.get_used_cells():
		# Skip if already lava
		if fences.get_cell_atlas_coords(tile_pos) == LAVA_ATLAS_COORDS:
			continue
		
		# Check if borders lava
		if is_tile_bordering_lava(tile_pos):
			# Roll probability
			if randf() <= probability_of_lava and !elevator_platform.occupies(tile_pos):
				tiles_to_convert.append(tile_pos)
	
	# Convert tiles to lava
	for tile_pos in tiles_to_convert:
		fences.set_cell(tile_pos, 0, LAVA_ATLAS_COORDS)
	fences.add_new_lava(tiles_to_convert)
	

func leave():
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	var final_position = global_position + Vector2(0, 1000)
	tween.tween_property(self, "global_position", final_position, 2)
	
