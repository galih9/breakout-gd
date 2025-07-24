extends StaticBody2D

@export var brick_texture: Texture2D
@export var max_hp: int = 1

# Movement properties
@export var is_moving: bool = false
@export var move_points: Array[Vector2] = []
@export var move_speed: float = 50.0
@export var wait_time_at_points: float = 0.0  # Time to pause at each point
@export var loop_movement: bool = true  # Whether to loop back to start or ping-pong

@onready var hp_label = $Label
var current_hp: int

# Movement variables
var current_point_index: int = 0
var target_position: Vector2
var is_waiting: bool = false
var wait_timer: float = 0.0
var movement_direction: int = 1  # 1 for forward, -1 for backward (ping-pong mode)
var original_speed: float  # Store original speed for freeze effects
var speed_modifier: float = 1.0  # Speed multiplier for effects like freeze

func _ready():
	if brick_texture != null:
		$Sprite2D.texture = brick_texture
	current_hp = max_hp
	update_label()
	
	# Initialize movement
	original_speed = move_speed
	if is_moving and move_points.size() > 0:
		setup_movement()

func _physics_process(delta):
	if is_moving and not is_waiting and move_points.size() > 1:
		move_towards_target(delta)

func setup_movement():
	if move_points.size() == 0:
		# If no points specified, create a simple back-and-forth movement
		var start_pos = global_position
		move_points = [start_pos, start_pos + Vector2(100, 0)]
	
	# Start at the first point
	if move_points.size() > 0:
		current_point_index = 0
		target_position = move_points[0]
		global_position = target_position
		if move_points.size() > 1:
			set_next_target()

func move_towards_target(delta):
	var current_speed = move_speed * speed_modifier
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target < 2.0:  # Close enough to target
		global_position = target_position
		if wait_time_at_points > 0:
			start_waiting()
		else:
			set_next_target()
	else:
		# Move towards target
		var direction = (target_position - global_position).normalized()
		global_position += direction * current_speed * delta

func set_next_target():
	if move_points.size() <= 1:
		return
	
	if loop_movement:
		# Loop mode: go through points in order, then restart
		current_point_index = (current_point_index + 1) % move_points.size()
	else:
		# Ping-pong mode: go back and forth
		current_point_index += movement_direction
		
		if current_point_index >= move_points.size():
			current_point_index = move_points.size() - 2
			movement_direction = -1
		elif current_point_index < 0:
			current_point_index = 1
			movement_direction = 1
	
	target_position = move_points[current_point_index]

func start_waiting():
	is_waiting = true
	wait_timer = wait_time_at_points

func _process(delta):
	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			set_next_target()

func apply_damage(amount: int):
	current_hp -= amount
	print("called",amount)
	update_label()
	if current_hp <= 0:
		queue_free()

func update_label():
	if hp_label:
		hp_label.text = str(current_hp)

# Speed modification functions for power-ups/effects
func set_speed_modifier(modifier: float):
	"""Set a speed modifier (1.0 = normal, 0.5 = half speed, 2.0 = double speed)"""
	speed_modifier = modifier

func freeze(duration: float, freeze_intensity: float = 0.1):
	"""Temporarily freeze/slow the brick"""
	var old_modifier = speed_modifier
	set_speed_modifier(freeze_intensity)
	
	# Create a timer to restore normal speed
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		set_speed_modifier(old_modifier)
		timer.queue_free()
	)
	timer.start()

func stop_movement():
	"""Stop the brick movement completely"""
	is_moving = false

func resume_movement():
	"""Resume the brick movement"""
	is_moving = true

func reset_to_original_speed():
	"""Reset speed to the original value"""
	move_speed = original_speed
	speed_modifier = 1.0

# Helper function to add points programmatically
func add_move_point(point: Vector2):
	move_points.append(point)
	if is_moving and move_points.size() == 1:
		setup_movement()

func clear_move_points():
	move_points.clear()
	stop_movement()

# Debug function to visualize movement path
func _draw():
	if Engine.is_editor_hint() and move_points.size() > 1:
		for i in range(move_points.size()):
			var next_i = (i + 1) % move_points.size()
			var start_point = to_local(move_points[i])
			var end_point = to_local(move_points[next_i])
			draw_line(start_point, end_point, Color.YELLOW, 2.0)
			draw_circle(start_point, 4.0, Color.RED)
