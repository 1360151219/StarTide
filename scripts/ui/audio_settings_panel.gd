extends Control

const UiFactory = preload("res://scripts/ui/ui_factory.gd")
const SunlitCardStyle = preload("res://scripts/ui/sunlit_card_style.gd")
const SETTINGS_MEDALLION := preload("res://assets/art/ui/home/settings_medallion.png")

var audio: Node
var compact_mode := false
var launcher_button: Button
var launcher_glyph: TextureRect
var launcher_tween: Tween
var settings_card: Panel
var close_button: Button
var music_button: Button
var sfx_button: Button
var music_slider: HSlider
var sfx_slider: HSlider
var music_value_label: Label
var sfx_value_label: Label


func configure(audio_manager: Node, compact := false) -> void:
	audio = audio_manager
	compact_mode = compact
	z_index = 30
	if compact_mode:
		size = Vector2(60, 60)
		_build_launcher()
		settings_card = _build_card(Vector2(-326, 70), Vector2(392, 236), true)
		settings_card.z_index = 100
		settings_card.visible = false
	else:
		size = Vector2(356, 220)
		settings_card = _build_card(Vector2.ZERO, size, false)
	if audio.has_signal("settings_changed"):
		audio.settings_changed.connect(refresh)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if compact_mode and settings_card.visible and event.is_action_pressed("ui_cancel"):
		_close_from_button()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	if not is_instance_valid(audio):
		return
	_refresh_channel("music", audio.music_enabled, audio.music_volume)
	_refresh_channel("sfx", audio.sfx_enabled, audio.sfx_volume)
	if is_instance_valid(launcher_button):
		var muted: bool = not audio.music_enabled and not audio.sfx_enabled
		launcher_glyph.modulate = Color(0.62, 0.66, 0.63, 0.78) if muted else Color.WHITE


func open_popup() -> void:
	if compact_mode:
		settings_card.visible = true


func close_popup() -> void:
	if compact_mode:
		settings_card.visible = false


func _build_launcher() -> void:
	launcher_button = Button.new()
	launcher_button.name = "SettingsButton"
	launcher_button.size = size
	launcher_button.tooltip_text = "声音设置"
	launcher_button.accessibility_name = "声音设置"
	launcher_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		launcher_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	launcher_button.pressed.connect(_toggle_popup)
	launcher_button.button_down.connect(_set_launcher_pressed.bind(true))
	launcher_button.button_up.connect(_set_launcher_pressed.bind(false))
	launcher_button.mouse_entered.connect(_set_launcher_hovered.bind(true))
	launcher_button.mouse_exited.connect(_set_launcher_hovered.bind(false))
	launcher_button.focus_entered.connect(_set_launcher_hovered.bind(true))
	launcher_button.focus_exited.connect(_set_launcher_hovered.bind(false))
	add_child(launcher_button)
	launcher_glyph = TextureRect.new()
	launcher_glyph.name = "SettingsMedallion"
	launcher_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	launcher_glyph.texture = SETTINGS_MEDALLION
	launcher_glyph.size = size
	launcher_glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	launcher_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	launcher_button.add_child(launcher_glyph)
	_set_launcher_hovered(false)


func _set_launcher_pressed(pressed: bool) -> void:
	if not is_instance_valid(launcher_glyph):
		return
	if is_instance_valid(launcher_tween) and launcher_tween.is_valid():
		launcher_tween.kill()
	launcher_tween = create_tween()
	launcher_tween.set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	launcher_tween.tween_property(launcher_glyph, "position", Vector2(1, 2) if pressed else Vector2.ZERO, 0.08 if pressed else 0.12)
	launcher_tween.tween_property(launcher_glyph, "size", Vector2(58, 58) if pressed else size, 0.08 if pressed else 0.12)


func _set_launcher_hovered(hovered: bool) -> void:
	if is_instance_valid(launcher_glyph):
		launcher_glyph.self_modulate = Color.WHITE if hovered else Color(0.94, 0.97, 0.96, 1.0)


