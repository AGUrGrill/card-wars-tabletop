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
	var player_num: int = get_card_player_num()
	var landscape_num: int = get_card_landscape_num()
	if player_num == 1:
		if card_type == "Creature":
			GameManager.player1_played_creatures[landscape_num]["Attack"] = card_attack
			GameManager.player1_played_creatures[landscape_num]["Defense"] = card_defense
			GameManager.player1_played_creatures[landscape_num]["Floop Status"] = is_flooped
		elif card_type == "Building":
			GameManager.player1_played_buildings[landscape_num]["Floop Status"] = is_flooped
	elif player_num == 2:
		if card_type == "Creature":
			GameManager.player2_played_creatures[landscape_num]["Attack"] = card_attack
			GameManager.player2_played_creatures[landscape_num]["Defense"] = card_defense
			GameManager.player2_played_creatures[landscape_num]["Floop Status"] = is_flooped
		elif card_type == "Building":
			GameManager.player2_played_buildings[landscape_num]["Floop Status"] = is_flooped
	print("Updating " + str(card_type) + " on landscape" + str(landscape_num) + " for P" + str(player_num) + "(" + str(multiplayer.get_unique_id()) + ")")
	landscape.net_change_card_on_landscape.rpc(player_num, landscape_num, get_card_data(false))

@rpc("any_peer", "call_local")
func net_change_card_on_landscape(player_num: int, landscape_num: int, _card: Dictionary):
	print("Changing " + str(_card["Card Type"]) + " on landscape" + str(landscape_num) + " for P" + str(player_num) + "(" + str(multiplayer.get_unique_id()) + ")")
	if _card["Card Type"] == "Creature":
		GameManager.net_add_creature_to_landscape_array.rpc(player_num, landscape_num, _card)
	elif _card["Card Type"] == "Building":
		GameManager.net_add_building_to_landscape_array.rpc(player_num, landscape_num, _card)
	card.change_card_data(_card["Landscape"], _card["Card Type"], _card["Name"], _card["Ability"], _card["Cost"], _card["Attack"], _card["Defense"], _card["Floop Status"])

@rpc("any_peer", "call_local")
func net_remove_card_from_landscape(player_num: int, landscape_num: int):
	card.remove_card_data()

# On Landscape Clicked
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_pressed():
		print("Clicked " + str(name))
		var player_num: int = player.player_num
		if player_num == 1:
			if GameManager.player1_selected_card.is_empty():
				return
			net_change_card_on_landscape.rpc(1, landscape_num, GameManager.player1_selected_card)
			GameManager.net_update_player_selected_card.rpc(1, {})
		elif player_num == 2:
			if GameManager.player2_selected_card.is_empty():
				return
			net_change_card_on_landscape.rpc(2, landscape_num, GameManager.player2_selected_card)
			GameManager.net_update_player_selected_card.rpc(2, {})
