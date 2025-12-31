extends Node

var IP_ADDRESS: String = "localhost"
var PORT: int = 26969

var peer: ENetMultiplayerPeer
var peers_connected: int = 0

func set_network_address(ip: String, port: int):
	IP_ADDRESS = ip
	PORT = port

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
			await get_tree().create_timer(1).timeout
			print("Game starting...")
			GameManager.start_game()


func _on_get_players_stats_pressed() -> void:
	$RichTextLabel.text = GameManager.return_all_stats()
