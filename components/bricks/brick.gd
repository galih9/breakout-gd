extends StaticBody2D

enum BrickType {
	NORMAL,
	MOVING,
	BLOCK,
	BALL,
	POWER
}

@export var brick_type: BrickType = BrickType.NORMAL
@export var brick_texture: Texture2D
@export var max_hp: int = 1

# Ball brick properties
@export var ball_scene: PackedScene  # Assign your ball scene in the editor
@export var ball_scene_path: String = "res://components/balls/ball.tscn"  # Fallback path
@export var balls_to_spawn: int = 3
@export var ball_spawn_speed: float = 300.0

# power ups
@export var power_scene: PackedScene  # Assign your ball scene in the editor
@export var power_scene_path: String = "res://components/power/power.tscn" # Fallback path

# Movement properties
@export var is_moving: bool = false
@export var move_points: Array[Vector2] = []
@export var move_speed: float = 50.0
@export var wait_time_at_points: float = 0.0
@export var loop_movement: bool = true

@onready var hp_label = $Label
var current_hp: int
var can_be_destroyed: bool = true

# Movement variables
var current_point_index: int = 0
var target_position: Vector2
var is_waiting: bool = false
var wait_timer: float = 0.0
var movement_direction: int = 1
var original_speed: float
var speed_modifier: float = 1.0

@export var specific_power_type: Generator.POWER_TYPES = Generator.POWER_TYPES.NONE  # For POWER type bricks

signal brick_damaged(points)
signal balls_spawned(balls_array)  # New signal for ball spawning

func _ready():
	if brick_texture != null:
		$Sprite2D.texture = brick_texture
	setup_brick_type()
	
	# Initialize movement
	original_speed = move_speed
	if is_moving and move_points.size() > 0:
		setup_movement()

func setup_brick_type():
	# Setup based on brick type
	match brick_type:
		BrickType.NORMAL:
			can_be_destroyed = true
			is_moving = false
		BrickType.MOVING:
			can_be_destroyed = true
			is_moving = true
		BrickType.BLOCK:
			can_be_destroyed = false
			is_moving = false
			hp_label.hide()
		BrickType.BALL:  # New ball brick setup
			can_be_destroyed = true
			is_moving = false
			# You might want to use a different color/texture for ball bricks
		BrickType.POWER:
			can_be_destroyed = true
			is_moving = false
	
	current_hp = max_hp if can_be_destroyed else 0
	update_label()

func _physics_process(delta):
	if is_moving and not is_waiting and move_points.size() > 1:
		move_towards_target(delta)

func setup_movement():
	if move_points.size() == 0:
		var start_pos = global_position
		move_points = [start_pos, start_pos + Vector2(100, 0)]
	
	if move_points.size() > 0:
		current_point_index = 0
		target_position = move_points[0]
		global_position = target_position
		if move_points.size() > 1:
			set_next_target()

func move_towards_target(delta):
	var current_speed = move_speed * speed_modifier
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target < 2.0:
		global_position = target_position
		if wait_time_at_points > 0:
			start_waiting()
		else:
			set_next_target()
	else:
		var direction = (target_position - global_position).normalized()
		global_position += direction * current_speed * delta

func set_next_target():
	if move_points.size() <= 1:
		return
	
	if loop_movement:
		current_point_index = (current_point_index + 1) % move_points.size()
	else:
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
	if not can_be_destroyed:
		return
	
	emit_signal("brick_damaged", 1000)
	current_hp -= amount
	update_label()
	
	if current_hp <= 0:
		# Check if this is a ball brick before destroying
		if brick_type == BrickType.BALL:
			# Defer the ball spawning to avoid physics conflicts
			await call_deferred("spawn_balls")
		if brick_type == BrickType.POWER:
			await call_deferred("spawn_power",1.0)
		queue_free()

