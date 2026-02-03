class_name elevator_button 
extends Entity
signal button_press

var pressed: bool = false

func _ready() -> void:
	pass

func press():
	if !pressed:
		$AnimatedSprite2D.play()
		pressed = true 
		button_press.emit()
