extends Node2D
@onready var player_1_container: Control = $Player1Container
@onready var player_2_container: Control = $Player2Container
const PLAYER = preload("uid://cmvkn00sedqin")
var connected: bool = false
var player_num: int
@onready var id: Label = $ID

func _ready() -> void:
	if multiplayer.get_unique_id() == GameManager.player1_id:
		var player1 = PLAYER.instantiate()
		player1.player_num = 1
		player1.is_player_board = true
		player_1_container.add_child(player1)
		var player2 = PLAYER.instantiate()
		player2.player_num = 2
		player2.is_player_board = false
		player_2_container.add_child(player2)
	if multiplayer.get_unique_id() == GameManager.player2_id:
		var player1 = PLAYER.instantiate()
		player1.player_num = 1
		player1.is_player_board = false
		player_1_container.add_child(player1)
		var player2 = PLAYER.instantiate()
		player2.player_num = 2
		player2.is_player_board = true
		player_2_container.add_child(player2)
	id.text = "ID: " + str(multiplayer.get_unique_id())