func _build_card(at: Vector2, card_size: Vector2, closable: bool) -> Panel:
	var card := Panel.new()
	card.position = at
	card.size = card_size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	SunlitCardStyle.apply_panel(card, UiFactory.SURFACE, UiFactory.PRIMARY, 10.0, true, true, "canvas")
	add_child(card)
	var title := UiFactory.surface_label("声音设置", 24, UiFactory.INK)
	title.position = Vector2(20, 13)
	title.size = Vector2(card_size.x - 112.0, 32)
	card.add_child(title)
	var hint := UiFactory.surface_label("音乐营造氛围，音效传达战斗反馈", 13, UiFactory.MUTED_INK)
	hint.position = Vector2(20, 43)
	hint.size = Vector2(card_size.x - 40.0, 24)
	card.add_child(hint)
	if closable:
		close_button = Button.new()
		close_button.position = Vector2(card_size.x - 84.0, 12)
		close_button.size = Vector2(64, 40)
		close_button.text = "完成"
		close_button.add_theme_font_size_override("font_size", 14)
		UiFactory.apply_secondary_button(close_button)
		close_button.pressed.connect(_close_from_button)
		card.add_child(close_button)
	_build_channel_row(card, "music", "背景音乐", 72.0)
	_build_channel_row(card, "sfx", "战斗音效", 145.0)
	return card


func _build_channel_row(parent: Control, kind: String, display_name: String, y: float) -> void:
	var row := Panel.new()
	row.position = Vector2(16, y)
	row.size = Vector2(parent.size.x - 32.0, 62)
	SunlitCardStyle.apply_panel(row, UiFactory.SURFACE_ALT, Color(UiFactory.PRIMARY, 0.48), 8.0, false, true, "ribbon")
	parent.add_child(row)
	var name_label := UiFactory.surface_label(display_name, 17, UiFactory.INK)
	name_label.position = Vector2(14, 4)
	name_label.size = Vector2(138, 26)
	row.add_child(name_label)
	var toggle_x := row.size.x - 82.0
	var value_label := UiFactory.surface_label("100%", 14, UiFactory.PRIMARY_DARK)
	value_label.position = Vector2(toggle_x - 56.0, 6)
	value_label.size = Vector2(48, 24)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	var slider := _make_slider(kind, Vector2(14, 34), Vector2(toggle_x - 28.0, 20))
	row.add_child(slider)
	var toggle := Button.new()
	toggle.position = Vector2(toggle_x, 10)
	toggle.size = Vector2(68, 42)
	toggle.add_theme_font_size_override("font_size", 14)
	toggle.pressed.connect(_toggle_channel.bind(kind))
	row.add_child(toggle)
	if kind == "music":
		music_button = toggle
		music_slider = slider
		music_value_label = value_label
	else:
		sfx_button = toggle
		sfx_slider = slider
		sfx_value_label = value_label
		sfx_slider.drag_ended.connect(_preview_sfx)


func _make_slider(kind: String, at: Vector2, slider_size: Vector2) -> HSlider:
	var slider := HSlider.new()
	slider.position = at
	slider.size = slider_size
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.scrollable = false
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var track := UiFactory.flat_bar_style(Color(UiFactory.MUTED_INK, 0.22), 5.0)
	track.content_margin_top = 5.0
	track.content_margin_bottom = 5.0
	var fill := UiFactory.flat_bar_style(UiFactory.PRIMARY, 5.0)
	fill.content_margin_top = 5.0
	fill.content_margin_bottom = 5.0
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.value_changed.connect(_set_volume.bind(kind))
	return slider


func _refresh_channel(kind: String, enabled: bool, volume: float) -> void:
	var button := music_button if kind == "music" else sfx_button
	var slider := music_slider if kind == "music" else sfx_slider
	var value_label := music_value_label if kind == "music" else sfx_value_label
	button.text = "开启" if enabled else "关闭"
	UiFactory.apply_secondary_button(button, enabled)
	slider.set_value_no_signal(volume * 100.0)
	slider.editable = enabled
	slider.modulate = Color.WHITE if enabled else Color(0.52, 0.61, 0.6, 0.5)
	value_label.text = "%d%%" % roundi(volume * 100.0)
	value_label.modulate = Color.WHITE if enabled else Color(0.52, 0.61, 0.6, 0.72)


func _toggle_popup() -> void:
	settings_card.visible = not settings_card.visible
	audio.play_sfx("ui_select", -2.0)


func _close_from_button() -> void:
	close_popup()
	audio.play_sfx("ui_confirm", -2.0)


func _toggle_channel(kind: String) -> void:
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


func _preview_sfx(value_changed: bool) -> void:
	if value_changed and audio.sfx_enabled:
		audio.play_sfx("ui_confirm", -2.0)
