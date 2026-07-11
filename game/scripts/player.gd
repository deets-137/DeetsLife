extends CharacterBody2D
## Isometric player movement. Screen-space input with the vertical axis halved
## so walking follows the 2:1 tile grid.

const SPEED := 260.0

## Seated visual lift, px. The seat anchor is the stool's south CORNER (chosen
## for Y-sorting); this raises the sprite only, centering the body over the
## stool and onto the cushion, without moving the node the sort reads.
const SIT_LIFT := 16.0

## Which assets/sprites/<character>/ rig this body wears; multiplayer and the
## character creator will point this at other folders.
@export var character := "deets"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _room: Node2D = get_parent()  # main.tscn roots the player under the room

var _facing := "down"
var _seat := {}                 # the room's seat dict while seated; empty = standing
var _stand_pos := Vector2.ZERO  # where we sat down from; standing returns here


func _ready() -> void:
	sprite.sprite_frames = CharacterSprites.build(character)
	sprite.play("idle_down")


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not _seat.is_empty():
		# Seated: interact or any movement stands back up (and the movement
		# then carries through this same frame, so stepping away feels direct).
		if Input.is_action_just_pressed("interact") or input != Vector2.ZERO:
			_stand()
		else:
			return
	elif Input.is_action_just_pressed("interact") and _room.has_method("request_seat"):
		var seat: Dictionary = _room.request_seat(position)
		if not seat.is_empty():
			_sit(seat)
			return
	velocity = Vector2(input.x, input.y * 0.5) * SPEED
	move_and_slide()
	_update_animation(input)


func _sit(seat: Dictionary) -> void:
	_seat = seat
	_stand_pos = position
	position = seat.pos
	velocity = Vector2.ZERO
	_facing = seat.facing
	sprite.flip_h = seat.flip
	sprite.offset.y -= SIT_LIFT
	sprite.play("sit_" + seat.facing)


func _stand() -> void:
	position = _stand_pos
	_room.release_seat(_seat)
	_seat = {}
	sprite.offset.y += SIT_LIFT
	sprite.flip_h = false  # seat flip mirrors the diagonal sit art; idle up/down art is unmirrored
	sprite.play("idle_" + _facing)


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
