extends Node2D
## Graybox multi-room map: builds every room's floor and NW/NE walls at runtime
## from per-room assets in assets/rooms/<name>/, leaves door gaps in the walls,
## and builds segment colliders along walls and floor boundaries so the player's
## CharacterBody2D collides and slides normally (doors are the only way between rooms).
## Tile coords: u grows toward screen lower-right, v toward lower-left.
## World origin = center of tile (0, 0).

const TILE_W := 128
const TILE_H := 64
const WALL_PX_H := 112  # wall texture height (80 face + 32 slope)
const WALL_STRIPS := 4  # Y-sort slices per wall tile (see _add_wall)

## Each room draws from assets/rooms/<key>/: floor_a, floor_b, wall_nw, wall_ne.
## Walls go on the NW (west-column) and NE (north-row) edges; SE/SW stay open
## to the camera. The hall skips its NE wall — it opens straight into room D.
const ROOMS := {
	"entry": { "origin": Vector2i(0, 0), "size": Vector2i(5, 3) },
	"room_a": { "origin": Vector2i(-3, -5), "size": Vector2i(5, 5) },
	"room_b": { "origin": Vector2i(3, -5), "size": Vector2i(5, 5) },
	"room_c": { "origin": Vector2i(-3, 0), "size": Vector2i(3, 3) },
	"room_d": { "origin": Vector2i(0, -10), "size": Vector2i(5, 5) },
	"hall": { "origin": Vector2i(2, -5), "size": Vector2i(1, 5), "no_ne_wall": true },
}

## Wall tiles skipped to leave doorways (frames get hand-drawn art later).
const DOOR_GAPS_NE := [Vector2i(0, 0), Vector2i(2, 0), Vector2i(4, 0)]  # entry → A, hall, B
const DOOR_GAPS_NW := [Vector2i(0, 2)]  # entry → C

const SPAWN_TILE := Vector2i(4, 2)  # bottom-right of the entry, on the mat

## Props: sprite from assets/props/<tex>.png, bottom-center anchored at the south
## corner of a square footprint centered on "at" (fractional tile coords are fine —
## the stools sit tucked toward the table, a quarter tile off their tile's center).
## "half" = footprint half-extent in tiles; "collider_half" = the solid diamond.
## Colliders match footprints so the stool edges seal against the table edge —
## smaller colliders leave corner pockets the player can wedge into, standing
## visually inside the furniture. The stools' colliders will toggle off when
## sitting gets built.
## "seat_face" marks a prop as sittable: interact nearby snaps the player onto it,
## facing that tile (the table), with the prop's collider off while occupied.
const PROPS := [
	{ "tex": "mahjong_table", "at": Vector2(-2.0, 1.0), "half": 0.5, "collider_half": 0.5 },
	{ "tex": "mahjong_chair", "at": Vector2(-2.0, 0.25), "half": 0.25, "collider_half": 0.25, "seat_face": Vector2(-2.0, 1.0) },  # NE seat
	{ "tex": "mahjong_chair", "at": Vector2(-2.0, 1.75), "half": 0.25, "collider_half": 0.25, "seat_face": Vector2(-2.0, 1.0) },  # SW seat
	{ "tex": "mahjong_chair", "at": Vector2(-2.75, 1.0), "half": 0.25, "collider_half": 0.25, "seat_face": Vector2(-2.0, 1.0) },  # NW seat
	{ "tex": "mahjong_chair", "at": Vector2(-1.25, 1.0), "half": 0.25, "collider_half": 0.25, "seat_face": Vector2(-2.0, 1.0) },  # SE seat
]

## Interact-to-sit reach: squared, in screen px with y doubled back to iso-fair
## distance. 80px covers standing in the lane beside a stool, not across the table.
const SEAT_REACH_SQ := 80.0 * 80.0

## Wall-hung art: a 64×112 overlay PNG aligned to one wall tile's canvas (same
## coordinates as that room's wall texture, transparent except the piece), from
## assets/rooms/<room>/<tex>.png. Rendered through the wall-strip pipeline with a
## tiny sort bias so it draws over the wall but still behind anyone in the room.
const WALL_ART := [
	{ "room": "room_c", "tex": "art_nw_left", "tile": Vector2i(-3, 2), "nw": true },   # portrait, west wall left tile
	{ "room": "room_c", "tex": "art_nw_right", "tile": Vector2i(-3, 0), "nw": true },  # landscape, west wall right tile
	{ "room": "room_c", "tex": "art_ne_mid", "tile": Vector2i(-2, 0), "nw": false },   # portrait, east wall middle tile
]

@onready var _player: CharacterBody2D = $Player

