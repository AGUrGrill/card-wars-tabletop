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
	GameManager.player1_hero = hero
	for card_name in deck:
		GameManager.player1_deck.append(GameManager.draw_by_name(card_name))
	await get_tree().create_timer(3).timeout
	#GameManager.client_give_player_id.rpc(1, multiplayer.get_unique_id())
	GameManager.player1_id = multiplayer.get_unique_id()
	GameManager.recieve_player_deck.rpc(1, GameManager.player1_deck)
	GameManager.recieve_player_hero.rpc(1, hero)
	confirm_sfx.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/board.tscn")

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
	await get_tree().create_timer(3).timeout
	#GameManager.client_give_player_id.rpc(2, multiplayer.get_unique_id())
	GameManager.player2_id = multiplayer.get_unique_id()
	GameManager.recieve_player_deck.rpc(2, GameManager.player2_deck)
	GameManager.recieve_player_hero.rpc(2, hero)
	confirm_sfx.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/board.tscn")

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
		"☆ Magic Man":
			default_deck_choice = "Hero
Magic Man

Landscapes
4 - Cornfield

Creatures
3 - Corn Ronin
3 - Corn Lord
3 - Cornataur
3 - Ethan Allfire
3 - Field Reaper
3 - Field Stalker
3 - Husker Knight
3 - Husker Champion
3 - Wall of Ears
3 - Husker Valkyrie

Spells
3 - Beach Ball
2 - Bale Out
3 - Field of Nightmares
2 - Unempty Coffin

Buildings
3 - Husker Garrison
2 - Blood Fortress
3 - Celestial Castle
2 - Yellow Lighthouse
"
		"☆☆ Jake":
			default_deck_choice = "Hero
Jake

Landscapes
4 - Cornfield

Creatures
3 - Earth Mover
3 - Husker Worm
3 - Quake Maker
3 - The Pig
3 - Big Foot
3 - Feedman
3 - Field Reaper
3 - Field Stalker
3 - Husker Champion
3 - Husker Valkyrie
2 - Patchy the Pumpkin

Spells
3 - Reclaim Landscape
2 - Rock Out!
2 - Volcano
3 - Beach Ball
2 - Field of Nightmares

Buildings
3 - Husker Garrison
3 - Celestial Castle
2 - Yellow Lighthouse
2 - Haybarn
"
		"☆☆ Fionna":
			default_deck_choice = "Hero
Fionna

Landscapes
4 - Blue Plains

Creatures
3 - Ancient Scholar
3 - Crazy Cat Lady
2 - Emboldened Retriever
3 - Fiddling Ferret
3 - Heavenly Gazer
3 - Infant Scholar
3 - Tiny Elephant
2 - TNTimmy
3 - Vampire Lord
3 - Static Parrotrooper
3 - X-Large Spirit Soldier
2 - Drooling Dude
3 - Furious Chick

Spells
3 - Beach Ball
2 - Unempty Coffin
3 - Gnome Snot
2 - Friendship Bracelet

Buildings
3 - Learning Center
3 - Celestial Castle
3 - Blood Fortress
1 - Celestial Fortress
"
		"☆☆ Prismo":
			default_deck_choice = "Hero
Prismo

Landscapes
1 - Blue Plains
1 - NiceLands
1 - Cornfield
1 - SandyLands

Creatures
3 - Ancient Scholar
3 - Beach Mummy
3 - Fancy Zebracorn
2 - Field Stalker
2 - Fummy
3 - Gold Ninja
3 - Heavenly Gazer
3 - Lime Slimey
3 - Niceasaurus Rex
3 - Sand Knights
2 - Sandhorn Devil
2 - SandWitch
3 - Rebounding Zebracorn
3 - Strawberry Slimey
3 - Yellow Slimey

Spells
3 - Beach Ball
2 - Bail Out
3 - Field of Nightmares
2 - Gnome Snot
2 - Scorching Serve

Buildings
3 - Sand Castle
2 - Yellow Lighthouse
3 - Celestial Castle
2 - Blood Fortress
"
		"☆☆☆ The Lich":
			default_deck_choice = "Hero
The Lich

Landscapes
2 - Cornfield
2 - Useless Swamp

Creatures
3 - Man-Witch
3 - Helping Hand
3 - Log Knight
3 - Black Paladin
3 - Bog Bum
3 - Fly Swatter
2 - Field Reaper
3 - Gray Eyebat
3 - Lt. Mushroom
3 - Teeth Leaf
3 - Unicyclops
3 - Red Eyeling
3 - Immortal Maize Walker
2 - Field Stalker

Spells
3 - Ancient Comet
3 - Unempty Coffin
3 - Whims of Fate
3 - Beach Ball

Buildings
3 - Monolith of Doom
3 - Funeral Home
2 - Shadowy Pyramid
2 - Yellow Lighthouse
2 - Cardboard Mansion
2 - Night Tower
"
		"☆☆☆ James Baxter":
			default_deck_choice = "Hero
James Baxter

Landscapes
1 - Blue Plains
2 - SandyLands
1 - Useless Swamp

Creatures
3 - Orange Slimey
3 - Fisher Fish
3 - Golden Axe Stump
3 - Blue Slimey
2 - Fummy
3 - Gray Eyebat
3 - Heavenly Gazer
3 - Lime Slimey
3 - Red Eyeling
3 - SandWitch
3 - Sand Knights
3 - Static Parrotrooper

Spells
3 - Quick Pick Me Up
3 - Drop Zone
3 - Snake Eye Ring
3 - Beach Ball

Buildings
3 - Sand Sphinx
2 - Bongo Bounce House
3 - Celestial Castle
3 - Shadowy Pyramid

"
