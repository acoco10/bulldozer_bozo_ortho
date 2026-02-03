extends Control

signal Continue
signal Retry

@onready var feed_back_text = $results_panel/MarginContainer/VBoxContainer/feedback_text
@onready var rank = $results_panel/MarginContainer/VBoxContainer/rank
@onready var demerit_sprites :Array = [$results_panel/MarginContainer/VBoxContainer/HBoxContainer/Demerit,  $results_panel/MarginContainer/VBoxContainer/HBoxContainer/Demerit2]
@onready var retry_token_sprites: Array = [$results_panel/MarginContainer/VBoxContainer/HBoxContainer/RetryToken,  $results_panel/MarginContainer/VBoxContainer/HBoxContainer/RetryToken2, $results_panel/MarginContainer/VBoxContainer/HBoxContainer/RetryToken3]
@onready var retry_token_button: Button = $results_panel/retry_button
@onready var continue_button: Button = $results_panel/main_button
@onready var buttons: Array[Button] = [continue_button, retry_token_button]

var but_index: int = 0 
var rank_feedback = {
	"A": "Excellent Work Citizen #9243!",
	"B": "Acceptable Effort Citizen #9243.",
	"C": "Below Standards Citizen #9990.
	Demerit Recieved."
}

var demerit_msg = "Maximum demerits recieved. Thank you for your service Citizen #9243"

var death_msg = "Citizen #9243 expired on mission"
# Track if rank is currently cycling
var is_cycling = false
var calculated_rank = ""
var cycle_timer = 0.0
var lost: bool 

var demerits: int
var retry_tokens: int 

var new_token_flash: Tween
const CYCLE_DURATION = 1.0  # 1 second

func on_enter():
	pass
func _ready() -> void:
	continue_button.pressed.connect(on_continue)
	retry_token_button.pressed.connect(on_retry)

func on_continue():
	if new_token_flash != null: 
		new_token_flash.kill()
	Continue.emit()
	
func on_retry():
	if new_token_flash.is_running():
		new_token_flash.kill()
	Retry.emit() 
	update_sprite_array(retry_token_sprites, retry_tokens -1, false)
	
func _process(delta: float) -> void:
	if is_cycling:
		cycle_timer -= delta
		if cycle_timer <= 0.0:
			_on_end_rank_cycle()
			
func update_results(data: Dictionary, citizen_number_current: int):
	update_citizen_number(citizen_number_current)

	var debris_retrieved: int = data["debris_harvested"]
	var debris_possible: int = data["debris_available"]
	var minutes_remaining: int = data["time_remaining_minutes"]
	var died: bool = data["died"]
	var demerit_loss: bool = data["demerit_loss"]
	
	if died or demerit_loss:
		lost = true 
	
	demerits = data["demerits"]
	retry_tokens = data["retry_tokens"]
	calculated_rank = data["rank"]
	


	if retry_tokens == 0:
		retry_token_button.disabled = true 
	else:
		retry_token_button.disabled = false


	if died:
		$results_panel/MarginContainer/VBoxContainer/rank.visible = false
		$results_panel/MarginContainer/VBoxContainer/outcome.visible = false 
		$results_panel/MarginContainer/VBoxContainer/time_remaining.visible = false 
		$results_panel/MarginContainer/VBoxContainer/title.visible = false 
		$results_panel/MarginContainer/VBoxContainer/you_lost.text = death_msg
		$results_panel/MarginContainer/VBoxContainer/you_lost.visible = true 
		feed_back_text.visible = false
		await get_tree().create_timer(0.2).timeout
		continue_button.grab_focus()
		return 
	if demerit_loss:
		$results_panel/MarginContainer/VBoxContainer/rank.visible = false
		$results_panel/MarginContainer/VBoxContainer/outcome.visible = false 
		$results_panel/MarginContainer/VBoxContainer/time_remaining.visible = false 
		$results_panel/MarginContainer/VBoxContainer/title.visible = false 
		$results_panel/MarginContainer/VBoxContainer/you_lost.visible = false
		feed_back_text.text = demerit_msg
		feed_back_text.visible = true 
		await get_tree().create_timer(0.2).timeout
		continue_button.grab_focus()
		return 
		#trigger demerit scene
	var time_string = get_time_string(minutes_remaining)
	feed_back_text.visible = false
	
	$results_panel/MarginContainer/VBoxContainer/outcome.visible = true
	$results_panel/MarginContainer/VBoxContainer/time_remaining.visible = true
	$results_panel/MarginContainer/VBoxContainer/title.visible = true
	$results_panel/MarginContainer/VBoxContainer/outcome.text = "Harvested %d of %d material" %[debris_retrieved, debris_possible]
	$results_panel/MarginContainer/VBoxContainer/time_remaining.text = "Time Remaining = %s" %time_string
	$results_panel/MarginContainer/VBoxContainer/you_lost.visible = false

	# Start cycling animation with timer
	is_cycling = true
	cycle_timer = CYCLE_DURATION
	rank.start_cycling()		