func spawn_balls():
	print("Ball scene reference: ", ball_scene)
	print("Ball scene is null: ", ball_scene == null)
	
	# Try to use assigned scene first, then fallback to path
	var scene_to_use = ball_scene
	if scene_to_use == null and ball_scene_path != "":
		print("Trying to load from path: ", ball_scene_path)
		scene_to_use = load(ball_scene_path)
	
	if scene_to_use == null:
		print("Error: No ball scene available!")
		return
	
	var spawned_balls = []
	var main = get_tree().get_root().get_node("Main")  # Or use $"../.." if predictable
	
	for i in range(balls_to_spawn):
		# Create new ball instance
		var new_ball = scene_to_use.instantiate()
		
		# Add to the same parent as the brick (usually the main scene)
		get_parent().add_child(new_ball)
		
		# Position at the brick's location
		new_ball.global_position = global_position
		
		# Calculate random direction (avoid straight up/down for better gameplay)
		var angle = randf_range(PI * 0.2, PI * 0.8)  # Angles between 36° and 144°
		if randf() > 0.5:
			angle = PI - angle  # Mirror to the other side sometimes
		var direction = Vector2(cos(angle), sin(angle))
		
		# Set the ball as already launched and give it velocity
		new_ball.launched = true
		new_ball.sleeping = false
		new_ball.linear_velocity = direction * ball_spawn_speed
		
		# Emit signal with spawned balls array
		print('spaaaaawn')
		main.add_ball(1)
		print('tak masuk logika?')
		spawned_balls.append(new_ball)
		# Make sure the ball doesn't try to attach to paddle
		# by setting it as launched before _ready() completes
		await get_tree().process_frame  # Wait one frame for ball's _ready() to complete
	emit_signal("balls_spawned", spawned_balls)

func update_label():
	if hp_label:
		hp_label.text = str(current_hp)

# Speed modification functions for power-ups/effects
func set_speed_modifier(modifier: float):
	speed_modifier = modifier

func freeze(duration: float, freeze_intensity: float = 0.1):
	var old_modifier = speed_modifier
	set_speed_modifier(freeze_intensity)
	
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
	is_moving = false

func resume_movement():
	is_moving = true

func reset_to_original_speed():
	move_speed = original_speed
	speed_modifier = 1.0

func add_move_point(point: Vector2):
	move_points.append(point)
	if is_moving and move_points.size() == 1:
		setup_movement()

func clear_move_points():
	move_points.clear()
	stop_movement()

func _draw():
	if Engine.is_editor_hint() and move_points.size() > 1:
		for i in range(move_points.size()):
			var next_i = (i + 1) % move_points.size()
			var start_point = to_local(move_points[i])
			var end_point = to_local(move_points[next_i])
			draw_line(start_point, end_point, Color.YELLOW, 2.0)
			draw_circle(start_point, 4.0, Color.RED)

func spawn_power(spawn_chance: float):
	print("Power scene reference: ", power_scene)
	print("Power scene is null: ", power_scene == null)
	
	# Try to use assigned scene first, then fallback to path
	var scene_to_use = power_scene
	if scene_to_use == null and power_scene_path != "":
		print("Trying to load power from path: ", power_scene_path)
		scene_to_use = load(power_scene_path)
	
	if scene_to_use == null:
		print("Error: No power scene available!")
		return
	
	# Create new power-up instance
	var new_power = scene_to_use.instantiate()
	
	# Add to the same parent as the brick (usually the main scene)
	get_parent().add_child(new_power)
	
	# Position at the brick's location
	new_power.global_position = global_position
	
	# Set power type if this is a POWER brick with a specific type
	if brick_type == BrickType.POWER and specific_power_type != Generator.POWER_TYPES.NONE:
		new_power.power_type = specific_power_type
	else:
		# For random power-ups, you might want to set a random type
		var power_types = Generator.POWER_TYPES.values()
		if power_types.size() > 1:
			# Filter out NONE type if it exists
			power_types = power_types.filter(func(type): return type != Generator.POWER_TYPES.NONE)
			if power_types.size() > 0:
				new_power.power_type = power_types[randi() % power_types.size()]
	
	# Make sure the power-up starts falling
	new_power.start_falling()
	# Wait one frame for power-up's _ready() to complete
	await get_tree().process_frame
