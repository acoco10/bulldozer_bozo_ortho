class_name TurnTracker
extends Node

class TurnData:
	var turn_number: int
	var player_moved: bool
	var player_pos: Vector2i
	var player_prev_pos: Vector2i
	var player_action: String  # "push", "dig", "move", "wait"
	var lava_spread: bool
	var entities_moved: Array[Vector2i] = []
	var entities_broken: Array[Vector2i] = []
	var button_pressed: bool = false
	
	func _init(turn: int):
		turn_number = turn
