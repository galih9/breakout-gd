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

func _on_MiddleSensor_body_entered(body: Node2D) -> void:
	if body.name == "ball":
		# Calculate offset to determine where the ball hit
		var offset = body.global_position.x - global_position.x
		var middle_threshold = 10.0 # Adjust tolerance for "middle" hit

		if abs(offset) < middle_threshold:
			ball_hit_middle_sensor.emit(body)
		elif offset < 0:
			ball_hit_left_sensor.emit(body)
		else:
			ball_hit_right_sensor.emit(body)

func widen_pad():
	%Sprite2D.scale.x = 3
	%Sensor.scale.x = 3
