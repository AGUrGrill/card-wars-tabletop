extends Node

const IP_ADDRESS: String = "localhost"
const PORT: int = 34782

var peer: ENetMultiplayerPeer
var is_peer_connected = false

func start_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)

func start_client() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(peer_id):
	print("Client connected. Starting game...")
	is_peer_connected = true
	await get_tree().create_timer(2).timeout
	GameManager.start_game()
