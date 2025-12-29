extends Node

const CARD_LIST = "res://card_list.json"
const MAX_CARDS = 568 # 717 is newest, 568 is released

const DEFAULT_HP: int = 25
const DEFAULT_ACTIONS: int = 2

var player1_id: int
var player2_id: int

# PLAYER DATA
@export var player1_health: int = DEFAULT_HP
@export var player1_actions: int = DEFAULT_ACTIONS
@export var player1_hand: Array[Dictionary]
@export var player1_discards: Array[Dictionary]
@export var player1_played_creatures: Array[Dictionary] = [{}, {}, {}, {}]
@export var player1_played_buildings: Array[Dictionary] = [{}, {}, {}, {}]
var player1_selected_card: Dictionary

@export var player2_health: int = DEFAULT_HP
@export var player2_actions: int = DEFAULT_ACTIONS
@export var player2_hand: Array[Dictionary]
@export var player2_discards: Array[Dictionary]
@export var player2_played_creatures: Array[Dictionary] = [{}, {}, {}, {}]
@export var player2_played_buildings: Array[Dictionary] = [{}, {}, {}, {}]
var player2_selected_card: Dictionary

# GAME DATA
var round_num: int = 0
var game_ended: bool = false
var p1_turn: bool = true
var p2_turn: bool = false

var refresh_needed: bool = false

func start_game():
	if multiplayer.is_server():
		p1_turn = true
		p2_turn = false
		if multiplayer.is_server():
			for i in range(5):
				net_add_card_to_player_hand.rpc(1, draw_card())
				net_add_card_to_player_hand.rpc(2, draw_card())
		server_update_turn_info_for_clients(p1_turn, p2_turn, round_num)
		net_tell_clients_to_refresh.rpc()
		start_turn()

func start_turn(): 
	if multiplayer.is_server():
		if round_num > 1:
			draw_phase()

func draw_phase():
	if multiplayer.is_server():
		if p1_turn:
			net_add_card_to_player_hand.rpc(1, draw_card())
		elif p2_turn:
			net_add_card_to_player_hand.rpc(2, draw_card())
		net_tell_clients_to_refresh.rpc()

# For call when player is ready
@rpc("any_peer", "call_remote")
func client_start_attack_phase():
	if multiplayer.is_server():
		attack_phase()

func attack_phase():
	if multiplayer.is_server():
		for landscape_num in range(4):
			if p1_turn:
				if player1_played_creatures[landscape_num].is_empty():
					continue
				if player1_played_creatures[landscape_num]["Floop Status"] == false:
					var opponent_landscape_num: int = abs(landscape_num - 3)
					var p1_creature_attack: int = player1_played_creatures[landscape_num]["Attack"]
					var p1_creature_defense: int = player1_played_creatures[landscape_num]["Defense"]
					if player2_played_creatures[opponent_landscape_num].is_empty():
						net_update_player_health.rpc(2, -p1_creature_attack)
					else:
						var p2_creature_attack: int = player2_played_creatures[opponent_landscape_num]["Attack"]
						var p2_creature_defense: int = player2_played_creatures[opponent_landscape_num]["Defense"]
						net_update_creature_in_landscape_array.rpc(2, opponent_landscape_num, player2_played_creatures[opponent_landscape_num]["Card Type"], player2_played_creatures[opponent_landscape_num]["Attack"],  p2_creature_defense - p1_creature_attack, player2_played_creatures[opponent_landscape_num]["Floop Status"])
						net_update_creature_in_landscape_array.rpc(1, landscape_num, player1_played_creatures[landscape_num]["Card Type"], player1_played_creatures[landscape_num]["Attack"],  p1_creature_defense - p2_creature_attack, player1_played_creatures[landscape_num]["Floop Status"])
						print(str(landscape_num) + " fought " + str(opponent_landscape_num))
			if p2_turn:
				if player2_played_creatures[landscape_num].is_empty():
					continue
				if player2_played_creatures[landscape_num]["Floop Status"] == false:
					var opponent_landscape_num: int = abs(landscape_num - 3)
					var p2_creature_attack: int = player2_played_creatures[landscape_num]["Attack"]
					var p2_creature_defense: int = player2_played_creatures[landscape_num]["Defense"]
					if player1_played_creatures[opponent_landscape_num].is_empty():
						net_update_player_health.rpc(1, -p2_creature_attack)
					else:
						var p1_creature_attack: int = player1_played_creatures[opponent_landscape_num]["Attack"]
						var p1_creature_defense: int = player1_played_creatures[opponent_landscape_num]["Defense"]
						net_update_creature_in_landscape_array.rpc(1, opponent_landscape_num, player1_played_creatures[opponent_landscape_num]["Card Type"], player1_played_creatures[opponent_landscape_num]["Attack"],  p1_creature_defense - p2_creature_attack, player1_played_creatures[opponent_landscape_num]["Floop Status"])
						net_update_creature_in_landscape_array.rpc(2, landscape_num, player2_played_creatures[landscape_num]["Card Type"], player2_played_creatures[landscape_num]["Attack"],  p2_creature_defense - p1_creature_attack, player2_played_creatures[landscape_num]["Floop Status"])
						print(str(landscape_num) + " fought " + str(opponent_landscape_num))
		net_tell_clients_to_refresh.rpc()
		end_turn()