var _floor_root: Node2D
var _walkable := {}     # Vector2i(u, v) -> true
var _blocked_nw := {}   # Vector2i(u, v): wall between (u, v) and (u-1, v)
var _blocked_ne := {}   # Vector2i(u, v): wall between (u, v) and (u, v-1)
var _seats := []        # { pos, cs, facing, flip, taken } per seat prop


func _ready() -> void:
	y_sort_enabled = true
	_floor_root = Node2D.new()
	_floor_root.name = "Floor"
	_floor_root.z_index = -10
	add_child(_floor_root)
	for room_name in ROOMS:
		_build_room(room_name, ROOMS[room_name])
	_build_wall_art()
	_build_mat()
	_build_props()
	_build_collision()
	_player.position = tile_to_world(SPAWN_TILE.x, SPAWN_TILE.y)


func tile_to_world(u: float, v: float) -> Vector2:
	return Vector2((u - v) * (TILE_W / 2.0), (u + v) * (TILE_H / 2.0))


func world_to_tile(p: Vector2) -> Vector2:
	var x := p.x / (TILE_W / 2.0)
	var y := p.y / (TILE_H / 2.0)
	return Vector2((x + y) * 0.5, (y - x) * 0.5)


func _build_room(room_name: String, r: Dictionary) -> void:
	var o: Vector2i = r.origin
	var sz: Vector2i = r.size
	var dir := "res://assets/rooms/%s" % room_name
	var floor_a: Texture2D = load(dir + "/floor_a.png")
	var floor_b: Texture2D = load(dir + "/floor_b.png")
	for u in range(o.x, o.x + sz.x):
		for v in range(o.y, o.y + sz.y):
			_walkable[Vector2i(u, v)] = true
			var s := Sprite2D.new()
			s.texture = floor_a if (u + v) % 2 == 0 else floor_b
			s.position = tile_to_world(u, v)
			_floor_root.add_child(s)
	var wall_nw: Texture2D = load(dir + "/wall_nw.png")
	for v in range(o.y, o.y + sz.y):
		var t := Vector2i(o.x, v)
		if t in DOOR_GAPS_NW:
			_maybe_add_door(dir + "/door_nw.png", t, true)
			continue
		_blocked_nw[t] = true
		_add_wall(wall_nw, t, true)
	if r.get("no_ne_wall", false):
		return
	var wall_ne: Texture2D = load(dir + "/wall_ne.png")
	for u in range(o.x, o.x + sz.x):
		var t := Vector2i(u, o.y)
		if t in DOOR_GAPS_NE:
			_maybe_add_door(dir + "/door_ne.png", t, false)
			continue
		_blocked_ne[t] = true
		_add_wall(wall_ne, t, false)


func _build_mat() -> void:
	# Added after the floors so it draws on top of them, still under the player.
	var mat := Sprite2D.new()
	mat.texture = load("res://assets/rooms/entry/mat.png")
	mat.position = tile_to_world(SPAWN_TILE.x, SPAWN_TILE.y)
	_floor_root.add_child(mat)


func _maybe_add_door(path: String, t: Vector2i, nw: bool) -> void:
	# Doorframe art is optional: drop door_nw.png / door_ne.png (64×112, transparent
	# opening) into the room's folder and it renders in the wall gap. Never blocks.
	if ResourceLoader.exists(path):
		_add_wall(load(path), t, nw)


func _build_wall_art() -> void:
	# The 0.25px sort bias breaks the Y-sort tie with the wall strips underneath
	# (art wins) while staying far below any character's feet, which sit several
	# pixels south of the wall base at minimum.
	for a in WALL_ART:
		var tex: Texture2D = load("res://assets/rooms/%s/%s.png" % [a.room, a.tex])
		_add_wall(tex, a.tile, a.nw, 0.25)


func _add_wall(tex: Texture2D, t: Vector2i, nw: bool, sort_bias := 0.0) -> void:
	# Each wall tile is sliced into vertical strips, each Y-sorted at its own
	# piece of the sloping base line. One sprite per tile would sort by the base
	# midpoint, and the base spans 32px of Y — so anything standing near the
	# high or low end of the slope could draw on the wrong side of the wall.
	var c := tile_to_world(t.x, t.y)
	var w := 64.0 / WALL_STRIPS
	for i in WALL_STRIPS:
		var strip_mid := i * w + w * 0.5  # x along the wall, from its left end
		var s := Sprite2D.new()
		s.centered = false
		s.texture = tex
		s.region_enabled = true
		s.region_rect = Rect2(i * w, 0, w, WALL_PX_H)
		if nw:  # base runs from (c.x-64, c.y) up to (c.x, c.y-32)
			s.position = Vector2(c.x - 64 + i * w, c.y - strip_mid * 0.5)
		else:   # base runs from (c.x, c.y-32) down to (c.x+64, c.y)
			s.position = Vector2(c.x + i * w, c.y - 32 + strip_mid * 0.5)
		s.position.y += sort_bias
		s.offset = Vector2(0, (c.y - WALL_PX_H) - s.position.y)
		add_child(s)


