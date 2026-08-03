extends RefCounted

const HeroCatalog = preload("res://scripts/hero_catalog.gd")
const REQUIRED_METHODS := [
	"configure", "play_state", "set_active", "available_states",
]
const PREVIEW_SIZES := [
	{"label": "实战尺寸 · 96 px", "height": 96.0},
	{"label": "角色中心 · 188 px", "height": 188.0},
	{"label": "美术检查 · 360 px", "height": 360.0},
]
const DEFAULT_PREVIEW_HEIGHT := 188.0


static func configure_desktop_window() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("mobile"):
		return
	var window: Window = Engine.get_main_loop().root.get_window()
	window.min_size = Vector2i(960, 720)
	if window.size.x < 960 or window.size.y < 720:
		window.size = Vector2i(1180, 720)
	DisplayServer.window_set_title("星潮守望者 · 角色帧动画预览器（开发专用）")


static func available_actions(rig: Node) -> PackedStringArray:
	if rig.has_method("available_states"):
		return rig.available_states()
	return PackedStringArray(["idle"])


static func populate_heroes(selector: OptionButton) -> void:
	selector.clear()
	for hero_id in HeroCatalog.ids():
		selector.add_item(str(HeroCatalog.hero(hero_id)["name"]))
		selector.set_item_metadata(selector.item_count - 1, hero_id)


static func populate_actions(selector: OptionButton, rig: Node) -> void:
	selector.clear()
	for action_id in available_actions(rig):
		selector.add_item(action_name(action_id))
		selector.set_item_metadata(selector.item_count - 1, action_id)
	if selector.item_count > 0:
		selector.select(0)


static func populate_preview_sizes(selector: OptionButton) -> void:
	selector.clear()
	var default_index := 0
	for index in range(PREVIEW_SIZES.size()):
		var option: Dictionary = PREVIEW_SIZES[index]
		selector.add_item(str(option["label"]))
		selector.set_item_metadata(selector.item_count - 1, float(option["height"]))
		if is_equal_approx(float(option["height"]), DEFAULT_PREVIEW_HEIGHT):
			default_index = index
	selector.select(default_index)


static func has_preview_api(rig: Node) -> bool:
	for method_name in REQUIRED_METHODS:
		if not rig.has_method(method_name):
			return false
	return true


static func hero_name(hero_id: String) -> String:
	return str(HeroCatalog.hero(hero_id)["name"])


static func action_name(action_id: String) -> String:
	return {
		"menu_idle": "菜单待机",
		"menu_react": "菜单互动",
		"idle": "战斗待机",
		"run": "奔跑",
		"cast": "施法",
		"hit": "受击",
		"victory": "胜利",
	}.get(action_id, action_id)


static func selected_id(selector: OptionButton, index: int) -> String:
	return str(selector.get_item_metadata(index)) if index >= 0 and index < selector.item_count else ""


static func selected_preview_height(selector: OptionButton, index: int) -> float:
	if index < 0 or index >= selector.item_count:
		return DEFAULT_PREVIEW_HEIGHT
	return float(selector.get_item_metadata(index))
