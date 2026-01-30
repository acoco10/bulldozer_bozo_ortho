extends CPUParticles2D

@export var powerup_color: Color = Color.GOLD
@export var secondary_color: Color = Color.YELLOW
@export var auto_start: bool = true
@export var one_shot_effect: bool = false
@export var particle_lifetime: float = 1.0

func _ready():
	setup_particles()
	if auto_start:
		emitting = true
	if one_shot_effect:
		await get_tree().create_timer(lifetime).timeout
		queue_free()

func setup_particles():
	# Basic settings
	amount = 400
	lifetime = particle_lifetime
	one_shot = one_shot_effect
	explosiveness = 0.8 if one_shot_effect else 0.3
	randomness = 0.5
	
	# Emission shape - circle around powerup
	emission_shape = EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 8.0
	
	# Movement - sparkles rise up and spread
	direction = Vector2(0, -1)
	spread = 45.0
	gravity = Vector2(0, -20)
	initial_velocity_min = 20.0
	initial_velocity_max = 40.0
	
	# Rotation
	angular_velocity_min = -180.0
	angular_velocity_max = 180.0
	
	# Scale - start small, grow, then shrink
	scale_amount_min = 0.5
	scale_amount_max = 1.5
	scale_amount_curve = create_scale_curve()
	
	# Color gradient
	color_ramp = create_color_gradient()
	
	# Alpha fade
	color_initial_ramp = create_alpha_gradient()

func create_scale_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 0.2))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func create_color_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, powerup_color)
	gradient.add_point(0.5, secondary_color)
	gradient.add_point(1.0, powerup_color)
	return gradient

func create_alpha_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 1))
	gradient.add_point(0.7, Color(1, 1, 1, 0.8))
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	return gradient

# Call this to play a burst effect
func burst():
	one_shot = true
	explosiveness = 1.0
	emitting = true

# Call this to change colors on the fly
func set_colors(primary: Color, secondary: Color = Color.WHITE):
	powerup_color = primary
	secondary_color = secondary
	color_ramp = create_color_gradient()
