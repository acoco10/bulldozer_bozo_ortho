extends Entity

@onready var visual_fence_layer = $visualFences
@onready var collision_layer = $fences

var fenceTiles: Array[Vector2i] = [Vector2i(0,1), Vector2i(1,1)]

func _ready() -> void:
	await get_tree().create_timer(0.2).timeout
	for debris in get_tree().get_nodes_in_group("debris"):
		debris = debris as Entity
		
		


	
