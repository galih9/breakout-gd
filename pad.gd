extends CharacterBody2D

@export var speed: float = 400.0

func _physics_process(delta: float) -> void:
	var direction := 0

	if Input.is_action_pressed("ui_left"):
		direction -= 1
	if Input.is_action_pressed("ui_right"):
		direction += 1

	velocity.x = direction * speed
	velocity.y = 0  # Just in case — make sure it doesn't drift vertically

	move_and_slide()
