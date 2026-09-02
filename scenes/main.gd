extends Control

func _ready() -> void:
	var loc := str(Save.data.get("locale", "zh"))
	TranslationServer.set_locale(loc)
	_refresh_copy()
	$Check.toggled.connect(_on_check)
	$Accept.pressed.connect(_on_accept)
	$LangZh.pressed.connect(func(): _switch_lang("zh"))
	$LangEn.pressed.connect(func(): _switch_lang("en"))
	$LangJa.pressed.connect(func(): _switch_lang("ja"))
	$Accept.disabled = not $Check.button_pressed
	if Save.disclaimer_accepted():
		_enter_clinic()

func _switch_lang(code: String) -> void:
	Save.set_locale(code)
	_refresh_copy()

func _refresh_copy() -> void:
	$GameTitle.text = tr("GAME_TITLE")
	$Subtitle.text = tr("GAME_SUBTITLE")
	$Title.text = tr("BOOT_DISCLAIMER_TITLE")
	$Body.text = tr("BOOT_DISCLAIMER_BODY")
	$Check.text = tr("BOOT_DISCLAIMER_CHECK")
	$Accept.text = tr("BOOT_DISCLAIMER_ACCEPT")
	$Footer.text = tr("BOOT_DISCLAIMER_FOOTER")
	$LangZh.text = tr("LANG_ZH")
	$LangEn.text = tr("LANG_EN")
	$LangJa.text = tr("LANG_JA")

func _on_check(on: bool) -> void:
	$Accept.disabled = not on

func _on_accept() -> void:
	if not $Check.button_pressed:
		return
	Save.accept_disclaimer()
	_enter_clinic()

func _enter_clinic() -> void:
	get_tree().change_scene_to_file("res://scenes/clinic.tscn")
