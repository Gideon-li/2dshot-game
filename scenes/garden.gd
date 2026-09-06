extends Control
## V121 backyard forage via Forage autoload (slice_logic herbs[].forage + packs).

var _spot: String = ""
var _focus: String = ""
var _status: Label
var _clue_box: VBoxContainer
var _opt_box: HBoxContainer
var _stock_l: Label
var _pick_b: Button
var _spot_row: HBoxContainer
var _herb_row: HFlowContainer
var _id_chrome: TextureRect

## Matches ui/forage/README.md herb-icons-12 / clusters-12 grid (4×3).
const ICON_ATLAS_ORDER: Array[String] = [
	"guizhi", "baishao", "shengjiang", "gancao",
	"chaihu", "danggui", "baizhu", "fuling",
	"mahuang", "dazao", "mudanpi", "shudi",
]
const ICON_ATLAS := "res://ui/forage/herb-icons-12.png"
const CLUSTER_ATLAS := "res://ui/forage/herb-clusters-12.png"
const IDENTIFY_UI := "res://ui/forage/identify-ui.png"


func _atlas_tex(path: String, hid: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var idx := ICON_ATLAS_ORDER.find(hid)
	if idx < 0:
		return null
	var full: Texture2D = load(path)
	if full == null:
		return null
	var cols := 4
	var rows := 3
	var cell := Vector2(full.get_width() / float(cols), full.get_height() / float(rows))
	var at := AtlasTexture.new()
	at.atlas = full
	at.region = Rect2(Vector2(idx % cols, int(idx / cols)) * cell, cell)
	return at


func _herb_icon(hid: String, size: Vector2 = Vector2(40, 40)) -> Control:
	var tex := _atlas_tex(ICON_ATLAS, hid)
	if tex == null:
		tex = _atlas_tex(CLUSTER_ATLAS, hid)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = size
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tr
	# swatch fallback (e.g. missing atlas id)
	var meta: Dictionary = Forage.shape_meta(hid) if Forage else {}
	var sw := ColorRect.new()
	sw.custom_minimum_size = size
	sw.color = meta.get("color", Color(0.5, 0.55, 0.4))
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sw



func _ready() -> void:
	if AudioHub:
		AudioHub.enter_clinic()
	_build()
	GameFlow.locale_changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.78, 0.86, 0.72, 1)
	add_child(bg)
	if ResourceLoader.exists("res://ui/forage/garden-bg.png"):
		var art := TextureRect.new()
		art.texture = load("res://ui/forage/garden-bg.png")
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.modulate = Color(1, 1, 1, 0.92)
		add_child(art)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var top := HBoxContainer.new()
	top.add_child(UiKit.ink_label(tr("GARDEN_TITLE"), 22))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UiKit.locale_bar())
	var back := UiKit.make_button("GARDEN_BACK", false)
	back.pressed.connect(func() -> void: Forage.leave_garden())
	top.add_child(back)
	root.add_child(top)
	var mentor: String = Forage.mentor_forage_line()
	if mentor != "":
		var who: String = CaseDB.mentor_name()
		if who == "":
			who = "苏问舟"
		root.add_child(UiKit.ink_label("%s：%s" % [who, mentor], 14, UiKit.SEAL))
	var ag: String = Forage.agui_hint()
	if ag != "":
		root.add_child(UiKit.ink_label("%s：%s" % [tr("GARDEN_AGUI"), ag], 13, UiKit.INK_MUTED))
	root.add_child(UiKit.ink_label(tr("GARDEN_HINT"), 13, UiKit.INK_MUTED))
	_stock_l = UiKit.ink_label("", 14)
	root.add_child(_stock_l)
	_spot_row = HBoxContainer.new()
	_spot_row.add_theme_constant_override("separation", 10)
	root.add_child(_spot_row)
	_herb_row = HFlowContainer.new()
	_herb_row.add_theme_constant_override("h_separation", 8)
	_herb_row.add_theme_constant_override("v_separation", 8)
	root.add_child(_herb_row)
	_status = UiKit.ink_label("", 14, UiKit.SEAL)
	root.add_child(_status)
	var id_wrap := PanelContainer.new()
	id_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if ResourceLoader.exists(IDENTIFY_UI):
		var sb := StyleBoxTexture.new()
		sb.texture = load(IDENTIFY_UI)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		id_wrap.add_theme_stylebox_override("panel", sb)
	root.add_child(id_wrap)
	var id_col := VBoxContainer.new()
	id_col.add_theme_constant_override("separation", 8)
	id_wrap.add_child(id_col)
	_clue_box = VBoxContainer.new()
	id_col.add_child(_clue_box)
	_opt_box = HBoxContainer.new()
	_opt_box.add_theme_constant_override("separation", 8)
	id_col.add_child(_opt_box)
	_pick_b = UiKit.make_button("GARDEN_PICK", true)
	_pick_b.pressed.connect(_pick_focus)
	_pick_b.visible = false
	root.add_child(_pick_b)
	_rebuild_spots()


func _refresh() -> void:
	UiKit.refresh_i18n_buttons(self)
	_refresh_stock()
	if _focus != "":
		_focus_herb(_focus)


