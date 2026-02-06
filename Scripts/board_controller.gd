extends Node2D
@onready var player_1_container: Control = $Player1Container
@onready var player_2_container: Control = $Player2Container
var player1
var player2
@onready var zoom_button: Button = $Player1Container/ZoomButton
@onready var main_camera: Camera2D = $MainCamera
const PLAYER = preload("res://Scenes/player.tscn")
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
	
	get_viewport().set_physics_object_picking_sort(true)
	get_viewport().set_physics_object_picking_first_only(true)

func _process(delta: float) -> void:
	if GameManager.hand_refresh_needed:
		player1.update_player_hand_display()
		player2.update_player_hand_display()
		GameManager.hand_refresh_needed = false
	if GameManager.stat_refresh_needed:
		player1.update_player_stat_display()
		player2.update_player_stat_display()
		GameManager.stat_refresh_needed = false
	if GameManager.landscape1_refresh_needed:
		player1.update_player_landscape.rpc(0)
		player2.update_player_landscape.rpc(0)
		GameManager.landscape1_refresh_needed = false
	if GameManager.landscape2_refresh_needed:
		player1.update_player_landscape.rpc(1)
		player2.update_player_landscape.rpc(1)
		GameManager.landscape2_refresh_needed = false
	if GameManager.landscape3_refresh_needed:
		player1.update_player_landscape.rpc(2)
		player2.update_player_landscape.rpc(2)
		GameManager.landscape3_refresh_needed = false
	if GameManager.landscape4_refresh_needed:
		player1.update_player_landscape.rpc(3)
		player2.update_player_landscape.rpc(3)
		GameManager.landscape4_refresh_needed = false
	if GameManager.landscape69_refresh_needed:
		player1.update_player_landscape.rpc(69)
		player2.update_player_landscape.rpc(69)
		GameManager.landscape69_refresh_needed = false
	if GameManager.hero_refresh_needed:
		player1.update_hero_image()
		player2.update_hero_image()
		GameManager.hero_refresh_needed = false

func _on_zoom_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		main_camera.zoom = Vector2(1.5, 1.5)
	else:
		main_camera.zoom = Vector2(1, 1)

func _on_return_to_menu_pressed() -> void:
	multiplayer.multiplayer_peer.disconnect_peer(1)
	#NetworkHandler.peer.disconnect_peer(multiplayer.get_unique_id())
	GameManager.game_ended = false
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
