extends SceneTree
## Derives the missing animation frames of a character rig from a reference rig,
## by transferring the target's colors through the reference's hand-drawn frames.
## Never invents anatomy and NEVER overwrites an existing file — every output is
## an ordinary PNG the artist can touch up, safe from regeneration.
##
## Usage (from game/):
##   godot --headless --path . --script res://tools/derive_character.gd -- <target> [reference]
##
## The target is a folder in assets/sprites/ holding hand-drawn idle sources
## (idle_down.png at minimum; idle_side.png / idle_up.png for those facings),
## drawn over the reference's idles so silhouettes align. Every animation file
## the reference has and the target lacks gets derived, per facing. The
## reference defaults to "happy".
##
## How a pixel gets its color, in order:
##   1. positional — same spot, same reference color as the reference idle:
##      copy the target idle's color there (~85% of pixels).
##   2. nearest — anatomy that moved (legs mid-stride, tail): nearest pixel of
##      the same reference color in the idle donates its color. Part hints
##      (derive_hints.json beside the reference art) tag regions like the tail,
##      and tagged pixels only borrow from matching-tag donors — that keeps a
##      distinctly-colored tail its own color while it moves.
##   3. passthrough — colors the idles never contained (tongue, dust puffs)
##      stay the reference's color.

const SPRITES_DIR := "res://assets/sprites"
const FACINGS := ["down", "up", "side"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage: godot --headless --path . --script res://tools/derive_character.gd -- <target> [reference]")
		quit(1)
		return
	var target: String = args[0]
	var reference: String = args[1] if args.size() > 1 else "happy"
	quit(_derive(target, reference))


func _derive(target: String, reference: String) -> int:
	if target == reference:
		printerr("target and reference are the same rig (%s)" % target)
		return 1
	var ref_dir := "%s/%s" % [SPRITES_DIR, reference]
	var tgt_dir := "%s/%s" % [SPRITES_DIR, target]
	if not DirAccess.dir_exists_absolute(tgt_dir):
		printerr("no folder %s — create it with the hand-drawn idle sources first" % tgt_dir)
		return 1
	var hints := _load_hints(ref_dir)
	var derived := 0
	for facing in FACINGS:
		var idle_name := "idle_%s.png" % facing
		var ref_idle_path := "%s/%s" % [ref_dir, idle_name]
		var tgt_idle_path := "%s/%s" % [tgt_dir, idle_name]
		if not FileAccess.file_exists(ref_idle_path):
			continue
		if not FileAccess.file_exists(tgt_idle_path):
			print("skip facing '%s': %s has no %s to learn from" % [facing, target, idle_name])
			continue
		var ref_idle := Image.load_from_file(ref_idle_path)
		var tgt_idle := Image.load_from_file(tgt_idle_path)
		if ref_idle.get_size() != tgt_idle.get_size():
			printerr("%s: %s is %s but the reference idle is %s — draw over the reference so silhouettes align"
				% [target, idle_name, tgt_idle.get_size(), ref_idle.get_size()])
			return 1
		_warn_silhouette_drift(idle_name, ref_idle, tgt_idle)
		var samples := _collect_samples(ref_idle, tgt_idle, hints, "idle_%s" % facing)
		for file in _reference_pngs(ref_dir, facing):
			var out_path := "%s/%s" % [tgt_dir, file]
			if FileAccess.file_exists(out_path):
				print("keep  %s/%s (exists; never overwritten)" % [target, file])
				continue
			var ref_frame := Image.load_from_file("%s/%s" % [ref_dir, file])
			var out := _transfer(ref_frame, ref_idle, tgt_idle, samples, hints, file.get_basename())
			if out.save_png(out_path) != OK:
				printerr("failed writing %s" % out_path)
				return 1
			print("wrote %s/%s" % [target, file])
			derived += 1
	print("%d file(s) derived into %s/ — reimport in Godot picks them up" % [derived, tgt_dir])
	return 0


func _warn_silhouette_drift(idle_name: String, ref_idle: Image, tgt_idle: Image) -> void:
	# The transfer assumes the target is drawn over the reference's silhouette.
	# Pixels drawn outside it (or left empty inside it) still derive, but borrow
	# colors less reliably — tell the artist how far they've strayed.
	var drift := 0
	for x in ref_idle.get_width():
		for y in ref_idle.get_height():
			if (ref_idle.get_pixel(x, y).a == 0.0) != (tgt_idle.get_pixel(x, y).a == 0.0):
				drift += 1
	if drift > 0:
		print("note: %s differs from the reference silhouette by %d px — derivation quality drops as this grows" % [idle_name, drift])


func _reference_pngs(ref_dir: String, facing: String) -> Array[String]:
	# Every non-idle animation PNG the reference has for this facing.
	var out: Array[String] = []
	for f in DirAccess.get_files_at(ref_dir):
		if f.get_extension() == "png" and f.ends_with("_%s.png" % facing) and not f.begins_with("idle_"):
			out.append(f)
	out.sort()
	return out


func _load_hints(ref_dir: String) -> Dictionary:
	# derive_hints.json: { "parts": { "tail": { "<frame>": [x0, y0, x1, y1], ... } } }
	var path := "%s/derive_hints.json" % ref_dir
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data.get("parts", {}) if data is Dictionary else {}


func _part_at(hints: Dictionary, frame: String, x: int, y: int) -> String:
	for part in hints:
		var rect: Variant = hints[part].get(frame)
		if rect is Array and x >= int(rect[0]) and y >= int(rect[1]) and x <= int(rect[2]) and y <= int(rect[3]):
			return part
	return ""


func _collect_samples(ref_idle: Image, tgt_idle: Image, hints: Dictionary, idle_frame: String) -> Array:
	# One entry per opaque idle pixel: [x, y, ref rgba32, target color, part tag].
	var samples := []
	for x in ref_idle.get_width():
		for y in ref_idle.get_height():
			var c := ref_idle.get_pixel(x, y)
			if c.a == 0.0:
				continue
			samples.append([x, y, c.to_rgba32(), tgt_idle.get_pixel(x, y), _part_at(hints, idle_frame, x, y)])
	return samples


func _transfer(ref_frame: Image, ref_idle: Image, tgt_idle: Image, samples: Array,
		hints: Dictionary, frame_name: String) -> Image:
	var fw := ref_idle.get_width()
	var out := Image.create(ref_frame.get_width(), ref_frame.get_height(), false, Image.FORMAT_RGBA8)
	for x in ref_frame.get_width():
		var lx := x % fw
		for y in ref_frame.get_height():
			var c := ref_frame.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var key := c.to_rgba32()
			var part := _part_at(hints, frame_name, lx, y)
			var idle_c := ref_idle.get_pixel(lx, y)
			if part == "" and idle_c.a != 0.0 and idle_c.to_rgba32() == key:
				out.set_pixel(x, y, tgt_idle.get_pixel(lx, y))
				continue
			var best := -1
			var best_d := 0x7FFFFFFF
			var best_any := -1
			var best_any_d := 0x7FFFFFFF
			for i in samples.size():
				var s: Array = samples[i]
				if s[2] != key:
					continue
				var d: int = (s[0] - lx) * (s[0] - lx) + (s[1] - y) * (s[1] - y)
				if d < best_any_d:
					best_any_d = d
					best_any = i
				if s[4] == part and d < best_d:
					best_d = d
					best = i
			if best < 0:
				best = best_any
			out.set_pixel(x, y, samples[best][3] if best >= 0 else c)
	return out
