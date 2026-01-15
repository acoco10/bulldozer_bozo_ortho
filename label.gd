extends Label
@export var Player: DirectionalCharacter
@export var GameTracker: Node2D
@export var timerNode: timer

func _process(_delta: float) -> void:
	text = "Turns: %d\nDebris Cleaned: %d\n %s" %[Player.turns, GameTracker.cleanedDebris, timerNode.get_time_string()]
