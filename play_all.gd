extends Node2D


signal leave_scene

func _ready() -> void:
	for child in get_children():
		if child is AnimatedSprite2D:
			
			child.speed_scale = 1.0 + randf()*2.3 

			child.play()



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		for child in get_children():
			if child is AnimatedSprite2D:
				var top_speed = 7 + randf() *5
				var tween = create_tween()
				tween.tween_property(child, "speed_scale", top_speed, 1.0)  # Speed up to 3x over 1.6 seconds
				
				
				
		await get_tree().create_timer(1.0).timeout
		leave_scene.emit()
