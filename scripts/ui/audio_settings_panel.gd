extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")

var audio: Node
var music_button: Button
var sfx_button: Button
var music_slider: HSlider
var sfx_slider: HSlider


func configure(audio_manager: Node) -> void:
	audio = audio_manager
	size = Vector2(268, 76)
	music_button = _make_button("music", Vector2.ZERO)
	sfx_button = _make_button("sfx", Vector2(146, 0))
	music_slider = _make_slider("music", Vector2(0, 50))
	sfx_slider = _make_slider("sfx", Vector2(146, 50))
	if audio.has_signal("settings_changed"):
		audio.settings_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if not is_instance_valid(audio):
		return
	music_button.text = "♫ 音乐 %s" % ("%d%%" % roundi(audio.music_volume * 100.0) if audio.music_enabled else "关")
	sfx_button.text = "★ 音效 %s" % ("%d%%" % roundi(audio.sfx_volume * 100.0) if audio.sfx_enabled else "关")
	music_slider.set_value_no_signal(audio.music_volume * 100.0)
	sfx_slider.set_value_no_signal(audio.sfx_volume * 100.0)


func _make_button(kind: String, at: Vector2) -> Button:
	var button := Button.new()
	button.position = at
	button.size = Vector2(122, 44)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", UiFactory.button_style(Color(0.035, 0.06, 0.12, 0.94), Color("55708f")))
	button.add_theme_stylebox_override("hover", UiFactory.button_style(Color("173c63"), Color("70e8ff")))
	button.pressed.connect(_toggle.bind(kind))
	add_child(button)
	return button


func _make_slider(kind: String, at: Vector2) -> HSlider:
	var slider := HSlider.new()
	slider.position = at
	slider.size = Vector2(122, 22)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.scrollable = false
	slider.value_changed.connect(_set_volume.bind(kind))
	add_child(slider)
	return slider


func _toggle(kind: String) -> void:
	if kind == "music":
		audio.toggle_music()
	else:
		audio.toggle_sfx()
	audio.play_sfx("ui_select", -2.0)


func _set_volume(value: float, kind: String) -> void:
	if kind == "music":
		audio.set_music_volume(value / 100.0)
	else:
		audio.set_sfx_volume(value / 100.0)
