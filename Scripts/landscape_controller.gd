extends Area2D

@onready var card: Area2D = $Card
@onready var player: Node2D = $".."
@onready var landscape_image: Sprite2D = $LandscapeImage
@onready var spell_image: Sprite2D = $SpellImage
@onready var change_landscape: OptionButton = $ChangeLandscape
@onready var frozen_token: Sprite2D = $FrozenToken
@onready var freeze_landscape: Button = $FreezeLandscape

@export var landscape_type: String
@export var landscape_num: int = 0
@export var designated_card_type: String = "Creature"

var frozen_enabled: bool = false
const LANDSCAPE_PATH: String = "res://Assets/Landscapes/"

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
	
	get_viewport().set_physics_object_picking_sort(true)
	get_viewport().set_physics_object_picking_first_only(true)

# Moving this to landscape image update for ease of use
func check_if_frozen_exists():
	var ignore_frozen: bool = true
	for idx in range(4):
		if GameManager.player1_landscapes[idx] == "IcyLands":
			ignore_frozen = false
		elif GameManager.player2_landscapes[idx] == "IcyLands":
			ignore_frozen = false
	if not ignore_frozen:
		freeze_landscape.visible = true
		freeze_landscape.disabled = false
		frozen_enabled = true

func add_card_to_landscape():
	var selected_card: Dictionary
	# PLAYING CARD ON SELF
	if player.player_num == 1 and multiplayer.get_unique_id() == GameManager.player1_id:
		selected_card = GameManager.player1_selected_card
		if selected_card == null:
			return
		var card_played: bool = false
		for key in selected_card:
			if key == "Card Type":
				if selected_card["Card Type"] == "Creature" and designated_card_type == "Creature":
					card_played = place_creature_logic(1, selected_card, false)
				elif selected_card["Card Type"] == "Building" and designated_card_type == "Building":
					card_played = place_building_logic(1, selected_card)
				elif selected_card["Card Type"] == "Spell" and designated_card_type == "Spell":
					card_played = place_spell_logic(1, selected_card)
			elif key == "Landscape Played":
				if selected_card["Landscape Played"] == 99 and card_played:
					GameManager.net_remove_card_from_player_hand.rpc(1, selected_card)
		GameManager.net_update_player_selected_card.rpc(1, {})
	# PLAYING CARD ON OPPONENT - only creature
	elif player.player_num == 1 and multiplayer.get_unique_id() == GameManager.player2_id:
		selected_card = GameManager.player2_selected_card
		if selected_card == null:
			return
		var creature_played: bool
		for key in selected_card:
			if key == "Card Type":
				if selected_card["Card Type"] == "Creature" and designated_card_type == "Creature":
					creature_played = place_creature_logic(1, selected_card, true)
				elif selected_card["Card Type"] == "Building" or selected_card["Card Type"] == "Spell":
					break
			elif key == "Landscape Played":
				if selected_card["Landscape Played"] == 99 and creature_played:
					GameManager.net_remove_card_from_player_hand.rpc(2, selected_card)
		GameManager.net_update_player_selected_card.rpc(2, {})
	# PLAYING CARD ON SELF
	elif player.player_num == 2 and multiplayer.get_unique_id() == GameManager.player2_id:
		selected_card = GameManager.player2_selected_card
		if selected_card == null:
			return
		var card_played: bool = false
		for key in selected_card:
			if key == "Card Type":
				if selected_card["Card Type"] == "Creature" and designated_card_type == "Creature":
					card_played = place_creature_logic(2, selected_card, false)
				elif selected_card["Card Type"] == "Building" and designated_card_type == "Building":
					card_played = place_building_logic(2, selected_card)
				elif selected_card["Card Type"] == "Spell" and designated_card_type == "Spell":
					card_played = place_spell_logic(2, selected_card)
			elif key == "Landscape Played":
				if selected_card["Landscape Played"] == 99 and card_played:
					GameManager.net_remove_card_from_player_hand.rpc(2, selected_card)
		GameManager.net_update_player_selected_card.rpc(2, {})
	# PLAYING CARD ON OPPONENT- only creature
	elif player.player_num == 2 and multiplayer.get_unique_id() == GameManager.player1_id:
		selected_card = GameManager.player1_selected_card
		if selected_card == null:
			return
		var creature_played: bool
		for key in selected_card:
			if key == "Card Type":
				if selected_card["Card Type"] == "Creature" and designated_card_type == "Creature":
					creature_played = place_creature_logic(2, selected_card, true)
				elif selected_card["Card Type"] == "Building" or selected_card["Card Type"] == "Spell":
					break
			elif key == "Landscape Played":
				if selected_card["Landscape Played"] == 99 and creature_played:
					GameManager.net_remove_card_from_player_hand.rpc(1, selected_card)
		GameManager.net_update_player_selected_card.rpc(1, {})

