extends TileMapLayer

func _process(delta: float) -> void:
	clear()
	for debris in get_tree().get_nodes_in_group("debris"):
			debris = debris as Entity
			for cell in debris.local_positions:
				set_cell(debris.grid_pos + cell, 0, Vector2i(2,0))
	
			set_cell(debris.grid_pos,0, Vector2i(2,0))
		
