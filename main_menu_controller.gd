extends Node2D

@onready var confirm_sfx: AudioStreamPlayer2D = $Audio/ConfirmSFX
@onready var enter_deck_code: TextEdit = $EnterDeckCode
@onready var choose_deck: OptionButton = $ChooseDeck
@onready var log_text: Label = $Log/LogText
@onready var log_timer: Timer = $Log/Timer
@onready var ip_address: LineEdit = $IPAddress
@onready var port: LineEdit = $Port

var hero: String
var deck: Array[String]
var default_deck_choice: String
var deck_choosen: bool = false

var in_testing_mode: bool = true

func send_log_msg(message: String):
	log_text.text = message
	log_timer.start()

func parse_deck_info(deck_data: String):
	var formatted_info: PackedStringArray = deck_data.split("\n", false)
	var gathering_card_info: bool = false
	var prev_line: String
	for line in formatted_info:
		if prev_line == "Hero":
			hero = line
		if line == "Creatures":
			gathering_card_info = true
			continue
		elif line == "Spells":
			continue
		elif line == "Buildings":
			continue
		if gathering_card_info:
			for idx in range(int(line[0])):
				deck.append(line.substr(4, line.length()))
		prev_line = line
	
	deck_choosen = true

func _on_start_server_pressed() -> void:
	if not in_testing_mode:
		NetworkHandler.set_network_address(ip_address.text, int(port.text))
	NetworkHandler.start_server()
	confirm_sfx.play()
	get_tree().change_scene_to_file("res://server.tscn")

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
	GameManager.player1_hero = hero
	for card_name in deck:
		GameManager.player1_deck.append(GameManager.draw_by_name(card_name))
	await get_tree().create_timer(0.5).timeout
	#GameManager.client_give_player_id.rpc(1, multiplayer.get_unique_id())
	GameManager.player1_id = multiplayer.get_unique_id()
	GameManager.recieve_player_deck.rpc(1, GameManager.player1_deck)
	GameManager.recieve_player_hero.rpc(1, hero)
	confirm_sfx.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://board.tscn")

func _on_start_client_2_pressed() -> void:
	if not deck_choosen:
		send_log_msg("Please select a deck.")
		return
	if not in_testing_mode:
		if ip_address.text.is_empty() or port.text.is_empty():
			send_log_msg("Please provide an IP Address and Port Number.")
			return
		NetworkHandler.set_network_address(ip_address.text, int(port.text))
	NetworkHandler.start_client()
	GameManager.player2_hero = hero
	for card_name in deck:
		GameManager.player2_deck.append(GameManager.draw_by_name(card_name))
	await get_tree().create_timer(0.5).timeout
	#GameManager.client_give_player_id.rpc(2, multiplayer.get_unique_id())
	GameManager.player2_id = multiplayer.get_unique_id()
	GameManager.recieve_player_deck.rpc(2, GameManager.player2_deck)
	GameManager.recieve_player_hero.rpc(2, hero)
	confirm_sfx.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://board.tscn")

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
	match choosen_deck:
		"Jake":
			default_deck_choice = "Hero
Jake

Landscapes
4 - Cornfield

Creatures
3 - Field Reaper
3 - Field Stalker
3 - Travelin' Farmer
3 - Husker Worm
3 - Husker Champion
3 - Ethan Allfire
3 - Popcorn Butteredfly
3 - Big Foot
3 - Earth Mover
3 - Mantle Masher
3 - Quake Maker
1 - The Pig

Spells
3 - Field of Nightmares
3 - Bale Out
3 - Clone
3 - Rock Out!

Buildings
3 - Yellow Lighthouse
3 - Husker Garrison
3 - Celestial Castle"
		"Marceline":
			default_deck_choice = "Hero
Marceline

Landscapes
1 - Cornfield
1 - NiceLands
2 - Useless Swamp

Creatures
3 - Man-Witch
3 - Red Eyeling
3 - Log Knight
3 - Field Stalker
3 - Unicyclops
3 - Black Paladin
3 - Dark-o-Mint
3 - Bog Bum
3 - Lt. Mushroom
3 - Teeth Leaf
3 - Furious Rooster
3 - Furious Chick
3 - Furious Hen

Spells
3 - Clone
3 - Beach Ball
3 - Unempty Coffin
2 - Whims of Fate

Buildings
2 - Cardboard Mansion
3 - Funeral Home
2 - Night Tower
2 - Shadowy Pyramid
2 - Mausoleum
"
		"Fionna":
			default_deck_choice = "Hero
Fionna

Landscapes
4 - Blue Plains

Creatures
3 - Ancient Scholar
2 - Big Foot
2 - Cool Dog
2 - Crazy Cat Lady
2 - Drooling Dude
2 - Emboldened Retriever
2 - Fiddling Ferret
2 - Furious Chick
2 - Heavenly Gazer
3 - Happy Ghost Lucky
3 - Infant Scholar
2 - Jinxed Parrotrooper
2 - Nice Ice Baby
2 - Static Parrotrooper
1 - The Pig
2 - TNTimmy
2 - Vampire Lord
2 - X-Large Spirit Soldier
2 - Tiny Elephant

Spells
3 - Beach Ball
2 - Drop Zone
2 - Friendship Bracelet
2 - Gnome Snot
2 - River of Swords
2 - Unempty Coffin

Buildings
2 - Learning Center
3 - Celestial Castle
3 - Blood Fortress
"
		"Princess Bubblegum":
			default_deck_choice = "Hero
Princess Bubblegum

Landscapes
4 - NiceLands

Creatures
3 - Adorabunny
2 - Stitched Squirrel
3 - Huggable Hedgehog
3 - Giddy Giraffe
3 - Grizzled ZebraCorn
2 - Burly Lumberjack
3 - Popcorn Butteredfly
2 - Log Knight
3 - Husker Champion
3 - Husker Valkyrie
3 - Knit Kitty
3 - Static Parrotrooper
3 - Niceasaurus Rex

Spells
2 - Hug It Out
3 - Beach Ball
3 - Clone
2 - Ring of Fluffy
2 - Stuffed
2 - Harvest Moon

Buildings
3 - Celestial Castle
3 - Bean Ball Bomba
2 - Yellow Lighthouse
3 - Cabin of Many Woods
"
