extends Node2D
## Graybox era-room: builds a checkered isometric floor and NW/NE walls from
## the placeholder tiles at runtime, and keeps the player on the floor.
## Tile coords: u grows toward screen lower-right, v toward lower-left.
## World origin = center of tile (0, 0).

const TILE_W := 128
const TILE_H := 64
const WALL_PX_H := 112  # wall texture height (80 face + 32 slope)

@export var room_width := 10  # tiles along u
@export var room_depth := 8   # tiles along v

var _floor_a: Texture2D = preload("res://assets/tiles/floor_beige.png")
var _floor_b: Texture2D = preload("res://assets/tiles/floor_beige_alt.png")
var _wall_nw: Texture2D = preload("res://assets/tiles/wall_nw.png")
var _wall_ne: Texture2D = preload("res://assets/tiles/wall_ne.png")

@onready var _player: CharacterBody2D = $Player


func _ready() -> void:
	y_sort_enabled = true
	_build_floor()
	_build_walls()
	_player.position = tile_to_world((room_width - 1) / 2.0, (room_depth - 1) / 2.0)


func _physics_process(_delta: float) -> void:
	# Graybox bounds: clamp the player to the floor diamond.
	var t := world_to_tile(_player.position)
	t.x = clampf(t.x, -0.1, room_width - 0.6)
	t.y = clampf(t.y, -0.1, room_depth - 0.6)
	_player.position = tile_to_world(t.x, t.y)


func tile_to_world(u: float, v: float) -> Vector2:
	return Vector2((u - v) * (TILE_W / 2.0), (u + v) * (TILE_H / 2.0))


func world_to_tile(p: Vector2) -> Vector2:
	var x := p.x / (TILE_W / 2.0)
	var y := p.y / (TILE_H / 2.0)
	return Vector2((x + y) * 0.5, (y - x) * 0.5)


func _build_floor() -> void:
	var floor_root := Node2D.new()
	floor_root.name = "Floor"
	floor_root.z_index = -10
	add_child(floor_root)
	for u in room_width:
		for v in room_depth:
			var s := Sprite2D.new()
			s.texture = _floor_a if (u + v) % 2 == 0 else _floor_b
			s.position = tile_to_world(u, v)
			floor_root.add_child(s)


func _build_walls() -> void:
	for u in room_width:
		var c := tile_to_world(u, 0)
		_add_wall(_wall_ne, c + Vector2(0, -16), Vector2(0, -(WALL_PX_H - 16)))
	for v in room_depth:
		var c := tile_to_world(0, v)
		_add_wall(_wall_nw, c + Vector2(-32, -16), Vector2(-32, -(WALL_PX_H - 16)))


func _add_wall(tex: Texture2D, pos: Vector2, off: Vector2) -> void:
	# position = base midpoint of the wall (its Y-sort point); offset shifts the
	# texture so it draws upward from that base.
	var s := Sprite2D.new()
	s.centered = false
	s.texture = tex
	s.position = pos
	s.offset = off
	add_child(s)
