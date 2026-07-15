extends Control

const ScreenLayout = preload("res://scripts/ui/screen_layout.gd")


func _init() -> void:
	size = ScreenLayout.DESIGN_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()


func layout_in_rect(safe_rect: Rect2) -> void:
	position = ScreenLayout.design_position(safe_rect)
	size = ScreenLayout.DESIGN_SIZE


func _layout() -> void:
	layout_in_rect(ScreenLayout.current_safe_rect(get_viewport()))
