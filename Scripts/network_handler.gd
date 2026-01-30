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
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func start_client() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.multiplayer_peer.peer_disconnected.connect(client_on_peer_disconnect)

func _on_peer_connected(peer_id):
	if multiplayer.is_server():
		print("Client " + str(peer_id) + " connected.")
		peers_connected += 1
		if peers_connected == 2:
			await get_tree().create_timer(5).timeout
			print("Game starting...")
			GameManager.start_game()
		elif peers_connected > 2:
			print("Client " + peer_id + " attempted connection... Denying access.")
			multiplayer.multiplayer_peer.close()

func _on_peer_disconnected(peer_id):
	if multiplayer.is_server():
		peers_connected -= 1
		print("Client " + str(peer_id) + " dicconnected.")
		if peers_connected == 0:
			GameManager.terminate_game()

func client_on_peer_disconnect():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_get_players_stats_pressed() -> void:
	$RichTextLabel.text = GameManager.return_all_stats()
