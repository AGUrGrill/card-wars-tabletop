extends Area2D

@onready var card: Area2D = $Card
@onready var player: Node2D = $".."
@onready var landscape_image: Sprite2D = $LandscapeImage
@onready var spell_image: Sprite2D = $SpellImage
@onready var change_landscape: OptionButton = $ChangeLandscape

@export var landscape_type: String
@export var landscape_num: int = 0
@export var designated_card_type: String = "Creature"

func _ready() -> void:
	if designated_card_type == "Building":
		remove_child(landscape_image)
		remove_child(spell_image)
		change_landscape.visible = false
		change_landscape.disabled = true
	elif designated_card_type == "Spell":
		remove_child(landscape_image)
		change_landscape.visible = false
		change_landscape.disabled = true
	else:
		remove_child(spell_image)

func add_card_to_landscape():
	var selected_card: Dictionary
	# PLAYING CARD ON SELF
	if player.player_num == 1 and multiplayer.get_unique_id() == GameManager.player1_id:
		selected_card = GameManager.player1_selected_card
		if selected_card == null:
			return
		for key in selected_card:
			if key == "Card Type":
				if selected_card["Card Type"] == "Creature":
					place_creature_logic(1, selected_card, false)
				elif selected_card["Card Type"] == "Building":
					place_building_logic(1, selected_card)
				elif selected_card["Card Type"] == "Spell":
					place_spell_logic(1, selected_card)
			elif key == "Landscape Played":
				if selected_card["Landscape Played"] == 99:
					GameManager.net_remove_card_from_player_hand.rpc(1, selected_card)
		GameManager.net_update_player_selected_card.rpc(1, {})
	# PLAYING CARD ON OPPONENT - only creature
	elif player.player_num == 1 and multiplayer.get_unique_id() == GameManager.player2_id:
		selected_card = GameManager.player2_selected_card
		if selected_card == null:
			return
		for key in selected_card:
			if key == "Card Type":
				if selected_card["Card Type"] == "Creature":
					place_creature_logic(1, selected_card, true)
			elif key == "Landscape Played":
				if selected_card["Landscape Played"] == 99:
					GameManager.net_remove_card_from_player_hand.rpc(2, selected_card)
		GameManager.net_update_player_selected_card.rpc(2, {})
	# PLAYING CARD ON SELF
	elif player.player_num == 2 and multiplayer.get_unique_id() == GameManager.player2_id:
		selected_card = GameManager.player2_selected_card
		if selected_card == null:
			return
		for key in selected_card:
			if key == "Card Type":
				if selected_card["Card Type"] == "Creature":
					place_creature_logic(2, selected_card, false)
				elif selected_card["Card Type"] == "Building":
					place_building_logic(2, selected_card)
				elif selected_card["Card Type"] == "Spell":
					place_spell_logic(2, selected_card)
			elif key == "Landscape Played":
				if selected_card["Landscape Played"] == 99:
					GameManager.net_remove_card_from_player_hand.rpc(2, selected_card)
		GameManager.net_update_player_selected_card.rpc(2, {})
	# PLAYING CARD ON OPPONENT- only creature
	elif player.player_num == 2 and multiplayer.get_unique_id() == GameManager.player1_id:
		selected_card = GameManager.player1_selected_card
		if selected_card == null:
			return
		for key in selected_card:
			if key == "Card Type":
				if selected_card["Card Type"] == "Creature":
					place_creature_logic(2, selected_card, true)
			elif key == "Landscape Played":
				if selected_card["Landscape Played"] == 99:
					GameManager.net_remove_card_from_player_hand.rpc(1, selected_card)
		GameManager.net_update_player_selected_card.rpc(1, {})

