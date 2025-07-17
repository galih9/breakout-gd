extends CharacterBody2D

@export var speed: float = 400.0

# Signals to emit when the ball enters a specific sensor
signal ball_hit_left_sensor(ball_node)
signal ball_hit_middle_sensor(ball_node)
signal ball_hit_right_sensor(ball_node)

func _physics_process(_delta: float) -> void:
	var direction := 0

	if Input.is_action_pressed("ui_left"):
		direction -= 1
	if Input.is_action_pressed("ui_right"):
		direction += 1

	velocity.x = direction * speed
	velocity.y = 0 # Just in case — make sure it doesn't drift vertically

	move_and_slide()

# --- Sensor Callbacks ---
func _on_LeftSensor_body_entered(body: Node2D) -> void:
	if body.name == "ball": # Check if the entering body is your ball
		ball_hit_left_sensor.emit(body) # Emit the signal, passing the ball node

func _on_MiddleSensor_body_entered(body: Node2D) -> void:
	if body.name == "ball":
		ball_hit_middle_sensor.emit(body)

func _on_RightSensor_body_entered(body: Node2D) -> void:
	if body.name == "ball":
		ball_hit_right_sensor.emit(body)
