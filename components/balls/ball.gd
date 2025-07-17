extends RigidBody2D

@export var initial_speed: float = 300.0
@export var damage := 1  # Ball level / damage
@export var min_vertical_speed_ratio: float = 0.5 # New: Minimum vertical speed as a ratio of initial_speed

var launched: bool = false
var paddle_ref: Node2D
var socket_ref: Marker2D

func _ready():
	# Get references to the paddle and its marker
	paddle_ref = get_parent().get_node("Pad")
	socket_ref = paddle_ref.get_node("BallSocket")

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
		
		# New: Ensure minimum vertical speed
		ensure_minimum_vertical_speed()

func launch_ball():
	sleeping = false
	launched = true
	var direction = Vector2(randf_range(-0.5, 0.5), -1).normalized()
	linear_velocity = direction * initial_speed
	
func reset_ball():
	sleeping = true
	linear_velocity = Vector2.ZERO
	launched = false
	if is_instance_valid(paddle_ref) and is_instance_valid(socket_ref):
		global_position = socket_ref.global_position

func ensure_minimum_vertical_speed():
	# Calculate the minimum allowed vertical speed
	var min_vertical_speed = initial_speed * min_vertical_speed_ratio

	# If the absolute vertical velocity is too low, adjust it
	if abs(linear_velocity.y) < min_vertical_speed:
		var new_y_velocity = sign(linear_velocity.y) * min_vertical_speed
		var new_x_velocity = sqrt(initial_speed * initial_speed - new_y_velocity * new_y_velocity)
		
		# Preserve the horizontal direction
		new_x_velocity *= sign(linear_velocity.x) if linear_velocity.x != 0 else randf_range(-1, 1)

		linear_velocity = Vector2(new_x_velocity, new_y_velocity).normalized() * initial_speed

func _on_Area2D_body_entered(body):
	if body.is_in_group("bricks") && body.has_method("apply_damage"):
		body.apply_damage(damage)

func _on_GameOverSensor_body_entered(body: Node2D) -> void:
	if body == self:
		reset_ball()

func _on_body_entered(body: Node2D) -> void:
	# This function will be called when the ball collides with any body (walls, paddle)
	# You'll need to connect the 'body_entered' signal from the ball's RigidBody2D node
	# to this script.
	if body == paddle_ref:
		# When hitting the paddle, you might want to give it a slight vertical push
		# or just let the ensure_minimum_vertical_speed handle it.
		# A common technique is to adjust the bounce angle based on where it hit the paddle.
		# For simplicity, we'll rely on the `ensure_minimum_vertical_speed` for now.
		pass
	
	# After any collision (bricks, walls, paddle), ensure vertical speed
	ensure_minimum_vertical_speed()
