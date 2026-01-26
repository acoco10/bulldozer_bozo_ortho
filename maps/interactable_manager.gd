
class_name EntityGrid
extends Node2D

var entities: Dictionary[Vector2i, Entity]

func push_entity(entity: Entity, direction: DirectionalCharacter.Facing) -> bool:
	var target = entity.grid_pos + get_push_vector(direction)
	

func move(entity: Entity, new_pos: Vector2i):
	entities.erase(entity.grid_pos)
	entity.grid_pos = new_pos
	entities[new_pos] = entity


func get_push_vector(push_direction: DirectionalCharacter.Facing) -> Vector2i:
	match push_direction:
		DirectionalCharacter.Facing.UP:
			return Vector2i(0, -1)
		DirectionalCharacter.Facing.DOWN:
			return Vector2i(0, 1)
		DirectionalCharacter.Facing.LEFT:
			return Vector2i(-1, 0)
		DirectionalCharacter.Facing.RIGHT:
			return Vector2i(1, 0)
	return Vector2i.ZERO
