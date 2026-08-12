extends TextureRect

const STAGE_FRAME := preload("res://assets/art/ui/character/hero_stage_frame.png")


func _ready() -> void:
	texture = STAGE_FRAME
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