func update_citizen_number(citizen_number: int):
	rank_feedback["A"] = "Excellent Work Citizen #%d! You have been awarded a retry token for your outstanding performance." % citizen_number
	if retry_tokens == 3:
		rank_feedback["A"] = "Excellent Work Citizen #%d! You already have the maximum number of retry tokens." % citizen_number
	rank_feedback["B"] = "Acceptable Effort Citizen #%d." % citizen_number
	rank_feedback["C"] = "Below Standards Citizen #%d. Demerit Recieved." % citizen_number
	demerit_msg = "Maximum demerits recieved. Thank you for your service Citizen #%d." %citizen_number
	death_msg  = "Citizen #%d expired on mission. We thank Citizen #%d for their service." %[citizen_number, citizen_number]

func focus_button():
	buttons[but_index].grab_focus()

func get_rank_message(calced_rank: String) -> String:
	return rank_feedback.get(calced_rank, "Error: Invalid Rank")


func _on_end_rank_cycle():
	reveal_rank()
	focus_button()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		if is_cycling:
			_on_end_rank_cycle()
		else:
			if event.is_action_pressed("ui_up"):
				cycle_buttons(true)
			if event.is_action_pressed("ui_down"):
				cycle_buttons(false)
				
func cycle_buttons(up: bool):
	if up:
		but_index +=1
	else: 
		but_index -=1 
	if but_index >= len(buttons) || but_index < 0:
		but_index = 0 
	buttons[but_index].grab_focus()
	
func reveal_rank():
	is_cycling = false
	cycle_timer = 0.0
	rank.stop_on_rank(calculated_rank)
	feed_back_text.text = get_rank_message(calculated_rank)
	feed_back_text.visible = true
	
	if calculated_rank == "A":
		print("A rank recieved")
		update_sprite_array(demerit_sprites, demerits, false)
		update_sprite_array(retry_token_sprites, retry_tokens, true)
	elif calculated_rank == "C":
		print("C rank recieved")
		update_sprite_array(demerit_sprites, demerits, true)
		update_sprite_array(retry_token_sprites, retry_tokens, false)

func update_sprite_array(sprites: Array, max_revealed: int, new: bool):
	for index in sprites.size():
		if index < max_revealed:
			sprites[index].visible = true 
		else:
			sprites[index].visible = false 
	if new:
		flash(sprites[max_revealed-1])
	return sprites
	

func flash(entity: Node2D, flash_count: int = 2, flash_duration: float = 0.3):
	print("calling ui flash function")
	new_token_flash = create_tween()
	for i in flash_count:
		new_token_flash.tween_property(entity, "modulate:a", 0.0, flash_duration)
		new_token_flash.tween_property(entity, "modulate:a", 1.0, flash_duration)
		
func get_time_string(remaining_minutes) -> String:
	var hours = remaining_minutes / 60
	var mins = remaining_minutes % 60
	return "%d:%02d" % [hours, mins]
