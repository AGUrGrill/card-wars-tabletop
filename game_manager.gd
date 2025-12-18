extends Node

var round_num: int = 0
const CARD_LIST = "res://card_list.json"
const MAX_CARDS = 568 # 717 is newest, 568 is released

const DEFAULT_HP: int = 25
const DEFAULT_ACTIONS: int = 2

@export var player1_health: int = DEFAULT_HP
@export var player1_actions: int = DEFAULT_ACTIONS
@export var player1_hand: Array
@export var player1_played_creatures: Array
@export var player1_played_buildings: Array

@export var player2_health: int = DEFAULT_HP
@export var player2_actions: int = DEFAULT_ACTIONS
@export var player2_hand: Array
@export var player2_played_creatures: Array
@export var player2_played_buildings: Array

func _ready() -> void:
	return

func start_game():
	for i in range(5):
		draw_card(1)
		draw_card(2)

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
func draw_card(player_num: int):
	var json_data = GameManager.load_json_file(GameManager.CARD_LIST)
	if !json_data:
		return
	
	while true:
		var card_data = json_data[str(randi() % MAX_CARDS)]
		if card_data["Name"] == "Unknown" or card_data == null:
			continue
		elif card_data["Card Type"] != "Landscape" and card_data["Card Type"] != "Hero" and card_data["Card Type"] != "Teamwork":
			if player_num == 1:
				player1_hand.append(card_data)
			elif player_num == 2:
				player2_hand.append(card_data)
			print(str(card_data["Name"]) + " drawn for player " + str(player_num))
			break

# PLAYER FUNCTIONS
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


# LANDSCAPE MODIFICATION FUNCTIONS
func add_building_to_landscape(player_num: int, landscape_num: int, card_name: String):
	if player_num == 1:
		player1_played_buildings[landscape_num] = card_name
	elif player_num == 2:
		player2_played_buildings[landscape_num] = card_name

func add_creature_to_landscape(player_num: int, landscape_num: int, card_name: String, attack: int, defense: int):
	var creature: Array = [card_name, attack, defense]
	if player_num == 1:
		player1_played_creatures[landscape_num] = creature
	elif player_num == 2:
		player2_played_creatures[landscape_num] = creature

func update_creature_on_landscape(player_num: int, landscape_num: int, attack: int, defense: int):
	if player_num == 1:
		var temp_creature = player1_played_creatures[landscape_num]
		temp_creature[1] = attack
		temp_creature[2] = defense
		player1_played_creatures[landscape_num] = temp_creature
	elif player_num == 2:
		var temp_creature = player2_played_creatures[landscape_num]
		temp_creature[1] = attack
		temp_creature[2] = defense
		player2_played_creatures[landscape_num] = temp_creature

func remove_creature_from_landscape(player_num: int, landscape_num: int, card_name: String):
	if player_num == 1:
		player1_played_creatures[landscape_num] = ""
	elif player_num == 2:
		player2_played_creatures[landscape_num] = ""

func remove_building_from_landscape(player_num: int, landscape_num: int, card_name: String):
	if player_num == 1:
		player1_played_buildings[landscape_num] = ""
	elif player_num == 2:
		player2_played_buildings[landscape_num] = ""