func _build_props() -> void:
	for p in PROPS:
		var tex: Texture2D = load("res://assets/props/%s.png" % p.tex)
		# Anchor bottom-center at the footprint's south corner (its Y-sort point);
		# size comes from the texture, so redrawn art can be any canvas size.
		var base: Vector2 = tile_to_world(p.at.x, p.at.y) + Vector2(0, p.half * TILE_H)
		var s := Sprite2D.new()
		s.centered = false
		s.texture = tex
		s.position = base
		s.offset = Vector2(-tex.get_width() / 2.0, -float(tex.get_height()))
		add_child(s)
		var body := StaticBody2D.new()
		body.position = tile_to_world(p.at.x, p.at.y)
		var shape := ConvexPolygonShape2D.new()
		var ch: float = p.collider_half
		shape.points = PackedVector2Array([
			Vector2(0, -TILE_H * ch), Vector2(TILE_W * ch, 0),
			Vector2(0, TILE_H * ch), Vector2(-TILE_W * ch, 0),
		])
		var cs := CollisionShape2D.new()
		cs.shape = shape
		body.add_child(cs)
		add_child(body)
		if p.has("seat_face"):
			var f: Array = _facing_toward(p.at, p.seat_face)
			_seats.append({
				# +1px past the prop's own Y-sort point so the sitter draws over it.
				"pos": base + Vector2(0, 1),
				"cs": cs,
				"facing": f[0], "flip": f[1],
				"taken": false,
			})


func _facing_toward(from_t: Vector2, to_t: Vector2) -> Array:
	# [animation facing, flip_h] for a seat looking toward the table. Every
	# sitter faces the table center, so seats read as the four diagonals from
	# just two drawn poses + mirror: sit_down faces down-LEFT (flip for
	# down-right), sit_up faces up-LEFT (flip for up-right) — same
	# art-faces-left convention as the side walk art.
	var d := tile_to_world(to_t.x, to_t.y) - tile_to_world(from_t.x, from_t.y)
	return ["down" if d.y > 0.0 else "up", d.x > 0.0]


func request_seat(from: Vector2) -> Dictionary:
	## Claim the nearest free seat within reach of `from`, turning its collider
	## off. Returns {} when none. Caller stands back up via release_seat.
	var best := {}
	var best_d := SEAT_REACH_SQ
	for s in _seats:
		if s.taken:
			continue
		var d: Vector2 = s.pos - from
		var dist: float = d.x * d.x + (d.y * 2.0) * (d.y * 2.0)
		if dist < best_d:
			best_d = dist
			best = s
	if not best.is_empty():
		best.taken = true
		best.cs.set_deferred("disabled", true)
	return best


func release_seat(seat: Dictionary) -> void:
	seat.taken = false
	seat.cs.set_deferred("disabled", false)


func _build_collision() -> void:
	# One StaticBody2D with a segment along every impassable tile edge: wall
	# edges, plus the floor's outer boundary. Door gaps get no segment, so the
	# player's feet box collides and slides with regular move_and_slide physics.
	var body := StaticBody2D.new()
	body.name = "WallColliders"
	add_child(body)
	for t: Vector2i in _walkable:
		# NW edge of t (between t and its -u neighbor), and the same edge seen
		# from the far side when the +u neighbor is off the map.
		if _blocked_nw.has(t) or not _walkable.has(t + Vector2i(-1, 0)):
			_add_edge_segment(body, t, true)
		if not _walkable.has(t + Vector2i(1, 0)):
			_add_edge_segment(body, t + Vector2i(1, 0), true)
		# NE edge of t (between t and its -v neighbor), same trick for +v.
		if _blocked_ne.has(t) or not _walkable.has(t + Vector2i(0, -1)):
			_add_edge_segment(body, t, false)
		if not _walkable.has(t + Vector2i(0, 1)):
			_add_edge_segment(body, t + Vector2i(0, 1), false)


func _add_edge_segment(body: StaticBody2D, t: Vector2i, nw: bool) -> void:
	var shape := SegmentShape2D.new()
	if nw:  # west edge of tile t: from its north corner to its west corner
		shape.a = tile_to_world(t.x - 0.5, t.y - 0.5)
		shape.b = tile_to_world(t.x - 0.5, t.y + 0.5)
	else:   # north edge of tile t: from its north corner to its east corner
		shape.a = tile_to_world(t.x - 0.5, t.y - 0.5)
		shape.b = tile_to_world(t.x + 0.5, t.y - 0.5)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)
