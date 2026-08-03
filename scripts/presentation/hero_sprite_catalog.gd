class_name HeroSpriteCatalog
extends RefCounted

const DEFAULT_HERO_ID := "star_warden"
const HERO_IDS := ["star_warden", "ember_ranger"]
const STATES := [
	"menu_idle", "menu_react", "idle", "run", "cast", "hit", "victory",
]
const ACTION_DURATIONS := {
	"menu_react": 0.76,
	"cast": 0.46,
	"hit": 0.28,
	"victory": 1.55,
}
const FRAME_SIZE := Vector2i(512, 512)
const FOOT_BASELINE := 488.0
const ART_HEIGHT := 475.0
const GENERATED_ROOT := "res://assets/generated/hero_chibi"
const FALLBACK_TEXTURES := {
	"star_warden": "res://assets/art/characters/star_tide_warden.png",
	"ember_ranger": "res://assets/art/characters/emberwing_ranger.png",
}
const ANIMATIONS := {
	"menu_idle": {
		"poses": ["idle"],
		"weights": [1.0],
		"duration": 3.0,
		"loop": true,
	},
	"menu_react": {
		"poses": ["idle", "victory", "idle"],
		"weights": [1.0, 2.0, 1.0],
		"duration": 0.76,
		"loop": false,
	},
	"idle": {
		"poses": ["idle"],
		"weights": [1.0],
		"duration": 1.8,
		"loop": true,
	},
	"run": {
		"poses": ["run_contact", "run_pass"],
		"weights": [1.0, 1.0],
		"duration": 0.52,
		"loop": true,
	},
	"cast": {
		"poses": ["idle", "cast", "idle"],
		"weights": [1.0, 4.0, 1.0],
		"duration": 0.46,
		"loop": false,
	},
	"hit": {
		"poses": ["idle", "hit", "idle"],
		"weights": [1.0, 4.0, 2.0],
		"duration": 0.28,
		"loop": false,
	},
	"victory": {
		"poses": ["idle", "victory", "idle"],
		"weights": [1.0, 8.0, 1.0],
		"duration": 1.55,
		"loop": false,
	},
}


static func normalized_hero_id(hero_id: String) -> String:
	return hero_id if HERO_IDS.has(hero_id) else DEFAULT_HERO_ID


static func build_frames(
	hero_id: String,
	texture_overrides: Dictionary = {},
	allow_generated_assets := true
) -> SpriteFrames:
	var overridden_frames: Variant = texture_overrides.get("sprite_frames")
	if overridden_frames is SpriteFrames:
		return overridden_frames
	var normalized_id := normalized_hero_id(hero_id)
	var textures := _load_pose_textures(normalized_id, texture_overrides, allow_generated_assets)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for state_id in STATES:
		var config: Dictionary = ANIMATIONS[state_id]
		var animation_name := StringName(state_id)
		var weights: Array = config["weights"]
		var total_weight := 0.0
		for weight in weights:
			total_weight += float(weight)
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, bool(config["loop"]))
		frames.set_animation_speed(animation_name, total_weight / float(config["duration"]))
		var poses: Array = config["poses"]
		for index in range(poses.size()):
			frames.add_frame(
				animation_name,
				textures[str(poses[index])],
				float(weights[index])
			)
	return frames


static func pose_path(hero_id: String, pose_id: String) -> String:
	return "%s/%s/%s.png" % [GENERATED_ROOT, normalized_hero_id(hero_id), pose_id]


static func _load_pose_textures(
	hero_id: String,
	texture_overrides: Dictionary,
	allow_generated_assets: bool
) -> Dictionary:
	var fallback: Texture2D
	var textures := {}
	for pose_id in ["idle", "run_contact", "run_pass", "cast", "hit", "victory"]:
		var texture: Variant = texture_overrides.get(pose_id)
		if not texture is Texture2D and allow_generated_assets:
			var path := pose_path(hero_id, pose_id)
			if ResourceLoader.exists(path):
				texture = load(path)
		if not texture is Texture2D:
			if fallback == null:
				fallback = _normalized_fallback_texture(hero_id)
			texture = fallback
		textures[pose_id] = texture
	return textures


static func _normalized_fallback_texture(hero_id: String) -> Texture2D:
	var source: Texture2D = load(FALLBACK_TEXTURES[hero_id])
	var image := source.get_image()
	var bounds := _alpha_bounds(image)
	if bounds.size == Vector2i.ZERO:
		return source
	var cropped := image.get_region(bounds)
	var fit_scale := minf(
		450.0 / float(cropped.get_width()),
		450.0 / float(cropped.get_height())
	)
	cropped.resize(
		maxi(1, roundi(cropped.get_width() * fit_scale)),
		maxi(1, roundi(cropped.get_height() * fit_scale)),
		Image.INTERPOLATE_LANCZOS
	)
	var canvas := Image.create_empty(
		FRAME_SIZE.x,
		FRAME_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)
	canvas.fill(Color.TRANSPARENT)
	var target := Vector2i(
		(FRAME_SIZE.x - cropped.get_width()) / 2,
		roundi(FOOT_BASELINE) - cropped.get_height()
	)
	canvas.blit_rect(cropped, Rect2i(Vector2i.ZERO, cropped.get_size()), target)
	return ImageTexture.create_from_image(canvas)


static func _alpha_bounds(image: Image) -> Rect2i:
	var minimum := image.get_size()
	var maximum := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.01:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < 0:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
