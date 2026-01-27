class_name Button_Tile
extends  Entity
var is_pressed :bool = false 
var turn_countdown: int = 1
signal button_pressed

@export var countdown_label = Label

@onready var pressed_texture = preload("res://art/button_pressed.png")
@onready var un_pressed_texture = preload("res://art/button.png")

func _ready() -> void:
	super._ready()
	add_to_group("button")

func pressed():
	$Button.visible = false
	$AnimatedSprite2D.visible = true 
	is_pressed = true 
	$Button.texture = pressed_texture
	print("Button Pressed By Player")
	button_pressed.emit()
	
func _process(_delta: float) -> void:
	if is_pressed:
		var still_pressed = false 
		var player = get_tree().get_first_node_in_group("player")
		if player.occupies(grid_pos):
			still_pressed = true 
		else:
			for ent in get_tree().get_nodes_in_group("entities"):
				ent = ent as Entity
				if ent == self:
					continue 
				if ent.occupies(grid_pos):
					still_pressed = true 
					break 
		if !still_pressed:
			is_pressed = false 
			$Button.texture = un_pressed_texture

func countdown():
	$AnimatedSprite2D.set_frame_and_progress(turn_countdown, 0)
	turn_countdown+=1

func force_complete_countdown():
	$AnimatedSprite2D.set_frame_and_progress(3, 0)	
