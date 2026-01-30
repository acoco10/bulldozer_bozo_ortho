extends Node2D

@onready var results_panel = $CanvasLayer/results_panel


func _ready():
	results_panel.update_results(6, 6, 2, false)
