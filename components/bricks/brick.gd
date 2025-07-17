extends StaticBody2D

@export var brick_texture: Texture2D
@export var max_hp: int = 3

@onready var hp_label = $Label
var current_hp: int

func _ready():
	if brick_texture != null:
		$Sprite2D.texture = brick_texture
	current_hp = max_hp
	update_label()


func apply_damage(amount: int):
	current_hp -= amount
	update_label()
	if current_hp <= 0:
		queue_free()

func update_label():
	if hp_label:
		hp_label.text = str(current_hp)
