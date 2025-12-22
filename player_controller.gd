extends Node2D

@onready var player_stats: Label = $PlayerStats
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
var local_health: int = GameManager.DEFAULT_HP
var local_actions: int = GameManager.DEFAULT_ACTIONS
var local_hand: Array
var is_player_board: bool

func _ready() -> void:
	update_player_stat_display()
	if not is_player_board:
		player.modulate = "7a7a7a"
		draw_card.disabled = true

func _process(delta: float) -> void:
	check_player_stats()

# UPDATES
func update_player_stat_display():
	player_stats.text = "Player " + str(player_num) + "\nHP: " + str(local_health) + "\nACTIONS: " + str(local_actions)

func update_player_hand_display():
	print("Player " + str(player_num) + "'s Hand:\n" + str(local_hand))
	var max_length: float = hand.size.x
	var increment: float = max_length / local_hand.size()
	
	for card in hand.get_children():
		hand.remove_child(card)
	
	var idx: int = 0
	for card in local_hand:
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

func check_player_stats():
	if player_num == 1:
		if local_health != GameManager.player1_health or local_actions != GameManager.player1_actions:
			print("Health: " + str(GameManager.player1_health))
			local_health = GameManager.player1_health
			local_actions = GameManager.player1_actions
			update_player_stat_display()
			print("Updated HP/Actions!")
		if local_hand != GameManager.player1_hand:
			local_hand = GameManager.player1_hand
			update_player_hand_display()
			print("Updated Hand!")
	elif player_num == 2:
		if local_health != GameManager.player2_health or local_actions != GameManager.player2_actions:
			local_health = GameManager.player2_health
			local_actions = GameManager.player2_actions
			update_player_stat_display()
			print("Updated HP/Actions!")
		if local_hand != GameManager.player2_hand:
			local_hand = GameManager.player2_hand
			update_player_hand_display()
			print("Updated Hand!")

# DRAW CARD -> SEND TO OTHER CLIENT
func _on_draw_card_pressed() -> void:
	local_hand.append(GameManager.draw_card())
	update_player_hand_display()
	if player_num == 1:
		GameManager.update_player_hand.rpc_id(GameManager.player2_id, 1, local_hand)
	if player_num == 2:
		GameManager.update_player_hand.rpc_id(GameManager.player1_id, 2, local_hand)
