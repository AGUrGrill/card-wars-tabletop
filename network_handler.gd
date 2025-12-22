extends Node

const IP_ADDRESS: String = "localhost"
const PORT: int = 34782

var peer: ENetMultiplayerPeer
var peers_connected: int = 0

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
	if multiplayer.is_server():
		print("Client " + str(peer_id) + "connected.")
		peers_connected += 1
		if peers_connected == 2:
			print("Game starting...")
			GameManager.start_game()
