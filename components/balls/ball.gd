extends RigidBody2D

enum BallType {
	NORMAL,    # Regular ball that attaches to paddle
	SPAWNED    # Special ball spawned from brick - bypasses paddle logic
}

@export var ball_type: BallType = BallType.NORMAL
@export var initial_speed: float = 300.0
@export var damage := 1  # Ball level / damage
@export var min_vertical_speed_ratio: float = 0.5 # Minimum vertical speed as a ratio of initial_speed
@export var side_bounce_strength: float = 0.7 # How much horizontal velocity to add/subtract (0.0 to 1.0)
@export var middle_bounce_vertical_bias: float = 0.2 # How much more vertical the middle bounce is
@export var power: String = "none" # Power-up type (e.g., "ice", "none")

@onready var trail = $Line2D
@onready var ice_power_timer = $IcePowerTimer
var trail_points = []
@export var max_trail_length: int = 20
@export var trail_update_distance: float = 5.0
@export var trail_width: float = 10.0
@onready var trail_width_curve: Curve = Curve.new()

var launched: bool = false
var paddle_ref: Node2D
var socket_ref: Marker2D

var padsounds = [
	preload("res://assets/audio/rollover1.ogg"),
	preload("res://assets/audio/rollover2.ogg"),
	preload("res://assets/audio/rollover4.ogg"),
	preload("res://assets/audio/rollover5.ogg"),
]
var wallbricksound = [
	preload("res://assets/audio/click1.ogg"),
	preload("res://assets/audio/click2.ogg"),
	preload("res://assets/audio/click3.ogg"),
	preload("res://assets/audio/click4.ogg"),
	preload("res://assets/audio/click5.ogg"),
]

func _ready():
	# Setup trail
	trail.gradient = create_trail_gradient()
	trail_width_curve.add_point(Vector2(0.0, 1.0))  # Full width at start
	trail_width_curve.add_point(Vector2(1.0, 0.0))  # Zero width at end
	trail.width_curve = trail_width_curve
	trail.width = trail_width
	
	# Only setup paddle references for normal balls
	if ball_type == BallType.NORMAL:
		setup_paddle_references()
		# Put ball to sleep before launch
		sleeping = true
		linear_velocity = Vector2.ZERO
		launched = false
		# Initialize trail at socket position
		reset_trail_at_socket()
	else:
		# For spawned balls, they're already launched
		launched = true
		sleeping = false
		# Initialize trail at current position
		trail_points = [global_position]
	
	# Hide trail initially if no power-up
	trail.visible = power == "ice" and not ice_power_timer.is_stopped()

func setup_paddle_references():
	# Get references to the paddle and its marker
	paddle_ref = get_parent().get_node_or_null("Pad")
	if paddle_ref == null:
		# Try alternative paths
		var main_node = get_tree().get_root().get_node_or_null("Main")
		if main_node:
			paddle_ref = main_node.get_node_or_null("Pad")
	
	if paddle_ref:
		socket_ref = paddle_ref.get_node_or_null("BallSocket")
		# Connect to the paddle's custom signals
		if paddle_ref.has_signal("ball_hit_left_sensor"):
			paddle_ref.ball_hit_left_sensor.connect(_on_paddle_left_hit)
		if paddle_ref.has_signal("ball_hit_middle_sensor"):
			paddle_ref.ball_hit_middle_sensor.connect(_on_paddle_middle_hit)
		if paddle_ref.has_signal("ball_hit_right_sensor"):
			paddle_ref.ball_hit_right_sensor.connect(_on_paddle_right_hit)
	else:
		print("Warning: Paddle reference not found for ball - this is normal for spawned balls")

func _physics_process(_delta):
	if ball_type == BallType.NORMAL and not launched:
		# Attach ball to paddle until launch (only for normal balls)
		if socket_ref and is_instance_valid(socket_ref):
			global_position = socket_ref.global_position

		if Input.is_action_just_pressed("ui_up"):
			launch_ball()

	elif launched:
		update_trail()
		# Maintain constant speed
		if linear_velocity.length() != initial_speed:
			linear_velocity = linear_velocity.normalized() * initial_speed
		
		# Ensure minimum vertical speed
		ensure_minimum_vertical_speed()

func launch_ball():
	sleeping = false
	launched = true
	# Launch with a slight, consistent angle (e.g., 0.1 for a small horizontal push)
	var initial_horizontal_bias = 0.1 # Adjust this value (e.g., 0.05 to 0.2)
	var direction = Vector2(initial_horizontal_bias, -1).normalized() 
	linear_velocity = direction * initial_speed
	# Ensure trail starts smoothly
	trail_points = [global_position] # Start with current position
	# Update trail visibility based on power-up state
	trail.visible = power == "ice" and not ice_power_timer.is_stopped()

func reset_ball():
	# Only reset to paddle for normal balls
	if ball_type == BallType.NORMAL:
		sleeping = true
		linear_velocity = Vector2.ZERO
		launched = false
		if is_instance_valid(paddle_ref) and is_instance_valid(socket_ref):
			global_position = socket_ref.global_position
			# Reset trail to socket position with a single point
			reset_trail_at_socket()
	else:
		# For spawned balls, just destroy them when they need to reset
		queue_free()
		return
	
	# Reset power-up and trail visibility
	power = "none"
	trail.visible = false
	if not ice_power_timer.is_stopped():
		ice_power_timer.stop()

