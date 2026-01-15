class_name map 
extends Node2D

@onready var fences = $tilemap/fences
@export var Player_start_pos: Marker2D


func _ready() -> void:
	for child in get_children():
		var ent = child as Entity
		if ent:
			ent.tilemap_fences_layer = fences
			ent.tilemap = $tilemap/tiles
