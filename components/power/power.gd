extends RigidBody2D

@export var fall_speed: float = 200.0
@export var power_type: Generator.POWER_TYPES = Generator.POWER_TYPES.NONE

var is_falling: bool = false

func _ready():
	# Set collision layers/masks as needed
	collision_layer = 4  # Power-up layer
	collision_mask = 2   # Paddle layer

func start_falling():
	"""Call this when the power block should start falling"""
	is_falling = true
	linear_velocity = Vector2(0, fall_speed)

func _physics_process(_delta):
	if is_falling:
		# Keep constant downward velocity
		linear_velocity.x = 0  # No horizontal drift
		linear_velocity.y = fall_speed
		
		# Remove power block if it goes off screen
		if global_position.y > get_viewport().get_visible_rect().size.y + 100:
			queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("pads"):
		var pad_ref = get_tree().get_nodes_in_group("pads")
		print(pad_ref, 'power parent')
		pad_ref[0].widen_pad()
		queue_free()
	if body.is_in_group("bottom_walls"):
		queue_free()
