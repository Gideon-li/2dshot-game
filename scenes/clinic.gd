extends Control

func _ready() -> void:
	$DeskLabel.text = tr("UI_CLINIC")
	$CabinetLabel.text = tr("UI_FORMULA_TRAY")
	if has_node("EnterBtn"):
		$EnterBtn.visible = false
	if has_node("Hint"):
		$Hint.text = tr("BOOT_DISCLAIMER_FOOTER")
	_play_rain()

func _play_rain() -> void:
	var stream: AudioStream = load("res://other-systems/audio/rain-clinic.ogg")
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var player := AudioStreamPlayer.new()
	player.stream = stream
	var ambient := 0.32
	if Save.data.has("audio") and typeof(Save.data["audio"]) == TYPE_DICTIONARY:
		ambient = float(Save.data["audio"].get("ambient", 0.32))
	player.volume_db = linear_to_db(clampf(ambient, 0.0, 1.0))
	player.autoplay = false
	add_child(player)
	player.play()
