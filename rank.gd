extends Label

var ranks = ["A", "B", "C"]
var current_index = 0
var final_rank_index = 0 
var is_cycling = false
var cycle_speed = 0.05
var cycle_timer: Timer

func _ready():
	update_display()

func start_cycling():
	is_cycling = true
	var tween = create_tween()
	
	var final_speed = 0.1
	tween.tween_property(self, "cycle_speed", final_speed, 0.5)
	
	if cycle_timer:
		cycle_timer.queue_free()
	
	cycle_timer = Timer.new()
	add_child(cycle_timer)
	cycle_timer.wait_time = cycle_speed
	cycle_timer.timeout.connect(_on_cycle_timer_timeout)
	cycle_timer.start()


func _on_cycle_timer_timeout():
	if is_cycling:
		cycle_timer.wait_time = cycle_speed
		current_index = (current_index + 1) % ranks.size()
		update_display()
	elif current_index != final_rank_index:
		# Keep cycling until we reach the final rank
		current_index = (current_index + 1) % ranks.size()
		update_display()
	else:
		# We've reached the final rank
		update_display()
		cycle_timer.queue_free()
		
func stop_on_rank(rank_letter: String):
	is_cycling = false
	match rank_letter:
		"A":
			final_rank_index = 0
		"B":
			final_rank_index = 1
		"C": 
			final_rank_index = 2
	

func update_display():
	var display_text = "Rank: "
	
	for i in range(ranks.size()):
		if i == current_index:
			display_text += "[" + ranks[i] + "] "  # Brackets around highlighted letter
		else:
			display_text += ranks[i] + " "
	
	text = display_text
