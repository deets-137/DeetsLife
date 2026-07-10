extends Node2D
## Dog follower. Trails the player along a breadcrumb path — so it walks where the
## player walked instead of cutting corners — then sits once it has been still a moment.

const SPEED := 300.0            # px/s; above the player's 260 so it can catch up
const FOLLOW_DISTANCE := 40.0   # path length kept between player and dog
const CRUMB_SPACING := 4.0      # min world distance between recorded path points
const ARRIVE_EPS := 1.5         # closer than this to the target counts as stopped
const SIT_DELAY := 0.7          # seconds of standing still before the dog sits

@export var player_path: NodePath

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _player: Node2D = get_node(player_path)

var _crumbs: PackedVector2Array = PackedVector2Array()
var _facing := "down"
var _still_time := 0.0


func _physics_process(delta: float) -> void:
	if _crumbs.is_empty():
		# Seeded here, not in _ready(): the room positions the player in its own
		# _ready(), which runs after ours.
		position = _player.position - Vector2(0, FOLLOW_DISTANCE * 0.5)
		_crumbs.append(position)
		return

	_record_crumb(_player.position)
	var target := _target_on_path()
	var moved := Vector2.ZERO
	var to_target := target - position
	if to_target.length() > ARRIVE_EPS:
		moved = to_target.limit_length(SPEED * delta)
		position += moved
	_update_animation(moved, delta)


func _record_crumb(p: Vector2) -> void:
	if _crumbs[_crumbs.size() - 1].distance_to(p) >= CRUMB_SPACING:
		_crumbs.append(p)
	_trim_crumbs()


func _trim_crumbs() -> void:
	# Keep only enough history to cover FOLLOW_DISTANCE, plus slack for the newest segment.
	var kept := 0.0
	var i := _crumbs.size() - 1
	while i > 0 and kept < FOLLOW_DISTANCE + CRUMB_SPACING * 2.0:
		kept += _crumbs[i].distance_to(_crumbs[i - 1])
		i -= 1
	if i > 0:
		_crumbs = _crumbs.slice(i)


func _target_on_path() -> Vector2:
	## Walk backwards from the player along the crumb trail, FOLLOW_DISTANCE of arc length.
	var head := _player.position
	var remaining := FOLLOW_DISTANCE
	for i in range(_crumbs.size() - 1, -1, -1):
		var b := _crumbs[i]
		var seg := head.distance_to(b)
		if seg >= remaining:
			return head.lerp(b, remaining / seg) if seg > 0.0 else head
		remaining -= seg
		head = b
	return head  # trail shorter than FOLLOW_DISTANCE: hold at its oldest point


func _update_animation(moved: Vector2, delta: float) -> void:
	if moved == Vector2.ZERO:
		_still_time += delta
	else:
		_still_time = 0.0
		# Undo the 2:1 vertical squash so the dog picks the same facing the player
		# would for this direction of travel.
		var dir := Vector2(moved.x, moved.y * 2.0)
		if absf(dir.x) >= absf(dir.y):
			_facing = "side"
			_sprite.flip_h = dir.x > 0.0  # side art faces left
		else:
			_facing = "up" if dir.y < 0.0 else "down"

	var anim: String
	if moved != Vector2.ZERO:
		anim = "walk_" + _facing
	elif _still_time >= SIT_DELAY:
		anim = "sit_" + _facing
	else:
		anim = "idle_" + _facing
	if _sprite.animation != anim:
		_sprite.play(anim)
