extends Node2D

@onready var hp_label: Label = $StatPanel/HPLabel
@onready var actions_label: Label = $StatPanel/ActionsLabel
@onready var player_label: Label = $StatPanel/PlayerLabel

@onready var player: Node2D = $"."
@onready var draw_card: Button = $DrawCard
@onready var landscape_1_creature: Area2D = $Landscape1/Card
@onready var landscape_2_creature: Area2D = $Landscape2/Card
@onready var landscape_3_creature: Area2D = $Landscape3/Card
@onready var landscape_4_creature: Area2D = $Landscape4/Card
@onready var landscape_1_building: Area2D = $Building1/Card
@onready var landscape_2_building: Area2D = $Building2/Card
@onready var landscape_3_building: Area2D = $Building3/Card
@onready var landscape_4_building: Area2D = $Building4/Card
@onready var hand: HBoxContainer = $Hand
const CARD = preload("uid://dycs2rc7imye2")

@export var player_num: int
var is_player_board: bool

func _ready() -> void:
	hand.set_meta("player_num", player_num)
	if not is_player_board:
		player.modulate = "7a7a7a"
		draw_card.disabled = true
	net_update_player_stat_display()
	net_update_player_hand_display()

# UPDATES
@rpc("any_peer", "call_local")
func net_update_player_stat_display():
	var health: int
	var actions: int
	if player_num == 1:
		health = GameManager.player1_health
		actions = GameManager.player1_actions
	elif player_num == 2:
		health = GameManager.player2_health
		actions = GameManager.player2_actions
	player_label.text = "PLAYER " + str(player_num)
	hp_label.text = "HP: " + str(health)
	actions_label.text = "ACTIONS: " + str(actions)

@rpc("any_peer", "call_local")
func net_update_player_hand_display():
	#print("Player " + str(player_num) + "'s Hand:\n" + str(local_hand))
	var main_hand: Array
	if player_num == 1:
		main_hand = GameManager.player1_hand
	elif player_num == 2:
		main_hand = GameManager.player2_hand
	if main_hand.is_empty():
		return
	
	var max_length: float = hand.size.x
	var increment: float = max_length / main_hand.size()
	
	for card in hand.get_children():
		hand.remove_child(card)
	
	var idx: int = 0
	for card in main_hand:
		var new_card = CARD.instantiate()
		new_card.is_in_hand = true
		hand.add_child(new_card)
		new_card.position.x = increment * idx
		idx += 1
		
		var card_ability: String = ""
		for key in card:
			if key == "Ability":
				card_ability = card["Ability"]
		if card["Card Type"] == "Spell" or card["Card Type"] == "Building":
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]), 0, 0, false)
		else:
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]),  int(card["Attack"]),  int(card["Defense"]), false)

@rpc("any_peer", "call_local")
func net_update_player_discards_display():
	var discards_hand: Array
	if player_num == 1:
		discards_hand = GameManager.player1_discards
	elif player_num == 2:
		discards_hand = GameManager.player2_discards
	if discards_hand.is_empty():
		return
	
	var max_length: float = hand.size.x
	var increment: float = max_length / discards_hand.size()
	
	for card in hand.get_children():
		hand.remove_child(card)
	
	var idx: int = 0
	for card in discards_hand:
		var new_card = CARD.instantiate()
		new_card.is_in_hand = true
		hand.add_child(new_card)
		new_card.position.x = increment * idx
		idx += 1
		
		var card_ability: String = ""
		var card_broken_temp_fix: bool = true
		for key in card:
			if key == "Ability":
				card_ability = card["Ability"]
			if key == "Name":
				card_broken_temp_fix = false
		if card_broken_temp_fix:
			continue
		if card["Card Type"] == "Spell" or card["Card Type"] == "Building":
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]), 0, 0, false)
		else:
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]),  int(card["Attack"]),  int(card["Defense"]), false)
	print(discards_hand)

