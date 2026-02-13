extends Node2D

@onready var confirm_sfx: AudioStreamPlayer2D = $Audio/ConfirmSFX
@onready var enter_deck_code: TextEdit = $EnterDeckCode
@onready var choose_deck: OptionButton = $ChooseDeck
@onready var ip_address: LineEdit = $IPAddress
@onready var port: LineEdit = $Port
@onready var log: Node2D = $Log
@onready var server_wait_timer: Timer = $ServerWaitTimer

var hero: String
var landscapes: Array[String]
var deck: Array[String]
var default_deck_choice: String
var deck_choosen: bool = false

var in_testing_mode: bool = false
var game_starting: bool = false

func _ready() -> void:
	GameManager.local_client_player_num = 0
	add_premade_decks()
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

func add_premade_decks():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("user://Decks"):
		dir.make_dir("Decks")
	if not DirAccess.open("user://Decks/").file_exists("Jake.dat"):
		var file = FileAccess.open("user://Decks/Jake.dat", FileAccess.WRITE)
		file.store_string(jake)
	if not DirAccess.open("user://Decks/").file_exists("Fionna.dat"):
		var file2 = FileAccess.open("user://Decks/Fionna.dat", FileAccess.WRITE)
		file2.store_string(fionna)
	if not DirAccess.open("user://Decks/").file_exists("Prismo.dat"):
		var file3 = FileAccess.open("user://Decks/Prismo.dat", FileAccess.WRITE)
		file3.store_string(prismo)
	if not DirAccess.open("user://Decks/").file_exists("Moniker.dat"):
		var file4 = FileAccess.open("user://Decks/Moniker.dat", FileAccess.WRITE)
		file4.store_string(moniker)
	if not DirAccess.open("user://Decks/").file_exists("The Lich.dat"):
		var file5 = FileAccess.open("user://Decks/The Lich.dat", FileAccess.WRITE)
		file5.store_string(the_lich)
	if not DirAccess.open("user://Decks/").file_exists("Gunter.dat"):
		var file6 = FileAccess.open("user://Decks/Gunter.dat", FileAccess.WRITE)
		file6.store_string(gunter)
	if not DirAccess.open("user://Decks/").file_exists("Finn.dat"):
		var file6 = FileAccess.open("user://Decks/Finn.dat", FileAccess.WRITE)
		file6.store_string(finn)

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
	log.make_log_message("Connection successful! Starting as player 1.")
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
	log.make_log_message("Connection successful! Starting as player 2.")
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
	GameManager.reset_game()
	if not deck_choosen:
		log.make_log_message("Please select a deck.")
		return
	if not in_testing_mode:
		if ip_address.text.is_empty() or port.text.is_empty():
			log.make_log_message("Please provide an IP Address and Port Number.")
			return
		NetworkHandler.set_network_address(ip_address.text, int(port.text))
	log.make_log_message("Attempting connection to server...")
	await get_tree().create_timer(0.5).timeout
	server_wait_timer.start()
	NetworkHandler.start_client()
	confirm_sfx.play()

func _on_load_deck_pressed() -> void:
	deck.clear()
	if not enter_deck_code.text.is_empty():
		parse_deck_info(enter_deck_code.text)
	elif not default_deck_choice.is_empty():
		parse_deck_info(default_deck_choice)
	else:
		log.make_log_message("No deck selected.")
		deck_choosen = false
		return
	log.make_log_message("Loaded \"" + hero +"\" Deck.")
	confirm_sfx.play()

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

func _on_server_wait_timer_timeout() -> void:
	log.make_log_message("Could not connect to server. Please try again.")

var jake: String = "Hero
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
2 - Beach Ball
2 - Field of Nightmares

Buildings
3 - Husker Garrison
3 - Celestial Castle
2 - Yellow Lighthouse
2 - Haybarn"

var fionna: String = "Hero
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
2 - Beach Ball
2 - Unempty Coffin
3 - Gnome Snot
2 - Friendship Bracelet

Buildings
3 - Learning Center
3 - Celestial Castle
3 - Blood Fortress
1 - Celestial Fortress
"

var prismo: String = "Hero
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
2 - Beach Ball
2 - Bail Out
3 - Field of Nightmares
2 - Gnome Snot
2 - Scorching Serve

Buildings
3 - Sand Castle
2 - Yellow Lighthouse
3 - Celestial Castle
2 - Blood Fortress"

var moniker: String = "Hero
Moniker

Landscapes
2 - Blue Plains
2 - Cornfield

Creatures
3 - Ancient Scholar
2 - Archer Dan
2 - Embarrassing Bard
3 - Heavenly Gazer
3 - Psionic Architect
3 - Struzann Djinn
2 - The Dog
3 - Fiddling Ferret
3 - Mr. Slicer
2 - Kernel Queen
3 - Druid of the Cob
3 - Djini Ghost
2 - Log Knight

Spells
2 - Strength Crystal
3 - Furious Furor
2 - Deforestation
2 - Puma Paw
2 - Ring of Damage
2 - Beach Ball

Buildings
3 - Celestial Castle
2 - Blood Castle
3 - Cabin of Many Woods
2 - Yellow Lighthouse"

var the_lich: String = "Hero
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
2 - Beach Ball

Buildings
3 - Monolith of Doom
3 - Funeral Home
2 - Shadowy Pyramid
2 - Yellow Lighthouse
2 - Cardboard Mansion
2 - Night Tower"

var gunter: String = "Hero
Gunter

Landscapes
2 - Useless Swamp
1 - IcyLands
1 - Blue Plains

Creatures
3 - Ancient Scholar
3 - Black Paladin
3 - Boarder Collie
2 - Cold Soldier
3 - Djini Ghost
3 - Frozen BanaNancy
3 - Frozen Fish
2 - Gray Eyebat
3 - Icy Commando
2 - Icy Infiltrator
2 - IrriGator
3 - Man-Witch
2 - Nice Ice Baby
3 - Orange Slimey
3 - Red Eyeling
3 - Smoldering Elder
3 - Snow Angel
3 - Softie Recruit
2 - Teeth Leaf
3 - Unicyclops
3 - X-Large Spirit Soldier

Spells
2 - Beach Ball
3 - Bomb Pop
3 - Freezing Point
3 - Gnome Snot
2 - Raise the Dead
3 - Snow Way

Buildings
3 - Crystal Palace
3 - Funeral Home
3 - Shadowy Pyramid
3 - Celestial Castle"

var finn: String = "Hero
Finn

Landscapes
3 - Blue Plains
1 - SandyLands

Creatures
3 - Ancient Scholar
3 - Struzann Djinn
3 - Cool Dog
3 - X-Large Spirit Soldier
3 - Infant Scholar
3 - Furious Chick
3 - Static Parrotrooper
3 - Psionic Architect
3 - Sand Knights
3 - SandWitch
3 - Jinxed Parrotrooper


Spells
3 - Puma Paw
3 - Gnome Snot
2 - Beach Ball
2 - Unempty Coffin
3 - Blood Transfusion


Buildings
3 - Schoolhouse
3 - Learning Center
3 - Celestial Castle
"
