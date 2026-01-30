extends Node

#region Variables
const CARD_LIST = "res://card_list.json"
var db: CardDatabase = preload("res://Assets/Database/CardDatabase.tres")
const MAX_CARDS = 568 # 717 is newest, 568 is released

const DEFAULT_HP: int = 25
const DEFAULT_ACTIONS: int = 2

var player1_id: int
var player2_id: int

# PLAYER DATA
var player1_hero: String
var player1_deck: Array[Dictionary]
@export var player1_health: int = DEFAULT_HP
@export var player1_actions: int = DEFAULT_ACTIONS
@export var player1_hand: Array[Dictionary]
@export var player1_discards: Array[Dictionary]
@export var player1_played_creatures: Array[Dictionary] = [{}, {}, {}, {}]
@export var player1_played_buildings: Array[Dictionary] = [{}, {}, {}, {}]
var player1_landscapes: Array[String] = ["", "", "", ""]
var player1_current_spell: Dictionary
var player1_selected_card: Dictionary

var player2_hero: String
var player2_deck: Array[Dictionary]
@export var player2_health: int = DEFAULT_HP
@export var player2_actions: int = DEFAULT_ACTIONS
@export var player2_hand: Array[Dictionary]
@export var player2_discards: Array[Dictionary]
@export var player2_played_creatures: Array[Dictionary] = [{}, {}, {}, {}]
@export var player2_played_buildings: Array[Dictionary] = [{}, {}, {}, {}]
var player2_landscapes: Array[String] = ["", "", "", ""]
var player2_current_spell: Dictionary
var player2_selected_card: Dictionary

# GAME DATA
var round_num: int = 0
var game_ended: bool = false
var who_won: bool = false # P1 = false, P2 = true
var p1_turn: bool = true
var p2_turn: bool = false

var hand_refresh_needed: bool = false
var stat_refresh_needed: bool = false
var landscape_refresh_needed: bool = false
var hero_refresh_needed: bool = false

#endregion
#region Game Logic

func start_game():
	if multiplayer.is_server():
		#server_distribute_player_ids.rpc(player1_id, player2_id)
		player1_deck.shuffle()
		player2_deck.shuffle()
		p1_turn = true
		p2_turn = false
		if multiplayer.is_server():
			for i in range(5):
				net_add_card_to_player_hand.rpc(1, draw_card(1))
				net_add_card_to_player_hand.rpc(2, draw_card(2))
		server_distribute_deck_info_to_client.rpc(player1_deck, player2_deck, player1_hero, player2_hero)
		server_update_turn_info_for_clients.rpc(p1_turn, p2_turn, round_num)
		net_tell_clients_to_refresh_hand.rpc()
		net_tell_clients_to_refresh_landscapes.rpc()
		net_tell_clients_to_refresh_stats.rpc()
		net_tell_clients_to_refresh_hero.rpc()
		start_turn()

func start_turn(): 
	if multiplayer.is_server():
		if round_num > 1:
			# ehh, good enough to reset to 2
			if player1_actions == 1:
				net_update_player_actions.rpc(1, 1)
			elif player1_actions == 0:
				net_update_player_actions.rpc(1, 2)
			if player2_actions == 1:
				net_update_player_actions.rpc(2, 1)
			elif player2_actions == 0:
				net_update_player_actions.rpc(2, 2)
			draw_phase()

func draw_phase():
	if multiplayer.is_server():
		if p1_turn:
			net_add_card_to_player_hand.rpc(1, draw_card(1))
		elif p2_turn:
			net_add_card_to_player_hand.rpc(2, draw_card(2))
		net_tell_clients_to_refresh_hand.rpc()

# For call when player is ready
@rpc("any_peer", "call_remote")
func client_start_attack_phase():
	if multiplayer.is_server():
		if round_num > 0:
			attack_phase()
		else:
			end_turn()

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
		net_tell_clients_to_refresh_landscapes.rpc()
		net_tell_clients_to_refresh_stats.rpc()
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
			net_declare_game_end.rpc(true)
		elif player2_health <= 0:
			print("Player 1 Wins!")
			game_ended = true
			net_declare_game_end.rpc(false)

