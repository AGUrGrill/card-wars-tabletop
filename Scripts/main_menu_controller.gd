extends Node2D

@onready var confirm_sfx: AudioStreamPlayer2D = $Audio/ConfirmSFX
@onready var enter_deck_code: TextEdit = $EnterDeckCode
@onready var choose_deck: OptionButton = $ChooseDeck
@onready var log_text: Label = $Log/LogText
@onready var log_timer: Timer = $Log/Timer
@onready var ip_address: LineEdit = $IPAddress
@onready var port: LineEdit = $Port

var hero: String
var landscapes: Array[String]
var deck: Array[String]
var default_deck_choice: String
var deck_choosen: bool = false

var in_testing_mode: bool = true
var game_starting: bool = false

func _ready() -> void:
	GameManager.local_client_player_num = 0
	get_all_decks("res://Assets/Decks/")
	get_all_decks("user://Decks/")

func _process(delta: float) -> void:
	if game_starting:
		return
	if GameManager.local_client_player_num == 1:
		game_starting = true
		start_as_p1()
	elif GameManager.local_client_player_num == 2:
		game_starting = true
		start_as_p2()

func get_all_decks(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if path.contains("user://"):
				choose_deck.add_item(file_name.trim_suffix(".dat"))
			else:
				choose_deck.add_item(file_name.trim_suffix(".txt"))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

func send_log_msg(message: String):
	log_text.text = message
	log_timer.start()

func parse_deck_info(deck_data: String):
	var formatted_info: PackedStringArray = deck_data.split("\n", false)
	var gathering_landscape_info: bool = false
	var gathering_card_info: bool = false
	var prev_line: String
	for line in formatted_info:
		if prev_line == "Hero":
			hero = line
		if line == "Landscapes":
			gathering_landscape_info = true
			continue
		if line == "Creatures":
			gathering_landscape_info = false
			gathering_card_info = true
			continue
		elif line == "Spells":
			continue
		elif line == "Buildings":
			continue
		if gathering_landscape_info:
			for idx in range(int(line[0])):
				landscapes.append(line.substr(4, line.length()))
		if gathering_card_info:
			for idx in range(int(line[0])):
				deck.append(line.substr(4, line.length()))
		prev_line = line
	
	deck_choosen = true

func start_as_p1():
	GameManager.player1_hero = hero
	for card_name in deck:
		GameManager.player1_deck.append(GameManager.draw_by_name(card_name))
	await get_tree().create_timer(3).timeout
	#GameManager.client_give_player_id.rpc(1, multiplayer.get_unique_id())
	GameManager.player1_id = multiplayer.get_unique_id()
	GameManager.recieve_player_landscapes.rpc(1, landscapes)
	GameManager.recieve_player_deck.rpc(1, GameManager.player1_deck)
	GameManager.recieve_player_hero.rpc(1, hero)
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/board.tscn")

func start_as_p2():
	GameManager.player2_hero = hero
	for card_name in deck:
		GameManager.player2_deck.append(GameManager.draw_by_name(card_name))
	await get_tree().create_timer(3).timeout
	#GameManager.client_give_player_id.rpc(2, multiplayer.get_unique_id())
	GameManager.player2_id = multiplayer.get_unique_id()
	GameManager.recieve_player_landscapes.rpc(2, landscapes)
	GameManager.recieve_player_deck.rpc(2, GameManager.player2_deck)
	GameManager.recieve_player_hero.rpc(2, hero)
	confirm_sfx.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/board.tscn")

func _on_start_server_pressed() -> void:
	if not in_testing_mode:
		NetworkHandler.set_network_address(ip_address.text, int(port.text))
	NetworkHandler.start_server()
	confirm_sfx.play()
	get_tree().change_scene_to_file("res://Scenes/server.tscn")

func _on_start_client_pressed() -> void:
	if not deck_choosen:
		send_log_msg("Please select a deck.")
		return
	if not in_testing_mode:
		if ip_address.text.is_empty() or port.text.is_empty():
			send_log_msg("Please provide an IP Address and Port Number.")
			return
		NetworkHandler.set_network_address(ip_address.text, int(port.text))
	NetworkHandler.start_client()
	confirm_sfx.play()

func _on_load_deck_pressed() -> void:
	deck.clear()
	if not enter_deck_code.text.is_empty():
		parse_deck_info(enter_deck_code.text)
	elif not default_deck_choice.is_empty():
		parse_deck_info(default_deck_choice)
	else:
		send_log_msg("No deck selected.")
		deck_choosen = false
		return
	send_log_msg("Loaded \"" + hero +"\" Deck.")
	confirm_sfx.play()

func _on_timer_timeout() -> void:
	log_text.text = ""

func _on_choose_deck_item_selected(index: int) -> void:
	var choosen_deck: String = choose_deck.get_item_text(index)
	default_deck_choice = load_from_file(choosen_deck)

func load_from_file(_name: String):
	var file = FileAccess.open("res://Assets/Decks/" + _name + ".txt", FileAccess.READ)
	if file == null:
		file = FileAccess.open("user://Decks/" + _name + ".dat", FileAccess.READ)
		if file == null:
			print("Error getting file data.")
			return ""
	var content = file.get_as_text()
	return content

func _on_player_stat_menu_pressed() -> void:
	confirm_sfx.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/stat_screen.tscn")

func _on_create_deck_pressed() -> void:
	confirm_sfx.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/deck_creation.tscn")