func place_creature_logic(player_num: int, selected_card: Dictionary, playing_on_opponent: bool):
	var potential_landscape_nums: Array[int] = [0,1,2,3]
	if player_num == 1 and not playing_on_opponent:
		for num in potential_landscape_nums:
			if selected_card["Landscape Played"] == num:
				GameManager.net_remove_creature_from_landscape_array.rpc(1, selected_card["Landscape Played"])
		if GameManager.player1_played_creatures[landscape_num].is_empty():
			GameManager.net_add_creature_to_landscape_array.rpc(1, landscape_num, selected_card)
		elif not GameManager.player1_played_creatures[landscape_num].is_empty():
			GameManager.net_add_card_to_player_discards.rpc(1, GameManager.player1_played_creatures[landscape_num])
			GameManager.net_remove_creature_from_landscape_array.rpc(1, landscape_num)
			GameManager.net_add_creature_to_landscape_array.rpc(1, landscape_num, selected_card)
	elif player_num == 1 and playing_on_opponent:
		for num in potential_landscape_nums:
			if selected_card["Landscape Played"] == num:
				GameManager.net_remove_creature_from_landscape_array.rpc(2, selected_card["Landscape Played"])
		if GameManager.player1_played_creatures[landscape_num].is_empty():
			GameManager.net_add_creature_to_landscape_array.rpc(1, landscape_num, selected_card)
	elif player_num == 2 and not playing_on_opponent:
		for num in potential_landscape_nums:
			if selected_card["Landscape Played"] == num:
				GameManager.net_remove_creature_from_landscape_array.rpc(2, selected_card["Landscape Played"])
		if GameManager.player2_played_creatures[landscape_num].is_empty():
			GameManager.net_add_creature_to_landscape_array.rpc(2, landscape_num, selected_card)
		elif not GameManager.player2_played_creatures[landscape_num].is_empty():
			GameManager.net_add_card_to_player_discards.rpc(2, GameManager.player2_played_creatures[landscape_num])
			GameManager.net_remove_creature_from_landscape_array.rpc(2, landscape_num)
			GameManager.net_add_creature_to_landscape_array.rpc(2, landscape_num, selected_card)
	elif player_num == 2 and playing_on_opponent:
		for num in potential_landscape_nums:
			if selected_card["Landscape Played"] == num:
				GameManager.net_remove_creature_from_landscape_array.rpc(1, selected_card["Landscape Played"])
		if GameManager.player2_played_creatures[landscape_num].is_empty():
			GameManager.net_add_creature_to_landscape_array.rpc(2, landscape_num, selected_card)

func place_building_logic(player_num: int, selected_card: Dictionary):
	if player_num == 1:
		if GameManager.player1_played_buildings[landscape_num].is_empty():
			GameManager.net_add_building_to_landscape_array.rpc(1, landscape_num, selected_card)
		elif not GameManager.player1_played_buildings[landscape_num].is_empty():
			var placed_card: Dictionary = GameManager.player1_played_buildings[landscape_num]
			GameManager.net_remove_building_from_landscape_array.rpc(1, landscape_num)
			GameManager.net_add_card_to_player_discards.rpc(1, placed_card)
			GameManager.net_add_building_to_landscape_array.rpc(1, landscape_num, selected_card)
	elif player_num == 2:
		if GameManager.player2_played_buildings[landscape_num].is_empty():
			GameManager.net_add_building_to_landscape_array.rpc(2, landscape_num, selected_card)
		elif not GameManager.player2_played_buildings[landscape_num].is_empty():
			var placed_card: Dictionary = GameManager.player2_played_buildings[landscape_num]
			GameManager.net_remove_building_from_landscape_array.rpc(2, landscape_num)
			GameManager.net_add_card_to_player_discards.rpc(2, placed_card)
			GameManager.net_add_building_to_landscape_array.rpc(2, landscape_num, selected_card)

func place_spell_logic(player_num: int, selected_card: Dictionary):
	if player_num == 1:
		if GameManager.player1_current_spell.is_empty():
			GameManager.net_add_spell_to_play.rpc(1, selected_card)
		elif not GameManager.player1_current_spell.is_empty():
			var placed_card: Dictionary = GameManager.player1_current_spell
			GameManager.net_remove_spell_from_play.rpc(1, selected_card)
			GameManager.net_add_card_to_player_discards.rpc(1, placed_card)
			GameManager.net_add_spell_to_play.rpc(1, selected_card)
	elif player_num == 2:
		if GameManager.player2_current_spell.is_empty():
			GameManager.net_add_spell_to_play.rpc(2, selected_card)
		elif not GameManager.player2_current_spell.is_empty():
			var placed_card: Dictionary = GameManager.player2_current_spell
			GameManager.net_remove_spell_from_play.rpc(2, selected_card)
			GameManager.net_add_card_to_player_discards.rpc(2, placed_card)
			GameManager.net_add_spell_to_play.rpc(2, selected_card)

