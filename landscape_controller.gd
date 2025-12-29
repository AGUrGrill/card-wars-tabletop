extends Area2D

@onready var card: Area2D = $Card
@onready var player: Node2D = $".."
@onready var board: Node2D = $"..."
@onready var image: Sprite2D = $Image

@export var landscape_num: int = 0
@export var designated_card_type: String = "Creature"

func _ready() -> void:
	if designated_card_type == "Building":
		remove_child(image)

func add_card_to_landscape():
	var player_num: int = player.player_num
	discard_card_if_in_play(player_num)
	if player_num == 1:
		if is_card_empty(GameManager.player1_selected_card):
			return
		if GameManager.player1_selected_card["Card Type"] == "Creature":
			GameManager.net_add_creature_to_landscape_array.rpc(1, landscape_num, GameManager.player1_selected_card)
		elif GameManager.player1_selected_card["Card Type"] == "Building":
			GameManager.net_add_building_to_landscape_array.rpc(1, landscape_num, GameManager.player1_selected_card)
		GameManager.net_remove_card_from_player_hand.rpc(1, GameManager.player1_selected_card)
		GameManager.net_update_player_selected_card.rpc(1, {})
	elif player_num == 2:
		if is_card_empty(GameManager.player2_selected_card):
			return
		if GameManager.player2_selected_card["Card Type"] == "Creature":
			GameManager.net_add_creature_to_landscape_array.rpc(2, landscape_num, GameManager.player2_selected_card)
		elif GameManager.player2_selected_card["Card Type"] == "Building":
			GameManager.net_add_building_to_landscape_array.rpc(2, landscape_num, GameManager.player2_selected_card)
		GameManager.net_remove_card_from_player_hand.rpc(2, GameManager.player2_selected_card)
		GameManager.net_update_player_selected_card.rpc(2, {})
	GameManager.net_tell_clients_to_refresh.rpc()

func is_card_empty(card: Dictionary) -> bool:
	return card.is_empty()

func discard_card_if_in_play(player_num: int):
	var current_card: Dictionary
	if player_num == 1:
		current_card = GameManager.player1_played_creatures[landscape_num]
	elif player_num == 2:
		current_card = GameManager.player2_played_creatures[landscape_num]
	if not current_card.is_empty():
		GameManager.net_add_card_to_player_discards.rpc(player_num, current_card)

# On Landscape Clicked
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_pressed():
		print("Clicked " + str(name))
		add_card_to_landscape()
