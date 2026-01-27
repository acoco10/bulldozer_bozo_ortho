extends TileMapLayer

func _process(_delta: float) -> void:
	clear()
	for entity in get_tree().get_nodes_in_group("entities"):
			entity = entity as Entity
			for cell in entity.local_positions:
				set_cell(entity.grid_pos + cell, 0, Vector2i(2,0))
			set_cell(entity.grid_pos,0, Vector2i(2,0))
	
