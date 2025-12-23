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

# GAME DATA
var round: int = 0
var turn_num: int = 0

func _ready() -> void:
	return

func start_game():
	if multiplayer.is_server():
		for i in range(5):
			player1_hand.append(draw_card())
			player2_hand.append(draw_card())
		update_player_hand.rpc(1, player1_hand)
		update_player_hand.rpc(2, player2_hand)
	start_turn()

func start_turn(): 
	# Update round every 2 turns, (p1 and p2)
	if turn_num % 2 == 0:
		round += 1  
	# Update turns played  
	turn_num += 1
	# If not first round draw
	if round != 1:
		draw_phase()

func draw_phase():
	if turn_num == 1:
		player1_hand.append(draw_card())
		update_player_hand.rpc(1, player1_hand)
	elif turn_num == 2:
		player2_hand.append(draw_card())
		update_player_hand.rpc(2, player2_hand)

# For call when player is ready
func start_attack_phase():
	attack_phase()

func attack_phase():
	for landscape_num in range(4):
		if turn_num == 1:
			if not player1_played_creatures[landscape_num]["Floop Status"]:
				var p1_creature_attack: int = player1_played_creatures[landscape_num]["Attack"]
				var p1_creature_defense: int = player1_played_creatures[landscape_num]["Defense"]
				var p2_creature_attack: int = player1_played_creatures[landscape_num]["Attack"]
				var p2_creature_defense: int = player1_played_creatures[landscape_num]["Defense"]
				player2_played_creatures[landscape_num]["Defense"] = p2_creature_defense - p1_creature_attack
				player1_played_creatures[landscape_num]["Defense"] = p1_creature_defense - p2_creature_attack
		if round % 2 == 0:
			if not player1_played_creatures[landscape_num]["Floop Status"]:
				var p1_creature_attack: int = player1_played_creatures[landscape_num]["Attack"]
				var p1_creature_defense: int = player1_played_creatures[landscape_num]["Defense"]
				var p2_creature_attack: int = player1_played_creatures[landscape_num]["Attack"]
				var p2_creature_defense: int = player1_played_creatures[landscape_num]["Defense"]
				player2_played_creatures[landscape_num]["Defense"] = p2_creature_defense - p1_creature_attack
				player1_played_creatures[landscape_num]["Defense"] = p1_creature_defense - p2_creature_attack
func end_turn():
	round += 1
	start_turn()

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

@rpc("any_peer") # FOR SERVER USE
func update_player_hand(player_num: int, hand: Array):
	if player_num == 1:
		player1_hand = hand
	elif player_num == 2:
		player2_hand = hand

@rpc("any_peer", "call_local") 
func update_player_selected_card(card: Dictionary):
	print("Selected " + str(card))
	player_selected_card = card

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
