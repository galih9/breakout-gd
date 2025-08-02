extends Node2D

@onready var pause_ui = $PauseUI
@onready var bricks_node = $Bricks # Get a reference to your "Bricks" Node2D
@onready var ball_node = $ball # Get a reference to your "ball" RigidBody2D

var initial_brick_data: Array = [] # To store position and initial properties of bricks
var current_level: int = 1 # Keep track of the current level/ante
var ball_count: int = 1 # Keep track of the current level/ante
var launched_once: bool = false # Flag to prevent immediate level clear on startup
var score = 0

func _ready():
	# Ensure the ball is at its starting position before the game begins
	ball_node.reset_ball()
	
	# Store the initial state of the bricks when the game starts
	# This will also clear the initial bricks from the scene
	store_initial_brick_layout()
	
	# The first set of bricks will be spawned by store_initial_brick_layout
	# No need to call spawn_bricks() here again.

func add_ball(count):
	print('add ball called')
	ball_count = ball_count+count
	print(ball_count)

func remove_ball():
	print('remove ball called')
	ball_count = ball_count-1
	print(ball_count)

func brick_destroyed(points):
	score += points
	$Score.text = str(score)
	
func _input(event):
	if event.is_action_pressed("pause") and not get_tree().paused:
		pause_ui.show_pause()

func _physics_process(_delta):
	# Set launched_once to true once the ball has been launched
	if ball_node.launched and not launched_once:
		launched_once = true
	
	# Check for bricks only after the ball has been launched at least once
	if launched_once:
		check_for_bricks_remaining()
	
	
	if (ball_count == 0):
		ball_count = 1
		ball_node.reset_ball()

func check_for_bricks_remaining():
	var destroyable_brick_count = 0
	for child in bricks_node.get_children():
		if child is StaticBody2D and child.is_in_group("bricks") and child.can_be_destroyed:
			destroyable_brick_count += 1
	
	# If no destroyable bricks are left and the ball has been launched at least once
	if destroyable_brick_count == 0 and launched_once:
		print("All destroyable bricks destroyed! Advancing to next level.")
		current_level += 1
		reset_level()

func store_initial_brick_layout():
	initial_brick_data.clear()
	print('curr level ', current_level)

	for child in bricks_node.get_children():
		if child is StaticBody2D and child.is_in_group("bricks"):
			var brick_data = {
				"scene_path": child.scene_file_path,
				"position": child.position,
				"brick_texture": child.brick_texture,
				"max_hp": child.max_hp,
				"brick_type": child.brick_type as int,  # Store as integer
				# Movement properties
				"is_moving": child.is_moving,
				"move_points": child.move_points.duplicate(),
				"move_speed": child.move_speed,
				"wait_time_at_points": child.wait_time_at_points,
				"loop_movement": child.loop_movement
			}
			print("Storing brick type:", brick_data.brick_type)
			initial_brick_data.append(brick_data)
			child.queue_free()

	spawn_bricks()

func spawn_bricks():
	for child in bricks_node.get_children():
		child.queue_free()
	
	for data in initial_brick_data:
		var brick_scene = load(data.scene_path)
		if brick_scene:
			var new_brick = brick_scene.instantiate()
			new_brick.brick_type = data.brick_type # Set brick type before adding to scene
			bricks_node.add_child(new_brick)
			new_brick.position = data.position
			new_brick.brick_texture = data.brick_texture
			
			# Only increase HP for destroyable bricks
			if new_brick.can_be_destroyed:
				new_brick.max_hp = data.max_hp + (current_level - 1)
				new_brick.current_hp = new_brick.max_hp
			
			# Apply movement properties
			if data.brick_type == new_brick.BrickType.MOVING:
				new_brick.is_moving = data.is_moving
				new_brick.move_points = data.move_points.duplicate()
				new_brick.move_speed = data.move_speed
				new_brick.wait_time_at_points = data.wait_time_at_points
				new_brick.loop_movement = data.loop_movement
				new_brick.setup_movement()
	
	print("Bricks spawned for Level ", current_level)

func reset_level():
	# Reset the ball to its initial state/position
	ball_node.reset_ball()
	# Reset the launch flag so the player must launch the ball again
	launched_once = false 

	# Spawn the next set of bricks for the new level
	spawn_bricks()

	print("Bricks spawned for Level ", current_level)
