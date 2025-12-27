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
	net_update_player_stat_display()
	hand.set_meta("player_num", player_num)
	if not is_player_board:
		player.modulate = "7a7a7a"
		draw_card.disabled = true
	await get_tree().create_timer(1).timeout
	net_update_player_hand_display()

# UPDATES
@rpc("any_peer", "call_local")
func net_update_player_stat_display():
	var health: int
	var actions: int
	if player_num == 1:
		health = GameManager.player1_health
		actions = GameManager.player1_actions
	elif player_num == 1:
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
		for key in card:
			if key == "Ability":
				card_ability = card["Ability"]
		if card["Card Type"] == "Spell" or card["Card Type"] == "Building":
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]), 0, 0, false)
		else:
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]),  int(card["Attack"]),  int(card["Defense"]), false)
	print(discards_hand)

func perform_super_hand_update_across_clients():
	GameManager.net_update_player_hand.rpc(1, GameManager.player1_hand)
	GameManager.net_update_player_hand.rpc(2, GameManager.player2_hand)
	GameManager.net_update_player_discards.rpc(1, GameManager.player1_discards)
	GameManager.net_update_player_discards.rpc(2, GameManager.player2_discards)
	net_update_player_hand_display.rpc()

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
		GameManager.net_add_card_to_player_hand.rpc(1, draw_card)
	if player_num == 2:
		GameManager.net_add_card_to_player_handd.rpc(2, draw_card)
	net_update_player_hand_display.rpc()

func _on_discard_card_pressed() -> void:
	var temp_card: Dictionary
	if player_num == 1:
		if GameManager.player1_selected_card.is_empty():
			return
		temp_card = GameManager.player1_selected_card
	elif player_num == 2:
		if GameManager.player2_selected_card.is_empty():
			return
		temp_card = GameManager.player2_selected_card
	
	print("Sending " + str(temp_card))
	if temp_card["Card Type"] == "Creature":
		match temp_card["Landscape Played"]:
			0:
				landscape_1_creature.send_card_to_discards()
			1:
				landscape_2_creature.send_card_to_discards()
			2:
				landscape_3_creature.send_card_to_discards()
			3:
				landscape_4_creature.send_card_to_discards()
			99:
				if player_num == 1:
					for card in GameManager.player1_hand:
						if card["Name"] == temp_card["Name"]:
							GameManager.player1_hand.remove_at(GameManager.player1_hand.find(card))
							GameManager.player1_discards.append(card)
							print("Removed " + card["Name"])
				elif player_num == 2:
					for card in GameManager.player2_hand:
						if card["Name"] == temp_card["Name"]:
							GameManager.player2_hand.remove_at(GameManager.player2_hand.find(card))
							GameManager.player2_discards.append(card)
							print("Removed " + card["Name"])
	elif temp_card["Card Type"] == "Building":
		match temp_card["Landscape Played"]:
			0:
				landscape_1_building.send_card_to_discards()
			1:
				landscape_2_building.send_card_to_discards()
			2:
				landscape_3_building.send_card_to_discards()
			3:
				landscape_4_building.send_card_to_discards()
			99:
				if player_num == 1:
					for card in GameManager.player1_hand:
						if card["Name"] == temp_card["Name"]:
							GameManager.player1_hand.remove_at(GameManager.player1_hand.find(card))
							GameManager.player1_discards.append(card)
				elif player_num == 2:
					for card in GameManager.player2_hand:
						if card["Name"] == temp_card["Name"]:
							GameManager.player2_hand.remove_at(GameManager.player2_hand.find(card))
							GameManager.player2_discards.append(card)
	print("Discarded " + temp_card["Name"] + " from P" + str(player_num))
	perform_super_hand_update_across_clients()

func _on_deck_switch_toggled(toggled_on: bool) -> void:
	if toggled_on:
		net_update_player_discards_display()
	else:
		net_update_player_hand_display()

func _on_stat_check_pressed() -> void:
	GameManager.print_all_stats()