func end_turn():
	if multiplayer.is_server():
		if p1_turn:
			p2_turn = true
			p1_turn = false
		elif p2_turn:
			p1_turn = true
			p2_turn = false
		check_end_game()
		if not game_ended:
			round_num += 1
			server_update_turn_info_for_clients.rpc(p1_turn, p2_turn, round_num)
			start_turn()

func check_end_game():
	if multiplayer.is_server():
		if player1_health <= 0:
			print("Player 2 Wins!")
			game_ended = true
		elif player2_health <= 0:
			print("Player 1 Wins!")
			game_ended = true

@rpc("authority", "call_remote")
func server_update_turn_info_for_clients(is_p1_turn: bool, is_p2_turn: bool, _round_num: int):
	if is_p1_turn:
		p1_turn = true
		p2_turn = false
	elif is_p2_turn:
		p2_turn = true
		p1_turn = false
	round_num = _round_num


# RETRIEVE CARD DATA
func load_json_file(file_path: String) -> Dictionary:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var json_data = json.parse(json_text)
		return json.data
	else:
		print("File does not exist.")
	return {}

func get_all_cards():
	var json_data = GameManager.load_json_file(GameManager.CARD_LIST)
	if !json_data:
		return
	
	for num in MAX_CARDS:
		var card_data = json_data[str(num)]
		if card_data["Name"] == "Unknown" or card_data == null:
			continue
		elif card_data["Card Type"] != "Landscape" and card_data["Card Type"] != "Hero" and card_data["Card Type"] != "Teamwork":
			print(card_data)

func get_specific_card_data_from_list(card_name: String):
	var json_data = GameManager.load_json_file(GameManager.CARD_LIST)

	for num in MAX_CARDS:
		var card_data = json_data[str(num)]
		if card_data["Name"] == "Unknown" or card_data == null:
			continue
		elif card_data["Card Type"] != "Landscape" and card_data["Card Type"] != "Hero" and card_data["Card Type"] != "Teamwork":
			if card_data["Name"] == card_name:
				return card_data
	
# DRAW FUNCTIONS
func draw_card():
	var json_data = GameManager.load_json_file(GameManager.CARD_LIST)
	if !json_data:
		return
	
	while true:
		var card_data = json_data[str(randi() % MAX_CARDS)]
		if card_data["Name"] == "Unknown" or card_data == null:
			continue
		elif card_data["Card Type"] != "Landscape" and card_data["Card Type"] != "Hero" and card_data["Card Type"] != "Teamwork":
			return card_data

