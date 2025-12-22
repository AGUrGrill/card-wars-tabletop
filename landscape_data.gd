extends Area2D

@onready var card: Area2D = $Card
@onready var player: Node2D = $".."
@onready var image: Sprite2D = $Image

@export var landscape_num: int = 0
@export var designated_card_type: String = "Creature"

var local_card_data: Dictionary

func _ready() -> void:
	if designated_card_type == "Building":
		remove_child(image)	

func _process(delta: float) -> void:
	update_card_on_landscape()

func update_card_on_landscape():
	var data_changed: bool = false
	if player.player_num == 1:
		if designated_card_type == "Creature" and GameManager.player1_played_creatures[landscape_num] != null:
			local_card_data = GameManager.player1_played_creatures.get(landscape_num)
			data_changed = true
		elif designated_card_type == "Building" and GameManager.player1_played_buildings[landscape_num] != null:
			local_card_data = GameManager.player1_played_buildings.get(landscape_num)
			data_changed = true
	elif player.player_num == 2:
		if designated_card_type == "Creature" and GameManager.player2_played_creatures[landscape_num] != null:
			local_card_data = GameManager.player2_played_creatures.get(landscape_num)
			data_changed = true
		elif designated_card_type == "Building" and GameManager.player2_played_buildings[landscape_num] != null:
			local_card_data = GameManager.player2_played_buildings.get(landscape_num)
			data_changed = true
	if data_changed and not local_card_data.is_empty():
		# This is calling on hyper speed but it works so ill kms or something
		print(str(multiplayer.get_unique_id()) + " | P1 " + str(GameManager.player1_played_creatures))
		print(str(multiplayer.get_unique_id()) + " | P2 " + str(GameManager.player2_played_creatures))
		card.change_card_data(local_card_data["Landscape"], local_card_data["Card Type"], local_card_data["Card Name"], local_card_data["Ability"], local_card_data["Cost"], local_card_data["Attack"], local_card_data["Defense"], local_card_data["Floop Status"])

func local_change_card_on_landscape(player_num: int, landscape_num: int, _card: Dictionary):
	if player_num == 1:
		if _card["Card Type"] == "Creature":
			GameManager.player1_played_creatures[landscape_num] = _card
		elif _card["Card Type"] == "Building":
			GameManager.player1_played_buildings[landscape_num] = _card
	elif player_num == 2:
		if _card["Card Type"] == "Creature":
			GameManager.player2_played_creatures[landscape_num] = _card
		elif _card["Card Type"] == "Building":
			GameManager.player2_played_buildings[landscape_num] = _card
	local_card_data = _card
	print(str(multiplayer.get_unique_id()) + " | P1 " + str(GameManager.player1_played_creatures))
	print(str(multiplayer.get_unique_id()) + " | P2 " + str(GameManager.player2_played_creatures))
	card.change_card_data(local_card_data["Landscape"], local_card_data["Card Type"], local_card_data["Card Name"], local_card_data["Ability"], local_card_data["Cost"], local_card_data["Attack"], local_card_data["Defense"], local_card_data["Floop Status"])

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_pressed():
		print("Clicked " + str(name))
		if GameManager.player_selected_card.is_empty():
			return
		var player_num: int = player.player_num
		local_change_card_on_landscape(player_num, landscape_num, GameManager.player_selected_card)
		GameManager.change_card_on_landscape.rpc(player_num, landscape_num, GameManager.player_selected_card)
		GameManager.player_selected_card.clear()