func place_creature_logic(player_num: int, selected_card: Dictionary, playing_on_opponent: bool) -> bool:
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
		return true
	elif player_num == 1 and playing_on_opponent:
		#for num in potential_landscape_nums:
		#	if selected_card["Landscape Played"] == num:
		#		GameManager.net_remove_creature_from_landscape_array.rpc(2, selected_card["Landscape Played"])
		if GameManager.player1_played_creatures[landscape_num].is_empty():
			GameManager.net_add_creature_to_landscape_array.rpc(1, landscape_num, selected_card)
			return true
		else:
			return false
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
		return true
	elif player_num == 2 and playing_on_opponent:
		#for num in potential_landscape_nums:
		#	if selected_card["Landscape Played"] == num:
		#		GameManager.net_remove_creature_from_landscape_array.rpc(1, selected_card["Landscape Played"])
		if GameManager.player2_played_creatures[landscape_num].is_empty():
			GameManager.net_add_creature_to_landscape_array.rpc(2, landscape_num, selected_card)
			return true
		else:
			return false
	return false

func place_building_logic(player_num: int, selected_card: Dictionary) -> bool:
	var potential_landscape_nums: Array[int] = [0,1,2,3]
	if player_num == 1:
		for num in potential_landscape_nums:
			if selected_card["Landscape Played"] == num:
				GameManager.net_remove_building_from_landscape_array.rpc(1, selected_card["Landscape Played"])
		if GameManager.player1_played_buildings[landscape_num].is_empty():
			GameManager.net_add_building_to_landscape_array.rpc(1, landscape_num, selected_card)
			return true
		elif not GameManager.player1_played_buildings[landscape_num].is_empty():
			var placed_card: Dictionary = GameManager.player1_played_buildings[landscape_num]
			GameManager.net_remove_building_from_landscape_array.rpc(1, landscape_num)
			GameManager.net_add_card_to_player_discards.rpc(1, placed_card)
			GameManager.net_add_building_to_landscape_array.rpc(1, landscape_num, selected_card)
			return true
	elif player_num == 2:
		for num in potential_landscape_nums:
			if selected_card["Landscape Played"] == num:
				GameManager.net_remove_building_from_landscape_array.rpc(1, selected_card["Landscape Played"])
		if GameManager.player2_played_buildings[landscape_num].is_empty():
			GameManager.net_add_building_to_landscape_array.rpc(2, landscape_num, selected_card)
			return true
		elif not GameManager.player2_played_buildings[landscape_num].is_empty():
			var placed_card: Dictionary = GameManager.player2_played_buildings[landscape_num]
			GameManager.net_remove_building_from_landscape_array.rpc(2, landscape_num)
			GameManager.net_add_card_to_player_discards.rpc(2, placed_card)
			GameManager.net_add_building_to_landscape_array.rpc(2, landscape_num, selected_card)
			return true
	return false

func place_spell_logic(player_num: int, selected_card: Dictionary) -> bool:
	if player_num == 1:
		if GameManager.player1_current_spell.is_empty():
			GameManager.net_add_spell_to_play.rpc(1, selected_card)
			return true
		elif not GameManager.player1_current_spell.is_empty():
			var placed_card: Dictionary = GameManager.player1_current_spell
			GameManager.net_remove_spell_from_play.rpc(1, selected_card)
			GameManager.net_add_card_to_player_discards.rpc(1, placed_card)
			GameManager.net_add_spell_to_play.rpc(1, selected_card)
			return true
	elif player_num == 2:
		if GameManager.player2_current_spell.is_empty():
			GameManager.net_add_spell_to_play.rpc(2, selected_card)
			return true
		elif not GameManager.player2_current_spell.is_empty():
			var placed_card: Dictionary = GameManager.player2_current_spell
			GameManager.net_remove_spell_from_play.rpc(2, selected_card)
			GameManager.net_add_card_to_player_discards.rpc(2, placed_card)
			GameManager.net_add_spell_to_play.rpc(2, selected_card)
			return true
	return false

func update_landscape_image(_name: String):
	if _name == "Facedown":
		_name = "card_back"
	#var ran_num: int  = randi() % 4 + 1
	#var full_path: String = LANDSCAPE_PATH + "" + _name + "" + str(ran_num) + ".png"
	#print(full_path)
	#var tex: Texture2D = load(full_path)
	var tex: Texture2D = GameManager.db.cards.get(_name)
	if tex == null:
		print("error printing " + _name)
		return
	var img: Image = tex.get_image()
	img.resize(700, 1007, Image.INTERPOLATE_LANCZOS)
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	landscape_image.texture = texture
	check_if_frozen_exists()

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

func toggle_frozen_token(enabled: bool):
	if enabled:
		frozen_token.visible = true
	else:
		frozen_token.visible = false

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

func _on_freeze_landscape_toggled(toggled_on: bool) -> void:
	GameManager.net_change_player_landscape_frozen_status.rpc(player.player_num, landscape_num, toggled_on)
	toggle_frozen_token(toggled_on)