func terminate_game():
	if not multiplayer.is_server():
		return
		
	for peer_id in multiplayer.get_peers():
		NetworkHandler.peer.disconnect_peer(peer_id, false)
	
	player1_id = 0
	player2_id = 0
	# PLAYER DATA
	player1_hero = ""
	player1_deck.clear()
	player1_health = DEFAULT_HP
	player1_actions = DEFAULT_ACTIONS
	player1_hand.clear()
	player1_discards.clear()
	player1_played_creatures = [{}, {}, {}, {}]
	player1_played_buildings = [{}, {}, {}, {}]
	player1_landscapes = ["", "", "", ""]
	player1_current_spell.clear()
	player1_selected_card.clear()

	player2_hero =""
	player2_deck.clear()
	player2_health = DEFAULT_HP
	player2_actions= DEFAULT_ACTIONS
	player2_hand.clear()
	player2_discards.clear()
	player2_played_creatures = [{}, {}, {}, {}]
	player2_played_buildings = [{}, {}, {}, {}]
	player2_landscapes = ["", "", "", ""]
	player2_current_spell.clear()
	player2_selected_card.clear()
	round_num = 0
	game_ended = false
	who_won = false # P1 = false, P2 = true
	p1_turn = true
	p2_turn = false

	hand_refresh_needed = false
	stat_refresh_needed = false
	landscape_refresh_needed = false
	hero_refresh_needed = false

@rpc("authority", "call_remote")
func net_declare_game_end(was_p2_winner: bool):
	game_ended = true
	if was_p2_winner:
		who_won = true 
	else:
		who_won = false

@rpc("authority", "call_remote")
func server_update_turn_info_for_clients(is_p1_turn: bool, is_p2_turn: bool, _round_num: int):
	if is_p1_turn:
		p1_turn = true
		p2_turn = false
	elif is_p2_turn:
		p2_turn = true
		p1_turn = false
	round_num = _round_num
#endregion
#region Get Data

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

@rpc("any_peer", "call_remote")
func recieve_player_deck(player_num: int, deck: Array[Dictionary]):
	if multiplayer.is_server():
		if player_num == 1:
			player1_deck = deck
			print("Loaded P1 Deck")
		elif player_num == 2:
			print("Loaded P2 Deck")
			player2_deck = deck
		print(deck)

@rpc("any_peer", "call_remote")
func recieve_player_hero(player_num: int, hero: String):
	if multiplayer.is_server():
		if player_num == 1:
			player1_hero = hero
		elif player_num == 2:
			player2_hero = hero

@rpc("authority", "call_remote")
func server_distribute_deck_info_to_client(p1_deck, p2_deck, p1_hero, p2_hero):
	player1_deck = p1_deck
	player2_deck = p2_deck
	player1_hero = p1_hero
	player2_hero = p2_hero

@rpc("any_peer", "call_remote")
func client_give_player_id(player_num: int, id: int):
	if multiplayer.is_server():
		if player_num == 1:
			player1_id = id
		elif player_num == 2:
			player2_id = id

@rpc("authority", "call_remote")
func server_distribute_player_ids(p1_id: int, p2_id: int):
	player1_id = p1_id
	player2_id = p2_id
#endregion
#region Updates

# DRAW FUNCTIONS
func draw_card(player_num: int):
	while true:
		var card_data
		if player_num == 1:
			if player1_deck.is_empty():
				print("Out of cards in p1 deck.")
				return
			card_data = player1_deck.pop_back()
			#player1_deck.remove_at(player1_deck.find(card_data))
		elif player_num == 2:
			if player2_deck.is_empty():
				print("Out of cards in p2 deck.")
				return
			card_data = player2_deck.pop_back()
			#player2_deck.remove_at(player2_deck.find(card_data))
		print(card_data)
		return card_data

# Could be removed, made on accident
func draw_player_card_by_name(player_num: int, name: String):
	var card_data
	if player_num == 1:
		if player1_deck.is_empty():
			print("Out of cards in p1 deck.")
			return
		for card in player1_deck:
			if card["Name"] == name:
				card_data = player1_deck.pop_at(player1_deck.find(card))
				print(card_data)
				return card_data
	elif player_num == 2:
		if player2_deck.is_empty():
			print("Out of cards in p2 deck.")
			return
		for card in player2_deck:
			if card["Name"] == name:
				card_data = player2_deck.pop_at(player2_deck.find(card))
				print(card_data)
				return card_data

func draw_by_name(name: String):
	var json_data = GameManager.load_json_file(GameManager.CARD_LIST)
	if !json_data:
		return 
	
	var card_data: Dictionary
	for idx in range(MAX_CARDS):
		card_data = json_data[str(idx)]
		if card_data["Name"] == name:
			break
	if card_data["Name"] == "Unknown" or card_data == null:
		return
	elif card_data["Card Type"] != "Landscape" and card_data["Card Type"] != "Hero" and card_data["Card Type"] != "Teamwork":
		return card_data

