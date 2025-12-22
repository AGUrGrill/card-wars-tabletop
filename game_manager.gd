extends Node

var round_num: int = 0
const CARD_LIST = "res://card_list.json"
const MAX_CARDS = 568 # 717 is newest, 568 is released

const DEFAULT_HP: int = 25
const DEFAULT_ACTIONS: int = 2

var player1_id: int
var player2_id: int

@export var player1_health: int = DEFAULT_HP
@export var player1_actions: int = DEFAULT_ACTIONS
@export var player1_hand: Array[Dictionary]
@export var player1_played_creatures: Array[Dictionary] = [{}, {}, {}, {}]
@export var player1_played_buildings: Array[Dictionary] = [{}, {}, {}, {}]

@export var player2_health: int = DEFAULT_HP
@export var player2_actions: int = DEFAULT_ACTIONS
@export var player2_hand: Array[Dictionary]
@export var player2_played_creatures: Array[Dictionary] = [{}, {}, {}, {}]
@export var player2_played_buildings: Array[Dictionary] = [{}, {}, {}, {}]

var player_selected_card: Dictionary

func _ready() -> void:
	return

func start_game():
	if multiplayer.is_server():
		for i in range(5):
			player1_hand.append(draw_card())
			player2_hand.append(draw_card())
		for id in multiplayer.get_peers():
			print("sending cards to " + str(id))
			update_player_hand.rpc_id(id, 1, player1_hand)
			update_player_hand.rpc_id(id, 2, player2_hand)

func start_turn():
	return

func draw_phase():
	return

func attack_phase():
	return

func end_turn():
	return

func end_game():
	return


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

# SERVER -> CLIENT UPDATES
@rpc("any_peer")
func update_player_health(player_num: int, modifier: int):
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

@rpc("any_peer")
func update_player_actions(player_num: int, modifier: int):
	if player_num == 1:
		var temp_actions = player1_actions + modifier
		if temp_actions >= 0:
			player1_actions = temp_actions
		else:
			player1_actions = 0
	elif player_num == 2:
		var temp_actions = player2_actions + modifier
		if temp_actions >= 0:
			player2_actions = temp_actions
		else:
			player2_actions = 0

@rpc("any_peer")
func update_player_hand(player_num: int, hand: Array):
	if player_num == 1:
		player1_hand = hand
	elif player_num == 2:
		player2_hand = hand

@rpc("any_peer")
func change_card_on_landscape(player_num: int, landscape_num: int, card: Dictionary):
	if player_num == 1:
		if card["Card Type"] == "Creature":
			player1_played_creatures[landscape_num] = card
		elif card["Card Type"] == "Building":
			player1_played_buildings[landscape_num] = card
	elif player_num == 2:
		if card["Card Type"] == "Creature":
			player2_played_creatures[landscape_num] = card
		elif card["Card Type"] == "Building":
			player2_played_buildings[landscape_num] = card

@rpc("any_peer")
func update_card_on_landscape(player_num: int, landscape_num: int, card_type: String, attack: int, defense: int, is_flooped: bool):
	print("Updating " + str(card_type) + " on landscape" + str(landscape_num) + " for P" + str(player_num) + "(" + str(multiplayer.get_unique_id()) + ")")
	if player_num == 1:
		if card_type == "Creature":
			player1_played_creatures[landscape_num]["Attack"] = attack
			player1_played_creatures[landscape_num]["Defense"] = defense
			player1_played_creatures[landscape_num]["Floop Status"] = is_flooped
		elif card_type == "Building":
			player1_played_buildings[landscape_num]["Floop Status"] = is_flooped
	elif player_num == 2:
		if card_type == "Creature":
			player2_played_creatures[landscape_num]["Attack"] = attack
			player2_played_creatures[landscape_num]["Defense"] = defense
			player2_played_creatures[landscape_num]["Floop Status"] = is_flooped
		elif card_type == "Building":
			player2_played_buildings[landscape_num]["Floop Status"] = is_flooped

@rpc("any_peer")
func remove_creature_from_landscape(player_num: int, landscape_num: int):
	if player_num == 1:
		player1_played_creatures[landscape_num].clear()
	elif player_num == 2:
		player2_played_creatures[landscape_num].clear()
@rpc("any_peer")
func remove_building_from_landscape(player_num: int, landscape_num: int):
	if player_num == 1:
		player1_played_buildings[landscape_num].clear()
	elif player_num == 2:
		player2_played_buildings[landscape_num].clear()
