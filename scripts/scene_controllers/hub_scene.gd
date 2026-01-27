extends Node2D

@onready var dozerScene = $dozer
@onready var canvas_layer = $CanvasLayer
@onready var contract = $CanvasLayer/contract
@onready var results = $CanvasLayer/results_panel
@onready var entrance = $entrance

var need_new_contract: bool 
var day1: bool = true
var lost: bool = false 

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.key_label == KEY_R:
			_on_reset()
			
			
func _ready() -> void:
	#signals:
	results.connect("next_day", _on_next_day)
	dozerScene.connect("end_of_day", _on_end_of_day)
	dozerScene.connect("reset", _on_reset)
	entrance.connect("leave_scene", _on_enter)
	
	untrigger_results_scene()
	untrigger_dozer_scene()

func _on_enter():
	entrance.queue_free()
	trigger_dozer_scene()

func _on_reset():
	get_tree().reload_current_scene()
	
func _on_end_of_day(data: Dictionary) -> void: 
	print("end of day recieved")	
	lost = data.lost 
	results.update_results(data.debris_harvested, data.debris_available, data.time_remaining_minutes, data.lost)
	trigger_results_scene()
	untrigger_dozer_scene()


func _on_next_day() -> void: 
	untrigger_results_scene()
	trigger_dozer_scene()

func trigger_dozer_scene() -> void:
	if !day1:
		dozerScene.on_enter(lost)
		lost = false
	dozerScene.first_enter()
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
