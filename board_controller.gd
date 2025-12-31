extends Node2D
@onready var player_1_container: Control = $Player1Container
@onready var player_2_container: Control = $Player2Container
var player1
var player2
@onready var zoom_button: Button = $Player1Container/ZoomButton
@onready var main_camera: Camera2D = $MainCamera
const PLAYER = preload("uid://cmvkn00sedqin")
var connected: bool = false
var player_num: int
@onready var id: Label = $ID

func _ready() -> void:
	if multiplayer.get_unique_id() == GameManager.player1_id:
		player1 = PLAYER.instantiate()
		player1.player_num = 1
		player1.is_player_board = true
		player_1_container.add_child(player1)
		player2 = PLAYER.instantiate()
		player2.player_num = 2
		player2.is_player_board = false
		player_2_container.add_child(player2)
	if multiplayer.get_unique_id() == GameManager.player2_id:
		player1 = PLAYER.instantiate()
		player1.player_num = 1
		player1.is_player_board = false
		player_2_container.add_child(player1)
		player2 = PLAYER.instantiate()
		player2.player_num = 2
		player2.is_player_board = true
		player_1_container.add_child(player2)
	id.text = "ID: " + str(multiplayer.get_unique_id())

func _process(delta: float) -> void:
	if GameManager.hand_refresh_needed:
		player1.update_player_hand_display()
		player2.update_player_hand_display()
		GameManager.hand_refresh_needed = false
	if GameManager.stat_refresh_needed:
		player1.update_player_stat_display()
		player2.update_player_stat_display()
		GameManager.stat_refresh_needed = false
	if GameManager.landscape_refresh_needed:
		player1.update_player_landscapes()
		player2.update_player_landscapes()
		GameManager.landscape_refresh_needed = false
	if GameManager.hero_refresh_needed:
		player1.update_hero_image()
		player2.update_hero_image()
		GameManager.landscape_refresh_needed = false

func _on_zoom_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		main_camera.zoom = Vector2(1.5, 1.5)
	else:
		main_camera.zoom = Vector2(1, 1)
