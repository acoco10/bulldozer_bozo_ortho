extends Node2D

@onready var visual_fence_layer = $visualFences
@onready var collision_layer = $fences

var fenceTiles: Array[Vector2i] = [Vector2i(0,1), Vector2i(1,1)]

func _ready() -> void:
	await get_tree().create_timer(0.2).timeout
	for debris in get_tree().get_nodes_in_group("debris"):
		debris = debris as Entity
		debris.HitFence.connect(_on_fence_hit)
		debris.DebrisBrokenUp.connect(_on_debris_broken_up)
		
func _on_fence_hit(data):
	print("fence hit registered at", data.coords)
	
	var col_tile_at_hit = collision_layer.get_cell_atlas_coords(data.coords)
	var vis_tile_at_hit = visual_fence_layer.get_cell_atlas_coords(data.coords)
	print("collision layer has  tile type: %v" %col_tile_at_hit)
	print("visual layer has  tile type: %v" %vis_tile_at_hit)

	if  col_tile_at_hit in fenceTiles:
		print("playing animated fence in collision layer")
		collision_layer.set_cell(data.coords, 0, Vector2i(1,2))
		await get_tree().create_timer(0.4).timeout
		collision_layer.set_cell(data.coords, 0, col_tile_at_hit)

	elif vis_tile_at_hit in fenceTiles:
		print("playing animated fence at in visual layer")
		visual_fence_layer.set_cell(data.coords, 0, Vector2i(1,2))
		await get_tree().create_timer(0.4).timeout
		visual_fence_layer.set_cell(data.coords, 0, vis_tile_at_hit)

func _on_debris_broken_up():
	for debris in get_tree().get_nodes_in_group("debris"):
		debris = debris as Entity
		if !debris.HitFence.is_connected(_on_fence_hit):
			debris.HitFence.connect(_on_fence_hit)
			if !debris.DebrisBrokenUp.is_connected(_on_debris_broken_up):
				debris.DebrisBrokenUp.connect(_on_debris_broken_up)

	
