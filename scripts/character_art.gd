class_name CharacterArt
extends RefCounted
## V126: per-id portraits under ui/characters/. Fallback to apprentice.png / patients-three thirds.

const PATHS := {
	"apprentice_jiang": "res://ui/characters/jiang_wan.png",
	"jiang_wan": "res://ui/characters/jiang_wan.png",
	"char_porter": "res://ui/characters/zhao_afu.png",
	"char_clerk": "res://ui/characters/shen_qinghe.png",
	"char_copyist": "res://ui/characters/zhou_popo.png",
	"pharmacy_kid_xiaohe": "res://ui/characters/xiaohe.png",
	"mentor_su": "res://ui/characters/su_wenzhou.png",
}

const FALLBACK_APPRENTICE := "res://ui/apprentice.png"
const FALLBACK_PATIENTS := "res://ui/patients-three.png"

## Equal horizontal thirds for porter / clerk / copyist.
const PATIENT_ORDER := ["char_porter", "char_clerk", "char_copyist"]

static var _warned: Dictionary = {}


static func portrait_path(id: String) -> String:
	return str(PATHS.get(id, ""))


static func load_portrait(id: String) -> Texture2D:
	var path := portrait_path(id)
	if path != "" and ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		if tex != null:
			return tex
	return _fallback(id)


static func has_single_file(id: String) -> bool:
	var path := portrait_path(id)
	return path != "" and ResourceLoader.exists(path)


static func _fallback(id: String) -> Texture2D:
	if not _warned.has(id):
		_warned[id] = true
		print("portrait_fallback id=", id)
	if id == "apprentice_jiang" or id == "jiang_wan":
		if ResourceLoader.exists(FALLBACK_APPRENTICE):
			return load(FALLBACK_APPRENTICE) as Texture2D
		return null
	var idx := PATIENT_ORDER.find(id)
	if idx < 0:
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
