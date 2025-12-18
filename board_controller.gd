extends Node2D
@onready var player_1_container: Control = $Player1Container
@onready var player_2_container: Control = $Player2Container
const PLAYER = preload("uid://cmvkn00sedqin")
var connected: bool = false

func _ready() -> void:
	if multiplayer.is_server():
		var player1 = PLAYER.instantiate()
		player1.player_num = 1
		player_1_container.add_child(player1)
	else:
		var player1 = PLAYER.instantiate()
		player1.player_num = 1
		player_1_container.add_child(player1)
		var player2 = PLAYER.instantiate()
		player2.player_num = 2
		player_2_container.add_child(player2)

func _process(delta: float) -> void:
	if NetworkHandler.is_peer_connected:
		if multiplayer.is_server():
			var player2 = PLAYER.instantiate()
			player2.player_num = 2
			player_2_container.add_child(player2)
