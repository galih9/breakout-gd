extends RigidBody2D

@export var initial_speed: float = 300.0

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


func _on_Area2D_body_entered(body):
	if body.is_in_group("bricks"):
		body.queue_free()


func _on_GameOverSensor_body_entered(body: Node2D) -> void:
	if body == self:
		reset_ball()