# MISC
func can_card_can_be_played(player_num: int, card: Dictionary) -> bool:
	if player_num == 1:
		if GameManager.player1_actions - int(card["Cost"]) < 0:
			print("Card cost too high.")
			return false
	elif player_num == 2:
		if GameManager.player2_actions - int(card["Cost"]) < 0:
			print("Card cost too high.")
			return false
	return true

func print_all_stats():
	print("PLAYER 1")
	print ("HP: " + str(player1_health), ", ACTIONS: " + str(player1_actions))
	var hand: String
	for card in player1_hand:
		if card != null:
			hand += card["Name"] + ", "
	print("HAND: " + str(hand))
	var discards: String
	for card in player1_discards:
		if card != null:
			for key in card:
				if key == "Name":
					discards += card["Name"] + ", "
				else:
					discards += ", "
	print("DISCARDS: " + str(discards))
	var played_creatures: String
	for card in player1_played_creatures:
		if card != null:
			for key in card:
				if key == "Name":
					played_creatures += card["Name"] + " [" + str(card["Attack"]) + ", " + str(card["Defense"]) + "], "
				else:
					played_creatures += ", "
	print("PLAYED CREATURES: " + str(played_creatures))
	var played_buildings: String
	for card in player1_played_buildings:
		if card != null:
			for key in card:
				if key == "Name":
					played_buildings += card["Name"] + ", "
				else:
					played_buildings += ", "
	print("PLAYED BUILDINGS: " + str(played_buildings))
	if player1_selected_card != null:
		for key in player1_selected_card:
			if key == "Name":
				print("SELECTED CARD: " + str(player1_selected_card["Name"]))
	
	print("PLAYER 2")
	print ("HP: " + str(player2_health), ", ACTIONS: " + str(player2_actions))
	var hand2: String
	for card in player2_hand:
		if card != null:
			hand2 += card["Name"] + ", "
	print("HAND: " + str(hand2))
	var discards2: String
	for card in player2_discards:
		if card != null:
			for key in card:
				if key == "Name":
					discards2 += card["Name"] + ", "
				else:
					discards2 += ", "
	print("DISCARDS: " + str(discards2))
	var played_creatures2: String
	for card in player2_played_creatures:
		if card != null:
			for key in card:
				if key == "Name":
					played_creatures2 += card["Name"] + " [" + str(card["Attack"]) + ", " + str(card["Defense"]) + "], "
				else:
					played_creatures2 += ", "
	print("PLAYED CREATURES: " + str(played_creatures2))
	var played_buildings2: String
	for card in player2_played_buildings:
		if card != null:
			for key in card:
				if key == "Name":
					played_buildings2 += card["Name"] + ", "
				else:
					played_buildings2 += ", "
	print("PLAYED BUILDINGS: " + str(played_buildings2))
	if player2_selected_card != null:
		for key in player1_selected_card:
			if key == "Name":
				print("SELECTED CARD: " + str(player2_selected_card["Name"]))

@rpc("any_peer", "call_local")
func net_tell_clients_to_refresh():
	GameManager.refresh_needed = true

# PLAYER STAT UPDATES
@rpc("any_peer", "call_local")
func net_update_player_health(player_num: int, modifier: int):
	if player_num == 1:
		var temp_health = player1_health + modifier
		if temp_health >= 0:
			player1_health = temp_health
		else:
			player1_health = 0
	elif player_num == 2:
		var temp_health = player2_health + modifier
		if temp_health >= 0:
			player2_health = temp_health
		else:
			player2_health = 0

@rpc("any_peer", "call_local")
func net_update_player_actions(player_num: int, modifier: int):
	if player_num == 1:
		var temp_actions = player1_actions + modifier
		if temp_actions > 0:
			print("Total: " + str(player1_actions) + " + " + str(modifier) + " = " + str(temp_actions))
			player1_actions = temp_actions
		elif temp_actions <= 0:
			player1_actions = 0
	elif player_num == 2:
		var temp_actions = player2_actions + modifier
		if temp_actions > 0:
			print("Total: " + str(player1_actions) + " + " + str(modifier) + " = " + str(temp_actions))
			player2_actions = temp_actions
		elif temp_actions <= 0:
			player2_actions = 0

