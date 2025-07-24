extends RigidBody2D

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

func _ready():
	# Get references to the paddle and its marker
	paddle_ref = get_parent().get_node("Pad")
	socket_ref = paddle_ref.get_node("BallSocket")
	trail.gradient = create_trail_gradient()
	
	# Setup trail width curve for natural tapering
	trail_width_curve.add_point(Vector2(0.0, 1.0))  # Full width at start
	trail_width_curve.add_point(Vector2(1.0, 0.0))  # Zero width at end
	trail.width_curve = trail_width_curve
	trail.width = trail_width

	# Connect to the paddle's custom signals
	if is_instance_valid(paddle_ref):
		paddle_ref.ball_hit_left_sensor.connect(_on_paddle_left_hit)
		paddle_ref.ball_hit_middle_sensor.connect(_on_paddle_middle_hit)
		paddle_ref.ball_hit_right_sensor.connect(_on_paddle_right_hit)
	else:
		print("Error: Paddle reference not found in Ball script!")

	# Put ball to sleep before launch
	sleeping = true
	linear_velocity = Vector2.ZERO
	launched = false
	# Initialize trail at socket position
	reset_trail_at_socket()
	# Hide trail initially if no power-up
	trail.visible = power == "ice" and not ice_power_timer.is_stopped()

func _physics_process(_delta):
	if not launched:
		# Attach ball to paddle until launch
		global_position = socket_ref.global_position

		if Input.is_action_just_pressed("ui_up"):
			launch_ball()
	else:
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
	sleeping = true
	linear_velocity = Vector2.ZERO
	launched = false
	if is_instance_valid(paddle_ref) and is_instance_valid(socket_ref):
		global_position = socket_ref.global_position
		# Reset trail to socket position with a single point
		reset_trail_at_socket()
	# Reset power-up and trail visibility
	power = "none"
	trail.visible = false
	if not ice_power_timer.is_stopped():
		ice_power_timer.stop()

func reset_trail_at_socket():
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

func _on_Area2D_body_entered(body):
	if body.is_in_group("bricks") && body.has_method("apply_damage"):
		body.apply_damage(damage)

func _on_GameOverSensor_body_entered(body: Node2D) -> void:
	if body == self:
		reset_ball()

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