# MISC
func shuffle_deck(player_num: int):
	if player_num == 1:
		player1_deck.shuffle()
	elif player_num == 1:
		player2_deck.shuffle()
	server_distribute_deck_info_to_client.rpc(player1_deck, player2_deck, player1_hero, player2_hero)

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

func return_all_stats() -> String:
	var return_string: String = ""
	return_string += "PLAYER 1\n"
	return_string += "HP: " + str(player1_health) + ", ACTIONS: " + str(player1_actions) + "\n"
	var hand: String
	for card in player1_hand:
		if card != null:
			hand += card["Name"] + ", "
	return_string += "HAND: " + str(hand) + "\n"
	var discards: String
	for card in player1_discards:
		if card != null:
			for key in card:
				if key == "Name":
					discards += card["Name"] + ", "
				else:
					discards += ", "
	return_string += "DISCARDS: " + str(discards) + "\n"
	var played_creatures: String
	for card in player1_played_creatures:
		if card != null:
			for key in card:
				if key == "Name":
					played_creatures += card["Name"] + " [" + str(card["Attack"]) + ", " + str(card["Defense"]) + "], "
				else:
					played_creatures += ", "
	return_string += "PLAYED CREATURES: " + str(played_creatures) + "\n"
	var played_buildings: String
	for card in player1_played_buildings:
		if card != null:
			for key in card:
				if key == "Name":
					played_buildings += card["Name"] + ", "
				else:
					played_buildings += ", "
	return_string += "PLAYED BUILDINGS: " + str(played_buildings) + "\n"
	if player1_selected_card != null:
		for key in player1_selected_card:
			if key == "Name":
				print("SELECTED CARD: " + str(player1_selected_card["Name"]))
	var deck: String
	for card in player1_deck:
		if card != null:
			for key in card:
				if key == "Name":
					deck += card["Name"] + ", "
				else:
					deck += ", "
	return_string += "DECK: " + str(deck) + "\n"
	
	return_string += "PLAYER 2" + "\n"
	return_string += "HP: " + str(player2_health) + ", ACTIONS: " + str(player2_actions) + "\n"
	var hand2: String
	for card in player2_hand:
		if card != null:
			hand2 += card["Name"] + ", "
	return_string += "HAND: " + str(hand2) + "\n"
	var discards2: String
	for card in player2_discards:
		if card != null:
			for key in card:
				if key == "Name":
					discards2 += card["Name"] + ", "
				else:
					discards2 += ", "
	return_string += "DISCARDS: " + str(discards2) + "\n"
	var played_creatures2: String
	for card in player2_played_creatures:
		if card != null:
			for key in card:
				if key == "Name":
					played_creatures2 += card["Name"] + " [" + str(card["Attack"]) + ", " + str(card["Defense"]) + "], "
				else:
					played_creatures2 += ", "
	return_string += "PLAYED CREATURES: " + str(played_creatures2) + "\n"
	var played_buildings2: String
	for card in player2_played_buildings:
		if card != null:
			for key in card:
				if key == "Name":
					played_buildings2 += card["Name"] + ", "
				else:
					played_buildings2 += ", "
	return_string += "PLAYED BUILDINGS: " + str(played_buildings2) + "\n"
	if player2_selected_card != null:
		for key in player1_selected_card:
			if key == "Name":
				return_string += "SELECTED CARD: " + str(player2_selected_card["Name"]) + "\n"
	var deck2: String
	for card in player2_deck:
		if card != null:
			for key in card:
				if key == "Name":
					deck2 += card["Name"] + ", "
				else:
					deck2 += ", "
	return_string += "DECK: " + str(deck2) + "\n"
	
	return return_string

@rpc("any_peer", "call_local")
func net_tell_clients_to_refresh_hand():
	hand_refresh_needed = true

@rpc("any_peer", "call_local")
func net_tell_clients_to_refresh_stats():
	stat_refresh_needed = true

@rpc("any_peer", "call_local")
func net_tell_clients_to_refresh_landscapes():
	landscape_refresh_needed = true

@rpc("any_peer", "call_local")
func net_tell_clients_to_refresh_hero():
	hero_refresh_needed = true

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
	net_tell_clients_to_refresh_stats.rpc()

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
	net_tell_clients_to_refresh_stats.rpc()

