class_name CharacterArt
extends RefCounted
## V126/V134/V135: per-id portraits under ui/characters/. Fallback to apprentice.png / patients-three thirds.

const PATHS := {
	"apprentice_jiang": "res://ui/characters/jiang_wan.png",
	"jiang_wan": "res://ui/characters/jiang_wan.png",
	"char_porter": "res://ui/characters/zhao_afu.png",
	"char_clerk": "res://ui/characters/shen_qinghe.png",
	"char_copyist": "res://ui/characters/zhou_popo.png",
	"char_xiuniang": "res://ui/characters/zhou_xiuniang.png",
	"char_zoufan": "res://ui/characters/liu_heqing.png",
	"char_yanhou": "res://ui/characters/gu_yanyu.png",
	"char_yaoqin": "res://ui/characters/lin_ashen.png",
	"char_danfu": "res://ui/characters/han_danfu.png",
	"char_bashi": "res://ui/characters/ma_bashi.png",
	"char_jiaoli": "res://ui/characters/xia_jiaoli.png",
	"pharmacy_kid_xiaohe": "res://ui/characters/xiaohe.png",
	"mentor_su": "res://ui/characters/su_wenzhou.png",
}

const SEAL_PATHS := {
	"fengre_biao": "res://ui/seals/fengre_biao.png",
	"shiji": "res://ui/seals/shiji.png",
	"pixu_shikun": "res://ui/seals/pixu_shikun.png",
	"yangxu_weihan": "res://ui/seals/yangxu_weihan.png",
	"xueyu_qing": "res://ui/seals/xueyu_qing.png",
	"shushi": "res://ui/seals/shushi.png",
}

const FALLBACK_APPRENTICE := "res://ui/apprentice.png"
const FALLBACK_PATIENTS := "res://ui/patients-three.png"

## Full Qingshi pool (10). Hall seats are max 4 via waiting rotation — not all forced on stage.
const PATIENT_ORDER := [
	"char_porter",
	"char_clerk",
	"char_copyist",
	"char_xiuniang",
	"char_zoufan",
	"char_yanhou",
	"char_yaoqin",
	"char_danfu",
	"char_bashi",
	"char_jiaoli",
]

const OLD_FOUR := ["char_porter", "char_clerk", "char_copyist", "char_xiuniang"]
const NEW_THREE := ["char_zoufan", "char_yanhou", "char_yaoqin"]
const EXPAND2_THREE := ["char_danfu", "char_bashi", "char_jiaoli"]
const WAITING_MAX_SEATS := 4

static var _warned: Dictionary = {}


static func portrait_path(id: String) -> String:
	return str(PATHS.get(id, ""))


static func seal_path(case_id: String) -> String:
	return str(SEAL_PATHS.get(case_id, ""))


static func _load_texture_file(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		if tex != null:
			return tex
	# Headless / pre-import: load PNG bytes directly
	if not path.begins_with("res://"):
		return null
	if not FileAccess.file_exists(path):
		return null
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	if img.load(abs_path) != OK:
		return null
	return ImageTexture.create_from_image(img)


static func load_portrait(id: String) -> Texture2D:
	var path := portrait_path(id)
	var tex := _load_texture_file(path)
	if tex != null:
		return tex
	return _fallback(id)


static func load_seal(case_id: String) -> Texture2D:
	return _load_texture_file(seal_path(case_id))


static func has_single_file(id: String) -> bool:
	var path := portrait_path(id)
	if path == "":
		return false
	if ResourceLoader.exists(path):
		return true
	return FileAccess.file_exists(path)


static func _fallback(id: String) -> Texture2D:
	if not _warned.has(id):
		_warned[id] = true
		print("portrait_fallback id=", id)
	if id == "apprentice_jiang" or id == "jiang_wan":
		if ResourceLoader.exists(FALLBACK_APPRENTICE):
			return load(FALLBACK_APPRENTICE) as Texture2D
		return null
	var idx := PATIENT_ORDER.find(id)
	# Sheet only covers first three; later patients need single-file portraits.
	if idx < 0 or idx >= 3:
		return null
	if not ResourceLoader.exists(FALLBACK_PATIENTS):
		return null
	var full: Texture2D = load(FALLBACK_PATIENTS)
	if full == null:
		return null
	var cols := 3
	var cell_w := float(full.get_width()) / float(cols)
	var at := AtlasTexture.new()
	at.atlas = full
	at.region = Rect2(cell_w * float(idx), 0.0, cell_w, float(full.get_height()))
	return at
