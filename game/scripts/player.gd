extends CharacterBody2D
## Isometric player movement. Screen-space input with the vertical axis halved
## so walking follows the 2:1 tile grid.

const SPEED := 260.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _facing := "down"


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = Vector2(input.x, input.y * 0.5) * SPEED
	move_and_slide()
	_update_animation(input)


func _update_animation(input: Vector2) -> void:
	if input != Vector2.ZERO:
		if absf(input.x) >= absf(input.y):
			_facing = "side"
			sprite.flip_h = input.x > 0.0  # side art faces left
		else:
			_facing = "up" if input.y < 0.0 else "down"
	var anim := ("walk_" if input != Vector2.ZERO else "idle_") + _facing
	if sprite.animation != anim:
		sprite.play(anim)
