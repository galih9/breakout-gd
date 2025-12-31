extends StaticBody2D

enum BrickType {
	NORMAL,
	MOVING,
	BLOCK,
	BALL,
	POWER
}

@export var brick_texture: Texture2D
@export var max_hp: int = 1

var current_hp: int
var can_be_destroyed: bool = true

var current_point_index: int = 0
var target_position: Vector2
var is_waiting: bool = false
var wait_timer: float = 0.0
var movement_direction: int = 1
var original_speed: float
var speed_modifier: float = 1.0
signal brick_damaged(points)

func _ready():
	if brick_texture != null:
		$Sprite2D.texture = brick_texture
	setup_brick_type()


func setup_brick_type():
	current_hp = max_hp if can_be_destroyed else 0 

func _process(delta):
	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false

func apply_damage(amount: int):
	if not can_be_destroyed:
		return

	emit_signal("brick_damaged", 1000)
	current_hp -= amount

	if current_hp <= 0:
		queue_free()

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
