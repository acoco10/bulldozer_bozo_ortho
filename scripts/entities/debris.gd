class_name  Debris
extends Entity

@onready var sprite: Sprite2D
@export var Platform: Entity

var cleaned_up: bool = false

var scooped: bool = false 
@export var broken: bool = false
@export var breakable: bool 
@export var mineral: bool 
@export var pushable: bool 
@export var scoopable: bool
@export var push_power: bool

signal Broken_up 

func _ready() -> void:
	
	super._ready()
	if has_node("Sprite2D"):
		sprite = $Sprite2D
	if breakable:
		var unbroken_asset_path = "res://art/interactable_objects/" + texture_path_name + ".png"
		var broken_asset_path = "res://art/interactable_objects/" + texture_path_name + "_broken_up" + ".png"
		
		unbroken_texture = load(unbroken_asset_path)
		broken_up_texture = load(broken_asset_path)
		sprite.texture = unbroken_texture
		if broken: 
			set_broken_flags()
			sprite.texture = broken_up_texture

func set_free_after_move():
	free_after_move = true 

func set_broken_flags() -> void:
	if !broken:
		Broken_up.emit()
	broken = true
	pushable = true

func clear_broken_flags() -> void:
	broken = false 
	pushable = false 



			
