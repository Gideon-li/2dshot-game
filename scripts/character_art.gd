class_name CharacterArt
extends RefCounted
## V126/V134/V135/V136: per-id portraits under ui/characters/. Fallback to apprentice.png / patients-three thirds.

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
	"char_tanfu": "res://ui/characters/qiu_tanfu.png",
	"char_tianhan": "res://ui/characters/he_tianhan.png",
	"char_mujiang": "res://ui/characters/lu_mujiang.png",
	"pharmacy_kid_xiaohe": "res://ui/characters/xiaohe.png",
	"mentor_su": "res://ui/characters/su_wenzhou.png",
}

const SIT_PATHS := {
	"apprentice_jiang": "res://ui/characters/jiang_wan_sit.png",
	"jiang_wan": "res://ui/characters/jiang_wan_sit.png",
}



const SEAL_PATHS := {
	# Expand 9 (V134–V136)
	"fengre_biao": "res://ui/seals/fengre_biao.png",
	"shiji": "res://ui/seals/shiji.png",
	"pixu_shikun": "res://ui/seals/pixu_shikun.png",
	"yangxu_weihan": "res://ui/seals/yangxu_weihan.png",
	"xueyu_qing": "res://ui/seals/xueyu_qing.png",
	"shushi": "res://ui/seals/shushi.png",
	"yinxu_zaoke": "res://ui/seals/yinxu_zaoke.png",
	"shire_xiazhu": "res://ui/seals/shire_xiazhu.png",
	"waishang_zhongtong": "res://ui/seals/waishang_zhongtong.png",
	# Old four (also write play.seals on clear+)
	"fenghan_biao": "res://ui/seals/fenghan_biao.png",
	"ganyu_qizhi": "res://ui/seals/ganyu_qizhi.png",
	"yinxu_neire": "res://ui/seals/yinxu_neire.png",
	"xuexu_ganyu": "res://ui/seals/xuexu_ganyu.png",
}

const SEAL_WALL_PATH := "res://ui/seals/seal_wall_9.png"
const SEAL_WALL_FRAME_PATH := "res://ui/seals/seal_wall_frame.png"

const FALLBACK_APPRENTICE := "res://ui/apprentice.png"
const FALLBACK_PATIENTS := "res://ui/patients-three.png"

## Full Qingshi pool (13). Hall seats are max 4 via waiting rotation — not all forced on stage.
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
	"char_tanfu",
	"char_tianhan",
	"char_mujiang",
]

const OLD_FOUR := ["char_porter", "char_clerk", "char_copyist", "char_xiuniang"]
const NEW_THREE := ["char_zoufan", "char_yanhou", "char_yaoqin"]
const EXPAND2_THREE := ["char_danfu", "char_bashi", "char_jiaoli"]
const EXPAND3_THREE := ["char_tanfu", "char_tianhan", "char_mujiang"]
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


static func load_portrait_sit(id: String) -> Texture2D:
	## V139: Jiang Wan sit-consult pose. Falls back to standing if sit art missing.
	var sit_path := str(SIT_PATHS.get(id, ""))
	var tex := _load_texture_file(sit_path)
	if tex != null:
		return tex
	return null


static func load_seal(case_id: String) -> Texture2D:
	return _load_texture_file(seal_path(case_id))


static func load_seal_wall() -> Texture2D:
	## Optional nine-seal wall art (V136). Soft-load; null if missing.
	var tex := _load_texture_file(SEAL_WALL_PATH)
	if tex != null:
		return tex
	return _load_texture_file(SEAL_WALL_FRAME_PATH)


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
