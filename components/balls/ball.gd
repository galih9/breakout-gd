extends RigidBody2D

@export var initial_speed: float = 300.0
@export var damage := 1  # Ball level / damage
@export var min_vertical_speed_ratio: float = 0.5 # Minimum vertical speed as a ratio of initial_speed
@export var side_bounce_strength: float = 0.7 # How much horizontal velocity to add/subtract (0.0 to 1.0)
@export var middle_bounce_vertical_bias: float = 0.2 # How much more vertical the middle bounce is

var launched: bool = false
var paddle_ref: Node2D
var socket_ref: Marker2D

func _ready():
	# Get references to the paddle and its marker
	paddle_ref = get_parent().get_node("Pad")
	socket_ref = paddle_ref.get_node("BallSocket")

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

func _physics_process(_delta):
	if not launched:
		# Attach ball to paddle until launch
		global_position = socket_ref.global_position

		if Input.is_action_just_pressed("ui_up"):
			launch_ball()
	else:
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
	
func reset_ball():
	sleeping = true
	linear_velocity = Vector2.ZERO
	launched = false
	if is_instance_valid(paddle_ref) and is_instance_valid(socket_ref):
		global_position = socket_ref.global_position

func ensure_minimum_vertical_speed():
	var min_vertical_speed = initial_speed * min_vertical_speed_ratio

	if abs(linear_velocity.y) < min_vertical_speed:
		var new_y_velocity = sign(linear_velocity.y) * min_vertical_speed
		var new_x_velocity = sqrt(initial_speed * initial_speed - new_y_velocity * new_y_velocity)
		
		new_x_velocity *= sign(linear_velocity.x) if linear_velocity.x != 0 else randf_range(-1, 1)

		linear_velocity = Vector2(new_x_velocity, new_y_velocity).normalized() * initial_speed

# --- New Paddle Hit Functions ---
func _on_paddle_left_hit(ball_node_ref: Node2D) -> void:
	# This function is called when the ball hits the left sensor
	# Ensure it's THIS ball instance that hit it (important if multiple balls exist)
	if ball_node_ref != self: return

	# Reverse vertical direction (always bounce up from paddle)
	var new_y = -abs(linear_velocity.y) 
	
	# If coming from left (negative x), make it go more left.
	# If coming from right (positive x), make it go left.
	var new_x = -initial_speed * side_bounce_strength # Always push to the left

	linear_velocity = Vector2(new_x, new_y).normalized() * initial_speed
	print("Ball hit left sensor!")

func _on_paddle_middle_hit(ball_node_ref: Node2D) -> void:
	if ball_node_ref != self: return

	# Reverse vertical direction
	var new_y = -abs(linear_velocity.y) 
	
	# Make it more vertical by reducing horizontal speed
	var new_x = linear_velocity.x * (1.0 - middle_bounce_vertical_bias) # Reduce horizontal component

	linear_velocity = Vector2(new_x, new_y).normalized() * initial_speed
	print("Ball hit middle sensor!")

func _on_paddle_right_hit(ball_node_ref: Node2D) -> void:
	if ball_node_ref != self: return

	# Reverse vertical direction
	var new_y = -abs(linear_velocity.y) 
	
	# If coming from right (positive x), make it go more right.
	# If coming from left (negative x), make it go right.
	var new_x = initial_speed * side_bounce_strength # Always push to the right

	linear_velocity = Vector2(new_x, new_y).normalized() * initial_speed
	print("Ball hit right sensor!")


func _on_Area2D_body_entered(body):
	# This is your existing collision logic for bricks
	if body.is_in_group("bricks") && body.has_method("apply_damage"):
		body.apply_damage(damage)

func _on_GameOverSensor_body_entered(body: Node2D) -> void:
	if body == self:
		reset_ball()