func old_add_card_to_landscape():
	if not player.can_select:
		return
	player.start_selection_buffer()
	var player_num: int = player.player_num
	var selected_card: Dictionary
	if player_num == 1:
		selected_card = GameManager.player1_selected_card
	elif player_num == 2:
		selected_card = GameManager.player2_selected_card
	if selected_card.is_empty() or selected_card == null or selected_card == {  }:
		return
	var is_valid: bool = false
	for key in selected_card:
		if key == "Card Type":
			is_valid = true
	if not is_valid:
		return
	print(selected_card)
	if landscape_num != 69:
		remove_card_if_came_from_landscape(player_num, selected_card)
		discard_card_if_in_play(player_num)
	print(selected_card)
	if selected_card["Card Type"] == "Creature":
		GameManager.net_add_creature_to_landscape_array.rpc(player_num, landscape_num, selected_card)
	elif selected_card["Card Type"] == "Building":
		GameManager.net_add_building_to_landscape_array.rpc(player_num, landscape_num, selected_card)
	elif selected_card["Card Type"] == "Spell":
		discard_spell_if_in_play(player_num)
		GameManager.net_add_spell_to_play.rpc(player_num, selected_card)
	if selected_card["Landscape Played"] == 99:
		GameManager.net_remove_card_from_player_hand.rpc(player_num, selected_card)
	GameManager.net_update_player_selected_card.rpc(player_num, {})
	
func update_landscape_image(_name: String):
	if _name == "Facedown":
		_name = "card_back"
	var tex: Texture2D = GameManager.db.cards.get(_name)
	if tex == null:
		print("error printing " + _name)
		return
	var img: Image = tex.get_image()
	img.resize(700, 1007, Image.INTERPOLATE_LANCZOS)
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	landscape_image.texture = texture

func discard_card_if_in_play(player_num: int):
	var current_card: Dictionary
	if player_num == 1:
		current_card = GameManager.player1_played_creatures[landscape_num]
	elif player_num == 2:
		current_card = GameManager.player2_played_creatures[landscape_num]
	if not current_card.is_empty():
		GameManager.net_add_card_to_player_discards.rpc(player_num, current_card)

func discard_spell_if_in_play(player_num: int):
	var current_card: Dictionary
	if player_num == 1:
		current_card = GameManager.player1_current_spell
	elif player_num == 2:
		current_card = GameManager.player2_current_spell
	if not current_card.is_empty():
		GameManager.net_add_card_to_player_discards.rpc(player_num, current_card)

func remove_card_if_came_from_landscape(player_num: int, selected_card: Dictionary):
	if selected_card["Landscape Played"] == 0 or selected_card["Landscape Played"] == 1 or selected_card["Landscape Played"] == 2 or selected_card["Landscape Played"] == 3:
		if selected_card["Card Type"] == "Creature":
			GameManager.net_remove_creature_from_landscape_array.rpc(player_num, selected_card["Landscape Played"])
		elif selected_card["Card Type"] == "Building":
			GameManager.net_remove_building_from_landscape_array.rpc(player_num, selected_card["Landscape Played"])

# On Landscape Clicked
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_pressed():
		print("Clicked " + str(name))
		if player.can_select:
			player.start_selection_buffer()
			add_card_to_landscape()
			player.update_selected_card_image("fart")
			player.audio.confirm_sfx.play()

func _on_change_landscape_item_selected(index: int) -> void:
	GameManager.net_change_player_landscape.rpc(player.player_num, landscape_num, change_landscape.get_item_text(index))
