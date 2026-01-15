extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

signal transition_finished

enum Direction { RIGHT, LEFT, DOWN, UP }

func _ready() -> void:
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.material.set_shader_parameter("progress", 0.0)
	color_rect.color = Color.BLACK
	color_rect.color.a = 0
	color_rect.size = get_viewport().get_visible_rect().size


func wipe_to_black(duration: float = 0.5, dir: Direction = Direction.RIGHT) -> void:
	color_rect.material.set_shader_parameter("direction", dir)
	color_rect.material.set_shader_parameter("progress", 0.0)

	var tween = create_tween()
	tween.tween_method(set_progress, 0.0, 1.0, duration)
	tween.tween_callback(func(): transition_finished.emit())

func set_progress(value: float) -> void:
	color_rect.material.set_shader_parameter("progress", value)

func wipe_from_black(duration: float = 0.5, dir: Direction = Direction.RIGHT) -> void:
	# Flip direction so it "unwipes" from where it came
	var reverse_dir = dir
	match dir:
		Direction.RIGHT: reverse_dir = Direction.LEFT
		Direction.LEFT: reverse_dir = Direction.RIGHT
		Direction.DOWN: reverse_dir = Direction.UP
		Direction.UP: reverse_dir = Direction.DOWN
	color_rect.material.set_shader_parameter("direction", reverse_dir)
	color_rect.material.set_shader_parameter("progress", 1.0)

	var tween = create_tween()
	tween.tween_method(set_progress, 1.0, 0.0, duration)
	tween.tween_callback(func(): transition_finished.emit())
	
