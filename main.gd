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
	ball_node.reset_ball()

func add_ball(count):
	print('add ball called')
	ball_count = ball_count + count
	print(ball_count)

func remove_ball():
	print('remove ball called')
	ball_count = ball_count - 1
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

func reset_level():
	# Reset the ball to its initial state/position
	ball_node.reset_ball()
	# Reset the launch flag so the player must launch the ball again
	launched_once = false

	print("Bricks spawned for Level ", current_level)
