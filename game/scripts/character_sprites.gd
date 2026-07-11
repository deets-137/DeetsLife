class_name CharacterSprites
extends RefCounted
## Builds a SpriteFrames from a character folder by filename convention, so a
## character IS a folder of PNGs in assets/sprites/<name>/ — no scene edits:
##   <verb>_<facing>.png  →  animation "<verb>_<facing>"
## (idle_down.png, walk_side.png, sit_up.png, ...). A strip wider than one frame
## is sliced automatically: frame width comes from that facing's idle, so a
## 128px walk strip on a 32px rig is 4 frames. Only files that exist become
## animations — sparse rigs (an NPC who only sits) are fine.

const FACINGS := ["down", "up", "side"]
const VERBS := ["idle", "walk", "sit"]
const DEFAULT_FPS := { "idle": 5.0, "walk": 7.0, "sit": 5.0 }


static func build(character: String, fps := {}) -> SpriteFrames:
	var dir := "res://assets/sprites/%s" % character
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for facing in FACINGS:
		var idle_path := "%s/idle_%s.png" % [dir, facing]
		if not ResourceLoader.exists(idle_path):
			push_warning("CharacterSprites: %s has no idle_%s.png; skipping facing" % [character, facing])
			continue
		var frame_w: int = (load(idle_path) as Texture2D).get_width()
		for verb in VERBS:
			var path := "%s/%s_%s.png" % [dir, verb, facing]
			if not ResourceLoader.exists(path):
				continue
			var tex: Texture2D = load(path)
			var anim := "%s_%s" % [verb, facing]
			sf.add_animation(anim)
			sf.set_animation_speed(anim, fps.get(verb, DEFAULT_FPS[verb]))
			@warning_ignore("integer_division")
			var count := maxi(1, tex.get_width() / frame_w)
			if count == 1:
				sf.add_frame(anim, tex)
				continue
			for i in count:
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(i * frame_w, 0, frame_w, tex.get_height())
				sf.add_frame(anim, at)
	return sf
