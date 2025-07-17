extends StaticBody2D

@export var brick_texture: Texture2D

func _ready():
	if brick_texture != null:
		$Sprite2D.texture = brick_texture