# PLAYER HAND UPDATES
@rpc("any_peer", "call_local")
func net_remove_card_from_player_hand(player_num: int, _card: Dictionary):
	if player_num == 1:
		for card in player1_hand:
			if card["Name"] == _card["Name"]:
				player1_hand.remove_at(player1_hand.find(card))
				break
	elif player_num == 2:
		for card in player2_hand:
			if card["Name"] == _card["Name"]:
				player2_hand.remove_at(player2_hand.find(card))
				break
	net_tell_clients_to_refresh_hand.rpc()

@rpc("any_peer", "call_local")
func net_add_card_to_player_hand(player_num: int, card: Dictionary):
	if player_num == 1:
		player1_hand.append(card)
	elif player_num == 2:
		player2_hand.append(card)
	net_tell_clients_to_refresh_hand.rpc()

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
	var modified_card: Dictionary
	modified_card = {
		"Name": card["Name"],
		"Card Type": card["Card Type"],
		"Landscape": card["Landscape"],
		"Ability": card["Ability"],
		"Cost": card["Cost"],
		"Attack": card["Attack"],
		"Defense": card["Defense"],
		"Floop Status": card["Floop Status"],
		"Landscape Played": -1,
		"Owner": card["Owner"]
	}
	print(modified_card)
	if player_num == 1:
		player1_discards.append(modified_card)
	elif player_num == 2:
		player2_discards.append(modified_card)

# PLAYER DECK UPDATES
@rpc("any_peer", "call_local")
func net_remove_card_from_player_deck(player_num: int, _card: Dictionary):
	if player_num == 1:
		if player1_deck.is_empty():
			print("Out of cards in p1 deck.")
			return
		player1_deck.remove_at(player1_deck.find(_card))
	elif player_num == 2:
		if player2_deck.is_empty():
			print("Out of cards in p2 deck.")
			return
		player2_deck.remove_at(player2_deck.find(_card))

# LANDSCAPE UPDATES
@rpc("any_peer", "call_local") 
func net_add_creature_to_landscape_array(player_num: int, landscape_num: int, card: Dictionary):
	if player_num == 1:
		player1_played_creatures[landscape_num] = card
	elif player_num == 2:
		player2_played_creatures[landscape_num] = card
	net_tell_clients_to_refresh_landscapes.rpc()

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
	net_tell_clients_to_refresh_landscapes.rpc()

@rpc("any_peer", "call_local") 
func net_add_building_to_landscape_array(player_num: int, landscape_num: int, card: Dictionary):
	if player_num == 1:
		player1_played_buildings[landscape_num] = card
	elif player_num == 2:
		player2_played_buildings[landscape_num] = card
	net_tell_clients_to_refresh_landscapes.rpc()

@rpc("any_peer", "call_local") 
func net_remove_creature_from_landscape_array(player_num: int, landscape_num: int):
	if player_num == 1:
		player1_played_creatures[landscape_num].clear()
	elif player_num == 2:
		player2_played_creatures[landscape_num].clear()
	net_tell_clients_to_refresh_landscapes.rpc()

@rpc("any_peer", "call_local") 
func net_remove_building_from_landscape_array(player_num: int, landscape_num: int):
	if player_num == 1:
		player1_played_buildings[landscape_num].clear()
	elif player_num == 2:
		player2_played_buildings[landscape_num].clear()
	net_tell_clients_to_refresh_landscapes.rpc()

@rpc("any_peer", "call_local") 
func net_change_player_landscape(player_num: int, landscape_num: int, type: String):
	if player_num == 1:
		player1_landscapes[landscape_num] = type
	elif player_num == 2:
		player2_landscapes[landscape_num] = type
	net_tell_clients_to_refresh_landscapes.rpc()

@rpc("any_peer", "call_local") 
func net_add_spell_to_play(player_num: int, card: Dictionary):
	if player_num == 1:
		player1_current_spell = card
	elif player_num == 2:
		player2_current_spell = card
	net_tell_clients_to_refresh_landscapes.rpc()

@rpc("any_peer", "call_local") 
func net_remove_spell_from_play(player_num: int):
	if player_num == 1:
		player1_current_spell.clear()
	elif player_num == 2:
		player2_current_spell.clear()
	net_tell_clients_to_refresh_landscapes.rpc()

# MISC
@rpc("any_peer", "call_local") 
func net_update_player_selected_card(player_num: int, card: Dictionary):
	if not card.is_empty():
		print("selected " + card["Name"])
	if player_num == 1:
		player1_selected_card = card
	elif player_num == 2:
		player2_selected_card = card
#endregion
