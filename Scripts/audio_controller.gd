extends Node

@export var audio_type: String
@export var disabled: bool
@onready var sfx: AudioStreamPlayer2D = $SFX
@onready var bgm: AudioStreamPlayer2D = $BGM
@onready var win: AudioStreamPlayer2D = $Win
@onready var lose: AudioStreamPlayer2D = $Lose
@onready var confirm_sfx: AudioStreamPlayer2D = $ConfirmSFX
@onready var enable_sfx: TextureButton = $Panel/EnableSFX
@onready var enable_bgm: TextureButton = $Panel/EnableBGM
@onready var panel: Panel = $Panel

var sfx_enabled: bool = true
var sfx_looping: bool = false

var playing_game_end_audio: bool = false

func _ready() -> void:
	if disabled:
		panel.visible = false
		return
	if audio_type == "Main Menu":
		sfx.stream = load("res://Assets/Sounds/bird_in_forest.mp3")
		sfx_looping = true
		sfx.play()
		bgm.stream = load("res://Assets/Sounds/island_song.mp3")
	elif audio_type == "Player":
		sfx.stream = load("res://Assets/Sounds/confirm.mp3")
		bgm.stream = load("res://Assets/Sounds/island_song.mp3")
	elif audio_type == "Disabled":
		panel.visible = false
	elif audio_type == "End Screen":
		if GameManager.who_won == false and multiplayer.get_unique_id() == GameManager.player1_id:
			win.play()
		elif GameManager.who_won == true and multiplayer.get_unique_id() == GameManager.player1_id:
			lose.play()
		if GameManager.who_won == true and multiplayer.get_unique_id() == GameManager.player2_id:
			win.play()
		elif GameManager.who_won == false and multiplayer.get_unique_id() == GameManager.player2_id:
			lose.play()

func _on_enable_bgm_pressed() -> void:
	if bgm.playing:
		bgm.playing = false
		enable_bgm.texture_normal = load("res://Assets/music_mute_icon.png")
	else:
		bgm.playing = true
		enable_bgm.texture_normal = load("res://Assets/music_icon.png")

func _on_enable_sfx_pressed() -> void:
	if sfx.playing:
		if audio_type == "Player":
			confirm_sfx.volume_db = -80
		else:
			sfx.playing = false
		enable_sfx.texture_normal = load("res://Assets/mute_icon.png")
	else:
		if audio_type == "Player":
			confirm_sfx.volume_db = 0
		else:
			sfx.playing = true
		enable_sfx.texture_normal = load("res://Assets/sound-icon.png")

func _on_sfx_finished() -> void:
	if sfx_looping:
		sfx.play()

func _on_bgm_finished() -> void:
	bgm.play()
