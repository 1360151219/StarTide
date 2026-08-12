extends Button

const EquipmentCatalog = preload("res://scripts/equipment_catalog.gd")
const CharacterStyle = preload("res://scripts/ui/character_ui_style.gd")
const CharacterAssets = preload("res://scripts/ui/character_asset_catalog.gd")
const SlotSilhouette = preload("res://scripts/ui/equipment_slot_silhouette.gd")
const SunlitLockBadge = preload("res://scripts/ui/sunlit_lock_badge.gd")

var slot_id := ""
var item_data: Dictionary = {}
var background_view: TextureRect
var icon_view: TextureRect
var empty_mark: Control
var lock_badge: Control


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	focus_mode = Control.FOCUS_ALL
	clip_contents = false
	background_view = TextureRect.new()
	background_view.name = "QualityBackground"
	background_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_view.stretch_mode = TextureRect.STRETCH_SCALE
	background_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_view)
	icon_view = TextureRect.new()
	icon_view.position = Vector2(10, 10)
	icon_view.size = Vector2(44, 44)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_view)
	empty_mark = SlotSilhouette.new()
	empty_mark.position = Vector2(12, 12)
	empty_mark.size = Vector2(40, 40)
	add_child(empty_mark)
	lock_badge = SunlitLockBadge.new()
	lock_badge.position = Vector2(15, 15)
	lock_badge.size = Vector2(34, 34)
	lock_badge.visible = false
	add_child(lock_badge)


func present(target_slot_id: String, item: Dictionary) -> void:
	slot_id = target_slot_id
	item_data = item
	disabled = false
	focus_mode = Control.FOCUS_ALL
	modulate = Color.WHITE
	var occupied := not item.is_empty()
	var rarity_id := str(item.get("rarity", "common"))
	background_view.texture = CharacterAssets.quality_texture(rarity_id if occupied else "common")
	icon_view.texture = item.get("icon") if occupied else null
	icon_view.visible = occupied
	empty_mark.visible = not occupied
	empty_mark.present(slot_id)
	lock_badge.visible = false
	set_meta("instance_id", str(item.get("instance_id", "")))
	tooltip_text = str(item.get("description", "点击下方背包选择装备"))
	accessibility_name = "%s槽，%s" % [
		EquipmentCatalog.slot_name(slot_id), str(item.get("name", "待装备")) if occupied else "待装备",
	]
	CharacterStyle.apply_item_card(self, rarity_id if occupied else "common", false)


func present_locked() -> void:
	slot_id = ""
	item_data = {}
	disabled = true
	focus_mode = Control.FOCUS_NONE
	background_view.texture = CharacterAssets.quality_texture("common")
	icon_view.visible = false
	empty_mark.visible = false
	lock_badge.visible = true
	set_meta("instance_id", "")
	tooltip_text = "该装备槽尚未解锁"
	accessibility_name = "锁定装备槽"
	CharacterStyle.apply_item_card(self, "common", false)
	modulate = Color(0.66, 0.7, 0.68, 0.74)
