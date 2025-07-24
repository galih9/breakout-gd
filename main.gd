extends Node2D

@onready var pause_ui = $PauseUI
@onready var bricks_node = $Bricks # Get a reference to your "Bricks" Node2D
@onready var ball_node = $ball # Get a reference to your "ball" RigidBody2D

var initial_brick_data: Array = [] # To store position and initial properties of bricks
var current_level: int = 1 # Keep track of the current level/ante
var ball_count: int = 1 # Keep track of the current level/ante
var launched_once: bool = false # Flag to prevent immediate level clear on startup

func _ready():
	# Ensure the ball is at its starting position before the game begins
	ball_node.reset_ball()
	
	# Store the initial state of the bricks when the game starts
	# This will also clear the initial bricks from the scene
	store_initial_brick_layout()
	
	# The first set of bricks will be spawned by store_initial_brick_layout
	# No need to call spawn_bricks() here again.

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

func store_initial_brick_layout():
	# Clear any existing data
	initial_brick_data.clear()

	# Iterate through existing bricks in the scene to save their data
	for child in bricks_node.get_children():
		# Make sure it's a brick and part of the "bricks" group
		if child is StaticBody2D and child.is_in_group("bricks"):
			# Store ALL brick properties including movement properties
			var brick_data = {
				"scene_path": child.scene_file_path, # Path to the original brick scene
				"position": child.position,
				"brick_texture": child.brick_texture,
				"max_hp": child.max_hp,
				# Movement properties
				"is_moving": child.is_moving if "is_moving" in child else false,
				"move_points": child.move_points.duplicate() if "move_points" in child else [],
				"move_speed": child.move_speed if "move_speed" in child else 50.0,
				"wait_time_at_points": child.wait_time_at_points if "wait_time_at_points" in child else 0.0,
				"loop_movement": child.loop_movement if "loop_movement" in child else true
			}
			initial_brick_data.append(brick_data)
			# Clean up the initial bricks from the scene after storing their data
			child.queue_free()

	# After storing the layout, spawn the first set of bricks for Level 1
	spawn_bricks()
	print("Initial brick layout stored and first level spawned.")

func spawn_bricks():
	# First, clear any existing bricks (from previous levels)
	for child in bricks_node.get_children():
		child.queue_free()
	
	# Spawn new bricks based on the stored initial data
	for data in initial_brick_data:
		# Load the brick scene dynamically
		var brick_scene = load(data.scene_path)
		if brick_scene:
			var new_brick = brick_scene.instantiate()
			bricks_node.add_child(new_brick)
			new_brick.position = data.position
			
			# Apply texture
			new_brick.brick_texture = data.brick_texture
			
			# Increase HP for new levels, or keep original for level 1
			# Each level (after the first) adds 1 HP to bricks
			new_brick.max_hp = data.max_hp + (current_level - 1) 
			new_brick.current_hp = new_brick.max_hp # Ensure current_hp is set
			new_brick.update_label() # Update the label immediately
			
			# Apply movement properties if they exist
			if "is_moving" in data and data.is_moving:
				new_brick.is_moving = data.is_moving
				new_brick.move_points = data.move_points.duplicate()
				new_brick.move_speed = data.move_speed
				new_brick.wait_time_at_points = data.wait_time_at_points
				new_brick.loop_movement = data.loop_movement
				
				# Important: Call setup_movement to initialize the movement system
				new_brick.setup_movement()

	print("Bricks spawned for Level ", current_level)

func check_for_bricks_remaining():
	var brick_count = 0
	for child in bricks_node.get_children():
		# Count only actual brick nodes
		if child is StaticBody2D and child.is_in_group("bricks"):
			brick_count += 1
	
	# If no bricks are left and the ball has been launched at least once
	if brick_count == 0 and launched_once:
		print("All bricks destroyed! Advancing to next level.")
		current_level += 1
		reset_level()

func reset_level():
	# Reset the ball to its initial state/position
	ball_node.reset_ball()
	# Reset the launch flag so the player must launch the ball again
	launched_once = false 

	# Spawn the next set of bricks for the new level
	spawn_bricks()
