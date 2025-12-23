extends Area2D

@onready var card: Area2D = $Card
@onready var player: Node2D = $".."
@onready var image: Sprite2D = $Image

@export var landscape_num: int = 0
@export var designated_card_type: String = "Creature"

func _ready() -> void:
	if designated_card_type == "Building":
		remove_child(image)	

func update_card_on_landscape():
	var temp_card: Dictionary
	if player.player_num == 1:
		if designated_card_type == "Creature":
			temp_card = GameManager.player1_played_creatures[landscape_num]
		elif designated_card_type == "Building":
			temp_card = GameManager.player1_played_buildings[landscape_num]
	elif player.player_num == 2:
		if designated_card_type == "Creature":
			temp_card = GameManager.player2_played_creatures[landscape_num]
		elif designated_card_type == "Building":
			temp_card = GameManager.player2_played_buildings[landscape_num]
	if not temp_card.is_empty():
		# This is calling on hyper speed but it works so ill kms or something
		#print(str(multiplayer.get_unique_id()) + " | P1 " + str(GameManager.player1_played_creatures))
		#print(str(multiplayer.get_unique_id()) + " | P2 " + str(GameManager.player2_played_creatures))
		print("Placed " + str(temp_card["Card Name"]) + " on landscape " + str(landscape_num))
		card.change_card_data(temp_card["Landscape"], temp_card["Card Type"], temp_card["Card Name"], temp_card["Ability"], temp_card["Cost"], temp_card["Attack"], temp_card["Defense"], temp_card["Floop Status"])

@rpc("any_peer", "call_local")
func update_card_data_on_landscape(player_num: int, landscape_num: int, card_type: String, attack: int, defense: int, is_flooped: bool):
	var c
	if player_num == 1:
		if card_type == "Creature":
			GameManager.player1_played_creatures[landscape_num]["Attack"] = attack
			GameManager.player1_played_creatures[landscape_num]["Defense"] = defense
			GameManager.player1_played_creatures[landscape_num]["Floop Status"] = is_flooped
			c = GameManager.player1_played_creatures[landscape_num]
		elif card_type == "Building":
			GameManager.player1_played_buildings[landscape_num]["Floop Status"] = is_flooped
			c = GameManager.player1_played_buildings[landscape_num]
	elif player_num == 2:
		if card_type == "Creature":
			GameManager.player2_played_creatures[landscape_num]["Attack"] = attack
			GameManager.player2_played_creatures[landscape_num]["Defense"] = defense
			GameManager.player2_played_creatures[landscape_num]["Floop Status"] = is_flooped
			c = GameManager.player2_played_creatures[landscape_num]
		elif card_type == "Building":
			GameManager.player2_played_buildings[landscape_num]["Floop Status"] = is_flooped
			c = GameManager.player2_played_buildings[landscape_num]
	print("Updated " + str(c) + " on landscape" + str(landscape_num) + " for P" + str(player_num) + "(" + str(multiplayer.get_unique_id()) + ")")
	update_card_on_landscape()

@rpc("any_peer", "call_local")
func change_card_on_landscape(player_num: int, landscape_num: int, card: Dictionary):
	print("Changing " + str(card["Card Type"]) + " on landscape" + str(landscape_num) + " for P" + str(player_num) + "(" + str(multiplayer.get_unique_id()) + ")")
	if player_num == 1:
		if card["Card Type"] == "Creature":
			GameManager.player1_played_creatures[landscape_num] = card
		elif card["Card Type"] == "Building":
			GameManager.player1_played_buildings[landscape_num] = card
	elif player_num == 2:
		if card["Card Type"] == "Creature":
			GameManager.player2_played_creatures[landscape_num] = card
		elif card["Card Type"] == "Building":
			GameManager.player2_played_buildings[landscape_num] = card
	update_card_on_landscape()

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_pressed():
		print("Clicked " + str(name))
		if GameManager.player_selected_card.is_empty():
			return
		var player_num: int = player.player_num
		change_card_on_landscape.rpc(player_num, landscape_num, GameManager.player_selected_card)
		GameManager.update_player_selected_card.rpc({})