@rpc("any_peer", "call_local")
func net_update_player_landscapes():
	landscape_1_creature.remove_card_data()
	landscape_2_creature.remove_card_data()
	landscape_3_creature.remove_card_data()
	landscape_4_creature.remove_card_data()
	landscape_1_building.remove_card_data()
	landscape_2_building.remove_card_data()
	landscape_3_building.remove_card_data()
	landscape_4_building.remove_card_data()
	
	var creatures: Array[Dictionary]
	var buildings: Array[Dictionary]
	if player_num == 1:
		creatures = GameManager.player1_played_creatures
		buildings = GameManager.player1_played_buildings
	if player_num == 2:
		creatures = GameManager.player2_played_creatures
		buildings = GameManager.player2_played_buildings
	
	# CREATURES
	if not creatures[0].is_empty():
		landscape_1_creature.change_card_data(creatures[0]["Landscape"], creatures[0]["Card Type"], creatures[0]["Name"], creatures[0]["Ability"], creatures[0]["Cost"], creatures[0]["Attack"], creatures[0]["Defense"], creatures[0]["Floop Status"])
	if not creatures[1].is_empty():
		landscape_2_creature.change_card_data(creatures[1]["Landscape"], creatures[1]["Card Type"], creatures[1]["Name"], creatures[1]["Ability"], creatures[1]["Cost"], creatures[1]["Attack"], creatures[1]["Defense"], creatures[1]["Floop Status"])
	if not creatures[2].is_empty():
		landscape_3_creature.change_card_data(creatures[2]["Landscape"], creatures[2]["Card Type"], creatures[2]["Name"], creatures[2]["Ability"], creatures[2]["Cost"], creatures[2]["Attack"], creatures[2]["Defense"], creatures[2]["Floop Status"])
	if not creatures[3].is_empty():
		landscape_4_creature.change_card_data(creatures[3]["Landscape"], creatures[3]["Card Type"], creatures[3]["Name"], creatures[3]["Ability"], creatures[3]["Cost"], creatures[3]["Attack"], creatures[3]["Defense"], creatures[3]["Floop Status"])
	
	# BUILDINGS
	if not buildings[0].is_empty():
		landscape_1_building.change_card_data(buildings[0]["Landscape"], buildings[0]["Card Type"], buildings[0]["Name"], buildings[0]["Ability"], buildings[0]["Cost"], buildings[0]["Attack"], buildings[0]["Defense"], buildings[0]["Floop Status"])
	if not buildings[1].is_empty():
		landscape_2_building.change_card_data(buildings[1]["Landscape"], buildings[1]["Card Type"], buildings[1]["Name"], buildings[1]["Ability"], buildings[1]["Cost"], buildings[1]["Attack"], buildings[1]["Defense"], buildings[1]["Floop Status"])
	if not buildings[2].is_empty():
		landscape_3_building.change_card_data(buildings[2]["Landscape"], buildings[2]["Card Type"], buildings[2]["Name"], buildings[2]["Ability"], buildings[2]["Cost"], buildings[2]["Attack"], buildings[2]["Defense"], buildings[2]["Floop Status"])
	if not buildings[3].is_empty():
		landscape_4_building.change_card_data(buildings[3]["Landscape"], buildings[3]["Card Type"], buildings[3]["Name"], buildings[3]["Ability"], buildings[3]["Cost"], buildings[3]["Attack"], buildings[3]["Defense"], buildings[3]["Floop Status"])

# UPDATE BUTTON CHANGES
func _on_hp_down_pressed() -> void:
	GameManager.net_update_player_health.rpc(player_num, -1)

func _on_hp_up_pressed() -> void:
	GameManager.net_update_player_health.rpc(player_num, 1)

func _on_actions_down_pressed() -> void:
	GameManager.net_update_player_actions.rpc(player_num, -1)

func _on_actions_up_pressed() -> void:
	GameManager.net_update_player_actions.rpc(player_num, 1)

func _on_draw_card_pressed() -> void:
	if player_num == 1:
		GameManager.net_add_card_to_player_hand.rpc(1, GameManager.draw_card())
	if player_num == 2:
		GameManager.net_add_card_to_player_hand.rpc(2, GameManager.draw_card())
	net_update_player_hand_display.rpc()
	print("draw")

func _on_discard_card_pressed() -> void:
	var temp_card: Dictionary
	if player_num == 1:
		if GameManager.player1_selected_card.is_empty():
			return
		temp_card = GameManager.player1_selected_card
		GameManager.net_update_player_selected_card.rpc(1, {})
	elif player_num == 2:
		if GameManager.player2_selected_card.is_empty():
			return
		temp_card = GameManager.player2_selected_card
		GameManager.net_update_player_selected_card.rpc(2, {})
	
	print("Sending " + str(temp_card))
	if temp_card["Card Type"] == "Creature":
		match temp_card["Landscape Played"]:
			0:
				GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 0)
			1:
				GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 1)
			2:
				GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 2)
			3:
				GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 3)
			99:
				if player_num == 1:
					GameManager.net_remove_card_from_player_hand.rpc(player_num, temp_card)
					GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				elif player_num == 2:
					GameManager.net_remove_card_from_player_hand.rpc(player_num, temp_card)
					GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
	elif temp_card["Card Type"] == "Building":
		match temp_card["Landscape Played"]:
			0:
				GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				GameManager.net_remove_building_from_landscape_array.rpc(player_num, 0)
			1:
				GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				GameManager.net_remove_building_from_landscape_array.rpc(player_num, 1)
			2:
				GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				GameManager.net_remove_building_from_landscape_array.rpc(player_num, 2)
			3:
				GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				GameManager.net_remove_building_from_landscape_array.rpc(player_num, 3)
			99:
				if player_num == 1:
					GameManager.net_remove_card_from_player_hand.rpc(player_num, temp_card)
					GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
				elif player_num == 2:
					GameManager.net_remove_card_from_player_hand.rpc(player_num, temp_card)
					GameManager.net_add_card_to_player_discards.rpc(player_num, temp_card)
	print("Discarded " + temp_card["Name"] + " from P" + str(player_num))
	net_update_player_hand_display.rpc()
	net_update_player_landscapes.rpc()

func _on_deck_switch_toggled(toggled_on: bool) -> void:
	if toggled_on:
		net_update_player_discards_display()
	else:
		net_update_player_hand_display()

func _on_stat_check_pressed() -> void:
	GameManager.print_all_stats()