func _rebuild_spots() -> void:
	for c in _spot_row.get_children():
		c.queue_free()
	var spots: PackedStringArray = Forage.spots()
	if spots.is_empty():
		# fallback single plot
		spots = PackedStringArray(["yard"])
	for spot in spots:
		var b := UiKit.make_button("", false)
		b.text = Forage.spot_label(str(spot))
		if b.text == "" or b.text == str(spot):
			b.text = str(spot)
		b.pressed.connect(_select_spot.bind(str(spot)))
		_spot_row.add_child(b)
	_select_spot(str(spots[0]))


func _select_spot(spot: String) -> void:
	_spot = spot
	_focus = ""
	_pick_b.visible = false
	_status.text = ""
	for c in _herb_row.get_children():
		c.queue_free()
	for c in _clue_box.get_children():
		c.queue_free()
	for c in _opt_box.get_children():
		c.queue_free()
	var herbs: PackedStringArray = Forage.herbs_at_spot(spot)
	if herbs.is_empty():
		# show all enabled if spot empty
		herbs = Forage.forage_enabled_ids()
	for hid in herbs:
		var b := Button.new()
		b.custom_minimum_size = Vector2(160, 56)
		UiKit.style_button(b, false)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 6
		row.offset_right = -6
		b.add_child(row)
		row.add_child(_herb_icon(str(hid), Vector2(36, 36)))
		var shown := "?"
		if Forage.is_identified(str(hid)):
			shown = Forage.herb_display_name(str(hid))
		var lab := UiKit.ink_label(shown, 13)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lab)
		b.pressed.connect(_focus_herb.bind(str(hid)))
		_herb_row.add_child(b)
	_refresh_stock()


func _refresh_stock() -> void:
	var bits: PackedStringArray = []
	for hid in Forage.forage_enabled_ids():
		var n: int = Forage.stock(str(hid))
		if n > 0:
			bits.append("%s×%d" % [Forage.herb_display_name(str(hid)), n])
	_stock_l.text = "%s：%s" % [tr("GARDEN_STOCK"), ("、".join(bits) if bits.size() > 0 else "—")]


func _focus_herb(hid: String) -> void:
	_focus = hid
	for c in _clue_box.get_children():
		c.queue_free()
	for c in _opt_box.get_children():
		c.queue_free()
	_status.text = ""
	# Visual clue cards (swatch + text), not a pure text quiz.
	var cards: Array = Forage.clue_cards(hid, 3) if Forage.has_method("clue_cards") else []
	if cards.is_empty():
		for line in Forage.clues_for(hid, 3):
			cards.append({"text": line, "color": Forage.shape_meta(hid).get("color", Color(0.5, 0.55, 0.4))})
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_clue_box.add_child(row)
	for card in cards:
		if typeof(card) != TYPE_DICTIONARY:
			continue
		var panel := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.93, 0.90, 0.82, 0.95)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.45, 0.4, 0.32)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", sb)
		panel.custom_minimum_size = Vector2(190, 88)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		panel.add_child(col)
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(0, 26)
		sw.color = card.get("color", Color(0.5, 0.55, 0.4))
		col.add_child(sw)
		var lab := UiKit.ink_label(str(card.get("text", "")), 12)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(lab)
		row.add_child(panel)
	var opts: PackedStringArray = Forage.identify_options(hid)
	var arr: Array = []
	for o in opts:
		arr.append(str(o))
	arr.shuffle()
	for oid in arr:
		var b := Button.new()
		b.custom_minimum_size = Vector2(140, 48)
		UiKit.style_button(b, false)
		var orow := HBoxContainer.new()
		orow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		orow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		orow.offset_left = 6
		orow.offset_right = -6
		b.add_child(orow)
		orow.add_child(_herb_icon(str(oid), Vector2(28, 28)))
		var ol := UiKit.ink_label(Forage.herb_display_name(str(oid)), 13)
		ol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		orow.add_child(ol)
		b.pressed.connect(_try_id.bind(str(oid)))
		_opt_box.add_child(b)
	_pick_b.visible = Forage.is_identified(hid)
	if Forage.stock(hid) > 0:
		_status.text = tr("GARDEN_PICKED")


func _try_id(choice: String) -> void:
	if _focus == "":
		return
	var res: Dictionary = Forage.try_identify(_focus, choice)
	_status.text = str(res.get("feedback", ""))
	if bool(res.get("ok", false)):
		AudioHub.play_one("ui-ink")
		_pick_b.visible = true
	else:
		AudioHub.play_herb_wrong()
		_pick_b.visible = false


func _pick_focus() -> void:
	if _focus == "":
		return
	var res: Dictionary = Forage.pick_herb(_focus)
	if bool(res.get("ok", false)):
		_status.text = "%s +%d" % [tr("GARDEN_PICKED"), int(res.get("added", 1))]
		if AudioHub.has_method("play_forage_pull"):
			AudioHub.play_forage_pull()
		if AudioHub.has_method("play_forage_bag"):
			AudioHub.play_forage_bag()
		else:
			AudioHub.play_one("herb-drop")
		_refresh_stock()
	else:
		_status.text = tr("GARDEN_NEED_ID")
