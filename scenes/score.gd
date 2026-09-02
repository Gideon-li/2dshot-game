extends Control

var _rank: Label
var _flavor: Label
var _fit: Label
var _speed: Label
var _flags: Label
var _miss: Label


func _ready() -> void:
	_build()
	GameFlow.locale_changed.connect(_refresh)
	_refresh()
	AudioHub.play_settle(str(GameFlow.last_result.get("rank_id", "none")))


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = UiKit.PAPER
	add_child(bg)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 80
	col.offset_right = -80
	col.offset_top = 40
	col.offset_bottom = -40
	col.add_theme_constant_override("separation", 14)
	add_child(col)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(UiKit.locale_bar())
	col.add_child(top)
	col.add_child(UiKit.ink_label(tr("SCORE_TITLE"), 20, UiKit.INK_MUTED))
	_rank = UiKit.ink_label("", 56, UiKit.SEAL)
	_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_rank)
	_flavor = UiKit.ink_label("", 20)
	_flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_flavor)
	_fit = UiKit.ink_label("", 16)
	col.add_child(_fit)
	_speed = UiKit.ink_label("", 16)
	col.add_child(_speed)
	_flags = UiKit.ink_label("", 16, UiKit.SEAL)
	col.add_child(_flags)
	_miss = UiKit.ink_label("", 15, UiKit.INK_MUTED)
	col.add_child(_miss)
	var bot := HBoxContainer.new()
	bot.alignment = BoxContainer.ALIGNMENT_CENTER
	var next := UiKit.make_button("ACTION_NEXT_PATIENT", true)
	next.custom_minimum_size = Vector2(200, 44)
	next.pressed.connect(func() -> void: GameFlow.go_clinic())
	bot.add_child(next)
	col.add_child(bot)
	var foot := UiKit.ink_label(tr("BOOT_DISCLAIMER_FOOTER"), 13, UiKit.INK_MUTED)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.name = "ScoreFoot"
	col.add_child(foot)


func _refresh() -> void:
	var r: Dictionary = GameFlow.last_result
	var rank_v: Variant = r.get("rank", {})
	if typeof(rank_v) == TYPE_DICTIONARY:
		_rank.text = GameFlow.loc_text(rank_v)
	else:
		_rank.text = tr(str(r.get("rank_key", "SCORE_NONE")))
	var flav: Variant = r.get("flavor", {})
	if typeof(flav) == TYPE_DICTIONARY:
		_flavor.text = UiKit.loc_text(flav, "")
	else:
		_flavor.text = str(flav)
	var fit_pct := int(round(float(r.get("score", r.get("pattern", 0.0))) * 100.0))
	_fit.text = "%s  %d" % [tr("SCORE_EFFICACY"), fit_pct]
	var sk := str(r.get("speed_key", r.get("speed", "steady")))
	var sk_tr := "SPEED_STEADY"
	match sk:
		"fast":
			sk_tr = "SPEED_FAST"
		"a_bit_rushed":
			sk_tr = "SPEED_RUSHED"
		"slow", "none":
			sk_tr = "SPEED_SLOW"
	_speed.text = "%s  %s" % [tr("SCORE_SPEED"), tr(sk_tr)]
	var flags := PackedStringArray()
	if bool(r.get("overtreat", false)):
		flags.append(tr("SCORE_OVERTREAT") + " · " + tr("SCORE_FLAG_OVER"))
	if bool(r.get("mistreat", false)):
		flags.append(tr("SCORE_MISTREAT") + " · " + tr("SCORE_FLAG_MIS"))
	_flags.text = "  ".join(flags)
	_miss.visible = bool(r.get("missing_exams", r.get("missing_exam", false)))
	_miss.text = tr("SCORE_INCOMPLETE_EXAM")
	var foot := find_child("ScoreFoot", true, false) as Label
	if foot:
		foot.text = tr("BOOT_DISCLAIMER_FOOTER")
	UiKit.refresh_i18n_buttons(self)