# PLAYER HAND UPDATES
@rpc("any_peer", "call_local")
func net_remove_card_from_player_hand(player_num: int, _card: Dictionary):
	if player_num == 1:
		for card in player1_hand:
			if card["Name"] == _card["Name"]:
				player1_hand.remove_at(player1_hand.find(card))
	elif player_num == 2:
		for card in player2_hand:
			if card["Name"] == _card["Name"]:
				player2_hand.remove_at(player2_hand.find(card))

@rpc("any_peer", "call_local")
func net_add_card_to_player_hand(player_num: int, card: Dictionary):
	if player_num == 1:
		player1_hand.append(card)
	elif player_num == 2:
		player2_hand.append(card)

# PLAYER DISCARDS UPDATES
@rpc("any_peer", "call_local")
func net_remove_card_from_player_discards(player_num: int, _card: Dictionary):
	if player_num == 1:
		for card in player1_discards:
			if card["Name"] == _card["Name"]:
				player1_discards.remove_at(player1_discards.find(card))
	elif player_num == 2:
		for card in player2_hand:
			if card["Name"] == _card["Name"]:
				player2_discards.remove_at(player2_discards.find(card))

@rpc("any_peer", "call_local")
func net_add_card_to_player_discards(player_num: int, card: Dictionary):
	if player_num == 1:
		player1_discards.append(card)
	elif player_num == 2:
		player2_discards.append(card)

# LANDSCAPE UPDATES
@rpc("any_peer", "call_local") 
func net_add_creature_to_landscape_array(player_num: int, landscape_num: int, card: Dictionary):
	if player_num == 1:
		player1_played_creatures[landscape_num] = card
	elif player_num == 2:
		player2_played_creatures[landscape_num] = card

@rpc("any_peer", "call_local")
func net_update_creature_in_landscape_array(player_num: int, landscape_num: int, card_type: String, new_attack: int, new_defense: int, is_flooped: bool):
	if player_num == 1:
		if card_type == "Creature":
			player1_played_creatures[landscape_num]["Attack"] = new_attack
			player1_played_creatures[landscape_num]["Defense"] = new_defense
			player1_played_creatures[landscape_num]["Floop Status"] = is_flooped
		elif card_type == "Building":
			player1_played_buildings[landscape_num]["Floop Status"] = is_flooped
	elif player_num == 2:
		if card_type == "Creature":
			player2_played_creatures[landscape_num]["Attack"] = new_attack
			player2_played_creatures[landscape_num]["Defense"] = new_defense
			player2_played_creatures[landscape_num]["Floop Status"] = is_flooped
		elif card_type == "Building":
			player2_played_buildings[landscape_num]["Floop Status"] = is_flooped

@rpc("any_peer", "call_local") 
func net_add_building_to_landscape_array(player_num: int, landscape_num: int, card: Dictionary):
	if player_num == 1:
		player1_played_buildings[landscape_num] = card
	elif player_num == 2:
		player2_played_buildings[landscape_num] = card

@rpc("any_peer", "call_local") 
func net_remove_creature_from_landscape_array(player_num: int, landscape_num: int):
	if player_num == 1:
		player1_played_creatures[landscape_num].clear()
	elif player_num == 2:
		player2_played_creatures[landscape_num].clear()

@rpc("any_peer", "call_local") 
func net_remove_building_from_landscape_array(player_num: int, landscape_num: int):
	if player_num == 1:
		player1_played_buildings[landscape_num].clear()
	elif player_num == 2:
		player2_played_buildings[landscape_num].clear()

# MISC
@rpc("any_peer", "call_local") 
func net_update_player_selected_card(player_num: int, card: Dictionary):
	if player_num == 1:
		player1_selected_card = card
	elif player_num == 2:
		player2_selected_card = card
