extends Node2D

@onready var dozerScene = $dozer
@onready var canvas_layer = $CanvasLayer
@onready var contract = $CanvasLayer/contract
@onready var results = $CanvasLayer/results_panel

var need_new_contract: bool 
var day1: bool = true
var lost: bool = false 
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.key_label == KEY_R:
			get_tree().reload_current_scene()
			
			
func _ready() -> void:
	#signals:
	contract.connect("contract_accepted", _on_contract_accepted)
	results.connect("next_day", _on_next_day)
	dozerScene.connect("end_of_day", _on_end_of_day)
	
	untrigger_results_scene()
	untrigger_dozer_scene()
	trigger_contract_scene()


func _on_contract_accepted() -> void:
	trigger_dozer_scene()
	untrigger_contract_scene()
	
func _on_end_of_day(data: Dictionary) -> void: 
	print("end of day recieved")	
	lost = data.lost 
	results.update_results(data.debris_harvested, data.debris_available, data.time_remaining_minutes, data.lost)
	trigger_results_scene()
	untrigger_dozer_scene()


func _on_next_day() -> void: 
	print("next day recieved")
	untrigger_results_scene()
	trigger_contract_scene()

func trigger_dozer_scene() -> void:
	if !day1:
		dozerScene.on_enter(lost)
		lost = false
	day1 = false 
	dozerScene.camera.enabled = true 
	dozerScene.visible = true
	dozerScene.process_mode = PROCESS_MODE_INHERIT
	
func untrigger_dozer_scene() -> void:
	dozerScene.camera.enabled = false 
	dozerScene.visible = false
	dozerScene.process_mode = PROCESS_MODE_DISABLED
	
func trigger_results_scene() -> void:
	results.process_mode = Node.PROCESS_MODE_INHERIT
	results.visible = true 

func untrigger_results_scene() -> void:
	results.process_mode = Node.PROCESS_MODE_DISABLED
	results.visible = false

func trigger_contract_scene() -> void:
	contract.process_mode = PROCESS_MODE_INHERIT
	contract.visible = true 
	
func untrigger_contract_scene() -> void:
	contract.visible = false 
	contract.process_mode = PROCESS_MODE_DISABLED	