func reset_trail_at_socket():
	if socket_ref and is_instance_valid(socket_ref):
		# Initialize trail with a single point at the socket position
		trail_points = [socket_ref.global_position]
		trail.clear_points()
		trail.add_point(to_local(socket_ref.global_position))

func ensure_minimum_vertical_speed():
	var min_vertical_speed = initial_speed * min_vertical_speed_ratio

	if abs(linear_velocity.y) < min_vertical_speed:
		var new_y_velocity = sign(linear_velocity.y) * min_vertical_speed
		var new_x_velocity = sqrt(initial_speed * initial_speed - new_y_velocity * new_y_velocity)
		
		new_x_velocity *= sign(linear_velocity.x) if linear_velocity.x != 0 else randf_range(-1, 1)

		linear_velocity = Vector2(new_x_velocity, new_y_velocity).normalized() * initial_speed

# --- Power-Up Functions ---
func trigger_power_up(power_type: String):
	if power_type == "ice":
		power = "ice"
		if is_instance_valid(ice_power_timer):
			ice_power_timer.start()
			trail.visible = true
			trail_points = [global_position] # Reset trail for smooth start
		else:
			print("Error: IcePowerTimer not found, cannot activate ice power-up!")

func _on_ice_power_timer_timeout():
	# Reset power-up state when timer runs out
	power = "none"
	trail.visible = false
	trail_points = [global_position] # Reset trail to avoid imprints

# --- Paddle Hit Functions ---
func _on_paddle_left_hit(ball_node_ref: Node2D) -> void:
	if ball_node_ref != self: return
	var new_y = -abs(linear_velocity.y) 
	var new_x = -initial_speed * side_bounce_strength
	linear_velocity = Vector2(new_x, new_y).normalized() * initial_speed
	print("Ball hit left sensor!")

func _on_paddle_middle_hit(ball_node_ref: Node2D) -> void:
	if ball_node_ref != self: return
	var new_y = -abs(linear_velocity.y) 
	var new_x = linear_velocity.x * (1.0 - middle_bounce_vertical_bias)
	linear_velocity = Vector2(new_x, new_y).normalized() * initial_speed
	print("Ball hit middle sensor!")

func _on_paddle_right_hit(ball_node_ref: Node2D) -> void:
	if ball_node_ref != self: return
	var new_y = -abs(linear_velocity.y) 
	var new_x = initial_speed * side_bounce_strength
	linear_velocity = Vector2(new_x, new_y).normalized() * initial_speed
	print("Ball hit right sensor!")

func play_random_click_sound():
	var random_index = Generator.generate_random_number(0, wallbricksound.size() - 1)
	$AudioStreamPlayer.stream = wallbricksound[random_index]
	$AudioStreamPlayer.play()
	

func play_random_pad_sound():
	var random_index = Generator.generate_random_number(0, padsounds.size() - 1)
	$AudioStreamPlayer.stream = padsounds[random_index]
	$AudioStreamPlayer.play()

func _on_Area2D_body_entered(body):
	if body.is_in_group("walls"):
		play_random_click_sound()
	elif body.is_in_group("bricks"):
		play_random_click_sound()
	elif body.is_in_group("pads"):
		play_random_pad_sound()
	if body.is_in_group("bricks") && body.has_method("apply_damage"):
		var main = get_tree().get_root().get_node("Main")  # Or use $"../.." if predictable
		main.brick_destroyed(100)  # Send score or any data
		body.apply_damage(damage)

func _on_GameOverSensor_body_entered(body: Node2D) -> void:
	if body == self:
		var main = get_tree().get_root().get_node("Main")  # Or use $"../.." if predictable
		main.remove_ball()
		#reset_ball()

func create_trail_gradient():
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0, 1, 1, 1.0))   # Bright cyan at start
	gradient.add_point(0.3, Color(0, 1, 1, 0.7))   # Slightly faded cyan
	gradient.add_point(0.6, Color(0, 0.5, 1, 0.4)) # Transition to darker blue
	gradient.add_point(1.0, Color(0, 0, 1, 0.0))   # Fully transparent blue
	return gradient

func update_trail():
	# Only update trail if power-up is active and timer is running
	if power != "ice" or ice_power_timer.is_stopped():
		trail.visible = false
		return
	
	trail.visible = true
	var current_pos = global_position
	
	# Dynamic trail length based on speed
	var dynamic_trail_length = max_trail_length * (linear_velocity.length() / initial_speed)
	
	# Add new point if moved far enough
	if trail_points.is_empty() or current_pos.distance_to(trail_points[0]) > trail_update_distance:
		trail_points.push_front(current_pos)
		
		# Remove old points
		while trail_points.size() > dynamic_trail_length:
			trail_points.pop_back()
	
	# Update Line2D points with smoothing
	trail.clear_points()
	var point_count = trail_points.size()
	for i in range(point_count):
		var point = trail_points[i]
		if i < point_count - 1:
			var next_point = trail_points[i + 1]
			var smoothed_point = point.lerp(next_point, 0.3)
			trail.add_point(to_local(smoothed_point))
		else:
			trail.add_point(to_local(point))

# Helper function to set ball type (used by brick spawning)
func set_ball_type(type: BallType):
	ball_type = type
