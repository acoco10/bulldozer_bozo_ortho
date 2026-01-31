extends AnimatedSprite2D
var sink_progress: float = 0.0
var shader_tween: Tween = create_tween()

func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/sinking_shader.gdshader")

func start_sinking(duration: float = 2.0) -> void:
	shader_tween = create_tween()
	shader_tween.tween_method(set_sink_progress, 0.0, 1.0, duration)
	
func set_sink_progress(value: float) -> void:
	sink_progress = value
	if material:
		material.set_shader_parameter("sink_progress", value)

func reset():
	if shader_tween.is_valid():
		shader_tween.kill()
	set_sink_progress(0.0)
