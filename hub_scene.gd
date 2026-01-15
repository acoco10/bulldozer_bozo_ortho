extends Node2D

@onready var dozerScene = $dozer
var need_new_contract: bool 

@onready var canvas_layer = $CanvasLayer
var day1: bool = true

func _ready() -> void:
	$CanvasLayer/Contract.connect("contract_accepted", _on_contract_accepted)
	$CanvasLayer/apartment_scene.connect("next_day", _on_next_day)
	$CanvasLayer/apartment_scene.process_mode = Node.PROCESS_MODE_DISABLED
	dozerScene.connect("end_of_day", _on_end_of_day)
	dozerScene.visible = false 
	dozerScene.process_mode = Node.PROCESS_MODE_DISABLED


func _on_contract_accepted() -> void:
	dozerScene.visible = true
	dozerScene.process_mode = PROCESS_MODE_INHERIT
	if !day1:
		dozerScene.on_enter()
	$CanvasLayer/Contract.visible = false 
	$CanvasLayer/Contract.process_mode = PROCESS_MODE_DISABLED
	canvas_layer.wipe_from_black(0.5)
	day1 = false 

	

func _on_end_of_day(data: Dictionary) -> void: 
	print("end of day recieved")
	print("contract completed = ", data.contract_completed)
	need_new_contract = data.contract_completed
	canvas_layer.wipe_from_black(0.5)
	$CanvasLayer/apartment_scene.process_mode = Node.PROCESS_MODE_INHERIT
	dozerScene.visible = false
	dozerScene.process_mode = PROCESS_MODE_DISABLED
	$CanvasLayer/apartment_scene.visible = true 


func _on_next_day() -> void: 
	print("next day recieved")
	$CanvasLayer/apartment_scene.process_mode = Node.PROCESS_MODE_DISABLED
	$CanvasLayer/apartment_scene.visible = false 
	if need_new_contract:
		$CanvasLayer/Contract.process_mode = PROCESS_MODE_INHERIT
		$CanvasLayer/Contract.visible = true 
	else:
		dozerScene.visible = true
		dozerScene.process_mode = PROCESS_MODE_INHERIT
		dozerScene.on_enter()
