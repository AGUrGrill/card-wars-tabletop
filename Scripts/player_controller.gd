extends Node2D

#region Variables
const CARD = preload("uid://dycs2rc7imye2")

# MAIN NODE
@onready var player: Node2D = $"."
# MAIN BUTTONS
@onready var main_switch: Button = $MainButtons/MainSwitch
@onready var main_button: Button = $MainButtons/MainButton
@onready var sub_button: Button = $MainButtons/SubButton
@onready var end_turn: Button = $MainButtons/EndTurn
# CARD AREAS
@onready var landscape_1_creature: Area2D = $Landscape1/Card
@onready var landscape_2_creature: Area2D = $Landscape2/Card
@onready var landscape_3_creature: Area2D = $Landscape3/Card
@onready var landscape_4_creature: Area2D = $Landscape4/Card
@onready var landscape_1_building: Area2D = $Building1/Card
@onready var landscape_2_building: Area2D = $Building2/Card
@onready var landscape_3_building: Area2D = $Building3/Card
@onready var landscape_4_building: Area2D = $Building4/Card
@onready var spell_area_card: Area2D = $SpellArea/Card
# STATS
@onready var hp_label: Label = $StatPanel/HPLabel
@onready var actions_label: Label = $StatPanel/ActionsLabel
@onready var player_label: Label = $StatPanel/PlayerLabel
@onready var opponent_hp_label: Label = $StatPanel/OpponentHPLabel
@onready var actions_down: Button = $StatPanel/ActionsLabel/ActionsDown
@onready var actions_up: Button = $StatPanel/ActionsLabel/ActionsUp
@onready var hp_up: Button = $StatPanel/HPLabel/HPUp
@onready var hp_down: Button = $StatPanel/HPLabel/HPDown
@onready var stat_panel: Panel = $StatPanel
# HAND
@onready var hand: HBoxContainer = $Hand
# IMAGES
@onready var hero_image: Sprite2D = $HeroImage
@onready var selected_card: Sprite2D = $SelectedCard
# TIMERS
@onready var input_timer: Timer = $Timers/InputTimer
@onready var input_timer_label: Label = $Timers/InputTimerLabel
@onready var card_selection_timer: Timer = $CardSelectionTimer
# LOG
@onready var log: Node = $Log
# ANIMATION
@onready var animation_player: AnimationPlayer = $MainPlayer
@onready var hand_player: AnimationPlayer = $HandPlayer
# AUDIO
@onready var audio: Node = $Audio
# ADDITIONAL OPTIONS
@onready var additional_options_panel: Panel = $AdditionalOptions/AdditionalOptionsPanel
# deck
@onready var deck_options: Node2D = $AdditionalOptions/AdditionalOptionsPanel/DeckOptions
@onready var scry_num: LineEdit = $AdditionalOptions/AdditionalOptionsPanel/DeckOptions/ScryNum
# additional
@onready var additional_options: Node2D = $AdditionalOptions/AdditionalOptionsPanel/AdditionalOptions
@onready var deck_options_button: Button = $AdditionalOptions/DeckOptionsButton
@onready var additional_options_button: Button = $AdditionalOptions/AdditionalOptionsButton
@onready var frozen_token: Sprite2D = $FrozenToken

# VARIABLES
@export var player_num: int
var is_player_board: bool
var disabled: bool = true
var can_select: bool = true
var prev_hp: int = GameManager.DEFAULT_HP
var modulated: bool = false
var in_deck_mode: bool
var in_discard_mode: bool
#endregion

func _ready() -> void:
	hand.set_meta("player_num", player_num)
	if player_num == 1 and not multiplayer.get_unique_id() == GameManager.player1_id:
		audio.audio_type = "Disabled"
		disable_inputs(true, true)
		hide_buttons(true)
		hero_image.rotation_degrees = 180
		selected_card.rotation_degrees = 180
	elif player_num == 2 and not multiplayer.get_unique_id() == GameManager.player2_id:
		audio.audio_type = "Disabled"
		disable_inputs(true, true)
		hide_buttons(true)
		hero_image.rotation_degrees = 180
		selected_card.rotation_degrees = 180
	else:
		disable_inputs(false, true)
	
	disabled = true
	log.make_log_message("Game Start!")

# Moving this to hero image update for ease of use
func check_if_frozen_exists():
	var ignore_frozen: bool = true
	for idx in range(4):
		print(idx)
		print(GameManager.player1_landscapes[idx])
		if GameManager.player1_landscapes[idx] == "IcyLands":
			ignore_frozen = false
		elif GameManager.player2_landscapes[idx] == "IcyLands":
			ignore_frozen = false
	if not ignore_frozen:
		frozen_token.visible = true

func _process(delta: float) -> void:
	determine_display_visibility()
	if GameManager.game_ended:
		get_tree().change_scene_to_file("res://Scenes/end_screen.tscn")
	if not can_select:
		input_timer_label.text = str(snappedf(input_timer.time_left, 0.01))

func determine_display_visibility():
	if player_num == 1 and multiplayer.get_unique_id() == GameManager.player1_id:
		if GameManager.p1_turn and disabled:
			disable_inputs(false, false)
			disabled = false
		elif not GameManager.p1_turn and not disabled:
			disable_inputs(false, true)
			disabled = true
	elif player_num == 1 and multiplayer.get_unique_id() != GameManager.player1_id:
		if GameManager.p1_turn and disabled:
			disable_inputs(false, false)
			disabled = false
		elif not GameManager.p1_turn and not disabled:
			disable_inputs(false, true)
			disabled = true
	if player_num == 2 and multiplayer.get_unique_id() == GameManager.player2_id:
		if GameManager.p2_turn and disabled:
			disable_inputs(false, false)
			disabled = false
		elif not GameManager.p2_turn and not disabled:
			disable_inputs(false, true)
			disabled = true
	elif player_num == 2 and multiplayer.get_unique_id() != GameManager.player2_id:
		if GameManager.p2_turn and disabled:
			disable_inputs(false, false)
			disabled = false
		elif not GameManager.p2_turn and not disabled:
			disable_inputs(false, true)
			disabled = true

func hide_buttons(should_hide: bool):
	stat_panel.visible = false
	main_button.visible = false
	sub_button.visible = false
	main_switch.visible = false
	end_turn.visible = false
	input_timer_label.visible = false
	log.visible = false
	audio.disabled = true
	additional_options_panel.visible = false
	deck_options_button.visible = false
	additional_options_button.visible = false

func disable_inputs(should_disable: bool, should_modulate: bool):
	if should_disable:
		actions_up.disabled = true
		actions_down.disabled = true
		hp_up.disabled = true
		hp_down.disabled = true
		main_button.disabled = true
		sub_button.disabled = true
		end_turn.disabled = true
		main_switch.disabled = true
	else:
		actions_up.disabled = false
		actions_down.disabled = false
		hp_up.disabled = false
		hp_down.disabled = false
		main_button.disabled = false
		sub_button.disabled = false
		end_turn.disabled = false
		main_switch.disabled = false
	if should_modulate:
		player.modulate = "7a7a7a"
		modulated = true
	else:
		player.modulate = "ffffff"
		modulated = false

# IMAGE STUFF
func update_hero_image():
	var _name: String
	if player_num == 1:
		_name = GameManager.player1_hero
	elif player_num == 2:
		_name = GameManager.player2_hero
	
	var tex = GameManager.db.cards.get(_name)
	hero_image.texture = tex
	check_if_frozen_exists()

func update_selected_card_image(_name: String):
	print("changing img to " + _name)
	if _name == "fart":
		selected_card.texture = null
		return
	var tex = GameManager.db.cards.get(_name)
	if tex == null:
		selected_card.texture = null
		return
	var img: Image = tex.get_image()
	img.resize(300, 420, Image.INTERPOLATE_LANCZOS)
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	selected_card.texture = texture
	card_selection_timer.start()

# BUTTON LOGIC
func discard_card_logic():
	var selected_card: Dictionary
	var is_opponents_card: bool = false
	if player_num == 1 and GameManager.player1_id == multiplayer.get_unique_id():
		selected_card = GameManager.player1_selected_card
	elif player_num == 1 and GameManager.player1_id != multiplayer.get_unique_id():
		selected_card = GameManager.player2_selected_card
		is_opponents_card = true
	elif player_num == 2 and GameManager.player2_id == multiplayer.get_unique_id():
		selected_card = GameManager.player2_selected_card
	elif player_num == 2 and GameManager.player2_id != multiplayer.get_unique_id():
		selected_card = GameManager.player1_selected_card
		is_opponents_card = true
	if selected_card.is_empty():
		return
	GameManager.net_update_player_selected_card.rpc(player_num, {})
	
	if selected_card["Card Type"] == "Creature":
		match selected_card["Landscape Played"]:
			0:
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
				if is_opponents_card:
					GameManager.net_remove_creature_from_landscape_array.rpc(player_num, abs(0-3))
				else:
					GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 0)
			1:
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
				if is_opponents_card:
					GameManager.net_remove_creature_from_landscape_array.rpc(player_num, abs(1-3))
				else:
					GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 1)
			2:
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
				if is_opponents_card:
					GameManager.net_remove_creature_from_landscape_array.rpc(player_num, abs(2-3))
				else:
					GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 2)
			3:
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
				if is_opponents_card:
					GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 3)
				else:
					GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 3)
			99:
				if is_opponents_card:
					if player_num == 1:
						GameManager.net_remove_card_from_player_hand.rpc(2, selected_card)
					else:
						GameManager.net_remove_card_from_player_hand.rpc(1, selected_card)
				else:
					GameManager.net_remove_card_from_player_hand.rpc(player_num, selected_card)
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
	elif selected_card["Card Type"] == "Building":
		match selected_card["Landscape Played"]:
			0:
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
				if is_opponents_card:
					GameManager.net_remove_building_from_landscape_array.rpc(player_num, abs(0-3))
				else:
					GameManager.net_remove_building_from_landscape_array.rpc(player_num, 0)
			1:
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
				if is_opponents_card:
					GameManager.net_remove_building_from_landscape_array.rpc(player_num, abs(1-3))
				else:
					GameManager.net_remove_building_from_landscape_array.rpc(player_num, 1)
			2:
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
				if is_opponents_card:
					GameManager.net_remove_building_from_landscape_array.rpc(player_num, abs(2-3))
				else:
					GameManager.net_remove_building_from_landscape_array.rpc(player_num, 2)
			3:
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
				if is_opponents_card:
					GameManager.net_remove_building_from_landscape_array.rpc(player_num, abs(3-3))
				else:
					GameManager.net_remove_building_from_landscape_array.rpc(player_num, 3)
			99:
				if is_opponents_card:
					if player_num == 1:
						GameManager.net_remove_card_from_player_hand.rpc(2, selected_card)
					else:
						GameManager.net_remove_card_from_player_hand.rpc(1, selected_card)
				else:
					GameManager.net_remove_card_from_player_hand.rpc(player_num, selected_card)
				GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
	elif selected_card["Card Type"] == "Spell":
		if selected_card["Landscape Played"] == 99:
			if is_opponents_card:
				if player_num == 1:
					GameManager.net_remove_card_from_player_hand.rpc(2, selected_card)
				else:
					GameManager.net_remove_card_from_player_hand.rpc(1, selected_card)
			else:
				GameManager.net_remove_card_from_player_hand.rpc(player_num, selected_card)
		else:
			GameManager.net_remove_spell_from_play.rpc(player_num)
		GameManager.net_add_card_to_player_discards.rpc(player_num, selected_card)
	log.make_log_message("Discarded " + selected_card["Name"] + ".")

func draw_card_logic():
	if player_num == 1:
		GameManager.net_add_card_to_player_hand.rpc(1, GameManager.draw_card(1))
	if player_num == 2:
		GameManager.net_add_card_to_player_hand.rpc(2, GameManager.draw_card(2))
	log.make_log_message("Card drawn.")

func draw_bottom_card_logic():
	if player_num == 1:
		GameManager.net_add_card_to_player_hand.rpc(1, GameManager.draw_bottom_card(1))
	if player_num == 2:
		GameManager.net_add_card_to_player_hand.rpc(2, GameManager.draw_bottom_card(2))
	log.make_log_message("Card drawn.")

func grab_card_from_play_logic():
	var potential_landscape_nums: Array[int] = [0,1,2,3,69]
	var selected_card: Dictionary
	if player_num == 1:
		selected_card = GameManager.player1_selected_card
	elif player_num == 2:
		selected_card = GameManager.player2_selected_card
	if selected_card.is_empty():
		return
	
	var valid_landscape_type: bool = false
	for num in potential_landscape_nums:
		if selected_card["Landscape Played"] == num:
			valid_landscape_type = true
	
	if valid_landscape_type:
		GameManager.net_add_card_to_player_hand.rpc(player_num, selected_card)
		if selected_card["Card Type"] == "Creature":
			GameManager.net_remove_creature_from_landscape_array.rpc(player_num, selected_card["Landscape Played"])
		elif selected_card["Card Type"] == "Building":
			GameManager.net_remove_building_from_landscape_array.rpc(player_num, selected_card["Landscape Played"])
		elif selected_card["Card Type"] == "Spell":
			GameManager.net_remove_spell_from_play.rpc(player_num)
		GameManager.net_update_player_selected_card.rpc(player_num, {})
		player.update_selected_card_image("fart")
		log.make_log_message("Grabbed " + selected_card["Name"] + ".")
	else:
		player.update_selected_card_image("fart")
		log.make_log_message("Invalid selection.")
		return

func grab_card_from_discards_logic():
	var selected_card: Dictionary
	if player_num == 1:
		selected_card = GameManager.player1_selected_card
	elif player_num == 2:
		selected_card = GameManager.player2_selected_card
	if selected_card.is_empty():
		return
	GameManager.net_add_card_to_player_hand.rpc(player_num, selected_card)
	GameManager.net_remove_card_from_player_discards.rpc(player_num, selected_card)
	GameManager.net_update_player_selected_card.rpc(player_num, {})
	player.update_selected_card_image("fart")
	log.make_log_message("Grabbed " + selected_card["Name"] + ".")
	update_player_hand_display()
	log.make_log_message("Switched to hand display.")

func grab_card_from_deck_logic():
	var selected_card: Dictionary
	if player_num == 1:
		selected_card = GameManager.player1_selected_card
	elif player_num == 2:
		selected_card = GameManager.player2_selected_card
	if selected_card.is_empty():
		return
	GameManager.net_add_card_to_player_hand.rpc(player_num, selected_card)
	GameManager.net_remove_card_from_player_deck.rpc(player_num, selected_card)
	GameManager.net_update_player_selected_card.rpc(player_num, {})
	player.update_selected_card_image("fart")
	log.make_log_message("Grabbed " + selected_card["Name"] + ".")
	update_player_hand_display()
	log.make_log_message("Switched to hand display.")

func remove_card_logic():
	var selected_card: Dictionary
	if player_num == 1:
		selected_card = GameManager.player1_selected_card
	elif player_num == 2:
		selected_card = GameManager.player2_selected_card
	if selected_card.is_empty():
		return
	GameManager.net_update_player_selected_card.rpc(player_num, {})
	
	if selected_card["Card Type"] == "Creature":
		match selected_card["Landscape Played"]:
			0:
				GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 0)
			1:
				GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 1)
			2:
				GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 2)
			3:
				GameManager.net_remove_creature_from_landscape_array.rpc(player_num, 3)
			99:
				GameManager.net_remove_card_from_player_hand.rpc(player_num, selected_card)
			-1:
				GameManager.net_remove_card_from_player_discards.rpc(player_num, selected_card)
	elif selected_card["Card Type"] == "Building":
		match selected_card["Landscape Played"]:
			0:
				GameManager.net_remove_building_from_landscape_array.rpc(player_num, 0)
			1:
				GameManager.net_remove_building_from_landscape_array.rpc(player_num, 1)
			2:
				GameManager.net_remove_building_from_landscape_array.rpc(player_num, 2)
			3:
				GameManager.net_remove_building_from_landscape_array.rpc(player_num, 3)
			99:
				GameManager.net_remove_card_from_player_hand.rpc(player_num, selected_card)
			-1:
				GameManager.net_remove_card_from_player_discards.rpc(player_num, selected_card)
	elif selected_card["Card Type"] == "Spell":
		if selected_card["Landscape Played"] == 99:
			GameManager.net_remove_card_from_player_hand.rpc(player_num, selected_card)
		elif selected_card["Landscape Played"] == -1:
			GameManager.net_remove_card_from_player_discards.rpc(player_num, selected_card)
		else:
			GameManager.net_remove_spell_from_play.rpc(player_num)
	#print("Removed " + selected_card["Name"] + " from P" + str(player_num))
	player.update_selected_card_image("fart")
	log.make_log_message("Removed " + selected_card["Name"] + ".")

func give_opp_card_logic():
	if player_num == 1:
		GameManager.net_add_card_to_player_hand.rpc(2, GameManager.player1_selected_card)
		log.make_log_message("Gave opponent " + GameManager.player1_selected_card["Name"] + ".")
	elif player_num == 2:
		GameManager.net_add_card_to_player_hand.rpc(1, GameManager.player2_selected_card)
		log.make_log_message("Gave opponent " + GameManager.player2_selected_card["Name"] + ".")
	remove_card_logic()

func shuffle_deck_logic():
	GameManager.shuffle_deck(player_num)
	log.make_log_message("Deck shuffled!")

func add_card_to_top_deck_logic():
	if player_num == 1:
		var can_remove: bool = false
		for card in GameManager.player1_hand:
			if card["Name"] == GameManager.player1_selected_card["Name"]:
				can_remove = true
		if can_remove:
			GameManager.add_card_to_top_of_deck.rpc(1, GameManager.player1_selected_card)
			GameManager.net_remove_card_from_player_hand.rpc(1, GameManager.player1_selected_card)
		else:
			log.make_log_message("Please return card to hand before adding to top of deck.")
	elif player_num == 2:
		var can_remove: bool = false
		for card in GameManager.player2_hand:
			if card["Name"] == GameManager.player2_selected_card["Name"]:
				can_remove = true
		if can_remove:
			GameManager.add_card_to_top_of_deck.rpc(2, GameManager.player2_selected_card)
			GameManager.net_remove_card_from_player_hand.rpc(2, GameManager.player2_selected_card)
		else:
			log.make_log_message("Please return card to hand before adding to top of deck.")

func add_card_to_bottom_deck_logic():
	if player_num == 1:
		GameManager.add_card_to_bottom_of_deck.rpc(1, GameManager.player1_selected_card)
		GameManager.net_remove_card_from_player_hand.rpc(1, GameManager.player1_selected_card)
	elif player_num == 2:
		GameManager.add_card_to_bottom_of_deck.rpc(2, GameManager.player2_selected_card)
		GameManager.net_remove_card_from_player_hand.rpc(2, GameManager.player2_selected_card)

# LAYOUTS
func change_to_discard_layout():
	in_deck_mode = false
	in_discard_mode = true
	main_switch.text = "VIEW HAND"
	main_button.text = "GRAB CARD"
	sub_button.disabled = true
	sub_button.visible = false
	if player_num == 1 and multiplayer.get_unique_id() == GameManager.player1_id:
		print(GameManager.player1_deck)
	elif player_num == 2 and multiplayer.get_unique_id() == GameManager.player2_id:
		print(GameManager.player2_deck)

func change_to_draw_layout():
	in_deck_mode = false
	in_discard_mode = false
	main_switch.text = "VIEW DISCARDS"
	main_button.text = "DRAW CARD"
	sub_button.text = "DISCARD CARD"
	# To make sure it does not enable for the other player sometimes (TRY TO FIX ORIGINAL ISSUE OF DISCARD CARD BUTTON APPEARING) this is a bandaid
	if player_num == 1 and multiplayer.get_unique_id() == GameManager.player1_id:
		sub_button.disabled = false
		sub_button.visible = true
	elif player_num == 2 and multiplayer.get_unique_id() == GameManager.player2_id:
		sub_button.disabled = false
		sub_button.visible = true
	
func change_to_deck_layout():
	in_deck_mode = true
	in_discard_mode = false
	main_switch.text = "VIEW HAND"
	main_button.text = "GRAB CARD"
	sub_button.disabled = true
	sub_button.visible = false
	if player_num == 1 and multiplayer.get_unique_id() == GameManager.player1_id:
		print(GameManager.player1_deck)
	elif player_num == 2 and multiplayer.get_unique_id() == GameManager.player2_id:
		print(GameManager.player2_deck)

func enable_deck_options():
	additional_options.visible = false
	deck_options.visible = true

func enable_additional_options():
	deck_options.visible = false
	additional_options.visible = true

# OTHER
func get_real_player_num():
	if multiplayer.get_unique_id() == GameManager.player1_id:
		return 1
	elif multiplayer.get_unique_id() == GameManager.player2_id:
		return 2

func start_selection_buffer():
	can_select = false
	input_timer.start()

# UPDATES
func update_player_stat_display():
	var health: int
	var opponent_health: int
	var actions: int
	if player_num == 1:
		health = GameManager.player1_health
		actions = GameManager.player1_actions
		opponent_health = GameManager.player2_health
	elif player_num == 2:
		health = GameManager.player2_health
		actions = GameManager.player2_actions
		opponent_health = GameManager.player1_health
	if prev_hp < health:
		play_heal()
	elif prev_hp > health:
		play_hurt()
	prev_hp = health
	#player_label.text = "PLAYER " + str(player_num)
	hp_label.text = "HP: " + str(health)
	actions_label.text = "ACTIONS: " + str(actions)
	opponent_hp_label.text = "HP: " + str(opponent_health)

func update_player_hand_display():
	change_to_draw_layout()
	for card in hand.get_children():
		hand.remove_child(card)
	
	var main_hand: Array
	if player_num == 1:
		main_hand = GameManager.player1_hand
	elif player_num == 2:
		main_hand = GameManager.player2_hand
	if main_hand.is_empty():
		return
	print("Player " + str(player_num) + "'s Hand:\n" + str(multiplayer.get_unique_id()))
	
	var idx: int = 0
	for card in main_hand:
		var new_card = CARD.instantiate()
		new_card.is_in_hand = true
		hand.add_child(new_card)
		var card_length: float = new_card.collision_shape_2d.shape.size.x
		var card_height: float = new_card.collision_shape_2d.shape.size.y
		var max_length: float = hand.size.x
		var increment: float = (max_length - card_length) / main_hand.size()
		new_card.position.x = (increment * idx) + (card_length/2)
		new_card.position.y += card_height/2
		new_card.z_index = idx
		idx += 1
		
		var card_ability: String = ""
		for key in card:
			if key == "Ability":
				card_ability = card["Ability"]
		if card["Card Type"] == "Spell" or card["Card Type"] == "Building":
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]), 0, 0, false)
		else:
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]),  int(card["Attack"]),  int(card["Defense"]), false)
		if not is_player_board:
			new_card.hide_image()

func update_player_discards_display():
	change_to_discard_layout()
	for card in hand.get_children():
		hand.remove_child(card)
	
	var discards_hand: Array
	if player_num == 1:
		discards_hand = GameManager.player1_discards
	elif player_num == 2:
		discards_hand = GameManager.player2_discards
	if discards_hand.is_empty():
		return
	
	var max_length: float = hand.size.x
	var increment: float = max_length / discards_hand.size()
	
	var idx: int = 0
	for card in discards_hand:
		var new_card = CARD.instantiate()
		new_card.is_in_hand = true
		hand.add_child(new_card)
		new_card.position.x = increment * idx
		new_card.z_index = idx
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

func update_player_deck_display():
	change_to_deck_layout()
	for card in hand.get_children():
		hand.remove_child(card)
	
	var main_hand: Array
	if player_num == 1:
		main_hand = GameManager.player1_deck
	elif player_num == 2:
		main_hand = GameManager.player2_deck
	if main_hand.is_empty():
		return
	print("Player " + str(player_num) + "'s Deck:\n" + str(multiplayer.get_unique_id()))
	
	var max_length: float = hand.size.x
	var increment: float = max_length / main_hand.size()
	var idx: int = 0
	
	for card in main_hand:
		var new_card = CARD.instantiate()
		new_card.is_in_hand = true
		hand.add_child(new_card)
		new_card.position.x = increment * idx
		new_card.z_index = idx
		idx += 1
		
		var card_ability: String = ""
		for key in card:
			if key == "Ability":
				card_ability = card["Ability"]
		if card["Card Type"] == "Spell" or card["Card Type"] == "Building":
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]), 0, 0, false)
		else:
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]),  int(card["Attack"]),  int(card["Defense"]), false)
		if not is_player_board:
			new_card.hide_image()
	log.make_log_message("Switched to deck display.")

func update_scry_player_deck_display(amount: int):
	change_to_deck_layout()
	for card in hand.get_children():
		hand.remove_child(card)
	
	var main_hand: Array
	if player_num == 1:
		main_hand = GameManager.player1_deck
	elif player_num == 2:
		main_hand = GameManager.player2_deck
	if main_hand.is_empty():
		return
	print("Player " + str(player_num) + "'s Deck:\n" + str(multiplayer.get_unique_id()))
	
	var max_length: float = hand.size.x
	var increment: float = max_length / main_hand.size()
	var idx: int = -1
	
	for card in main_hand:
		idx += 1
		if idx < main_hand.size() - amount:
			continue
		var new_card = CARD.instantiate()
		new_card.is_in_hand = true
		hand.add_child(new_card)
		new_card.position.x = increment * idx
		
		var card_ability: String = ""
		for key in card:
			if key == "Ability":
				card_ability = card["Ability"]
		if card["Card Type"] == "Spell" or card["Card Type"] == "Building":
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]), 0, 0, false)
		else:
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]),  int(card["Attack"]),  int(card["Defense"]), false)
		if not is_player_board:
			new_card.hide_image()
	log.make_log_message("Switched to deck display.")

@rpc("any_peer", "call_local")
func update_player_landscape(landscape_num: int):
	if landscape_num == 0:
		landscape_1_creature.remove_card_data()
		landscape_1_building.remove_card_data()
	elif landscape_num == 1:
		landscape_2_creature.remove_card_data()
		landscape_2_building.remove_card_data()
	elif landscape_num == 2:
		landscape_3_creature.remove_card_data()
		landscape_3_building.remove_card_data()
	elif landscape_num == 3:
		landscape_4_creature.remove_card_data()
		landscape_4_building.remove_card_data()
	elif landscape_num == 69:
		spell_area_card.remove_card_data()
	
	var creatures: Array[Dictionary]
	var buildings: Array[Dictionary]
	var spell: Dictionary
	var landscapes: Array[String]
	var landscape_frozen_status: Array[bool]
	
	if player_num == 1:
		creatures = GameManager.player1_played_creatures
		buildings = GameManager.player1_played_buildings
		spell = GameManager.player1_current_spell
		landscapes = GameManager.player1_landscapes
		landscape_frozen_status = GameManager.player1_landscape_frozen_status
	elif player_num == 2:
		creatures = GameManager.player2_played_creatures
		buildings = GameManager.player2_played_buildings
		spell = GameManager.player2_current_spell
		landscapes = GameManager.player2_landscapes
		landscape_frozen_status = GameManager.player2_landscape_frozen_status
	
	# LANDSCAPES
	if not landscapes[0].is_empty() and landscape_num == 0:
		$Landscape1.update_landscape_image(landscapes[0])
	if not landscapes[1].is_empty() and landscape_num == 1:
		$Landscape2.update_landscape_image(landscapes[1])
	if not landscapes[2].is_empty() and landscape_num == 2:
		$Landscape3.update_landscape_image(landscapes[2])
	if not landscapes[3].is_empty() and landscape_num == 3:
		$Landscape4.update_landscape_image(landscapes[3])
	
	# LANDSCAPE FROZEN STATUS
	$Landscape1.toggle_frozen_token(landscape_frozen_status[0])
	$Landscape2.toggle_frozen_token(landscape_frozen_status[1])
	$Landscape3.toggle_frozen_token(landscape_frozen_status[2])
	$Landscape4.toggle_frozen_token(landscape_frozen_status[3])
	
	# CREATURES
	if not creatures[0].is_empty() and landscape_num == 0:
		landscape_1_creature.is_in_hand = false
		landscape_1_creature.change_card_data(creatures[0]["Landscape"], creatures[0]["Card Type"], creatures[0]["Name"], creatures[0]["Ability"], creatures[0]["Cost"], creatures[0]["Attack"], creatures[0]["Defense"], creatures[0]["Floop Status"])
	if not creatures[1].is_empty() and landscape_num == 1:
		landscape_2_creature.is_in_hand = false
		landscape_2_creature.change_card_data(creatures[1]["Landscape"], creatures[1]["Card Type"], creatures[1]["Name"], creatures[1]["Ability"], creatures[1]["Cost"], creatures[1]["Attack"], creatures[1]["Defense"], creatures[1]["Floop Status"])
	if not creatures[2].is_empty() and landscape_num == 2:
		landscape_3_creature.is_in_hand = false
		landscape_3_creature.change_card_data(creatures[2]["Landscape"], creatures[2]["Card Type"], creatures[2]["Name"], creatures[2]["Ability"], creatures[2]["Cost"], creatures[2]["Attack"], creatures[2]["Defense"], creatures[2]["Floop Status"])
	if not creatures[3].is_empty() and landscape_num == 3:
		landscape_4_creature.is_in_hand = false
		landscape_4_creature.change_card_data(creatures[3]["Landscape"], creatures[3]["Card Type"], creatures[3]["Name"], creatures[3]["Ability"], creatures[3]["Cost"], creatures[3]["Attack"], creatures[3]["Defense"], creatures[3]["Floop Status"])
	# BUILDINGS
	if not buildings[0].is_empty() and landscape_num == 0:
		landscape_1_building.is_in_hand = false
		landscape_1_building.change_card_data(buildings[0]["Landscape"], buildings[0]["Card Type"], buildings[0]["Name"], buildings[0]["Ability"], buildings[0]["Cost"], buildings[0]["Attack"], buildings[0]["Defense"], buildings[0]["Floop Status"])
	if not buildings[1].is_empty() and landscape_num == 1:
		landscape_2_building.is_in_hand = false
		landscape_2_building.change_card_data(buildings[1]["Landscape"], buildings[1]["Card Type"], buildings[1]["Name"], buildings[1]["Ability"], buildings[1]["Cost"], buildings[1]["Attack"], buildings[1]["Defense"], buildings[1]["Floop Status"])
	if not buildings[2].is_empty() and landscape_num == 2:
		landscape_3_building.is_in_hand = false
		landscape_3_building.change_card_data(buildings[2]["Landscape"], buildings[2]["Card Type"], buildings[2]["Name"], buildings[2]["Ability"], buildings[2]["Cost"], buildings[2]["Attack"], buildings[2]["Defense"], buildings[2]["Floop Status"])
	if not buildings[3].is_empty() and landscape_num == 3:
		landscape_4_building.is_in_hand = false
		landscape_4_building.change_card_data(buildings[3]["Landscape"], buildings[3]["Card Type"], buildings[3]["Name"], buildings[3]["Ability"], buildings[3]["Cost"], buildings[3]["Attack"], buildings[3]["Defense"], buildings[3]["Floop Status"])
	
	# SPELL
	if not spell.is_empty() and landscape_num == 69:
		spell_area_card.change_card_data(spell["Landscape"], spell["Card Type"], spell["Name"], spell["Ability"], spell["Cost"], spell["Attack"], spell["Defense"], spell["Floop Status"])

# ANIMATIONS
func play_hurt():
	if modulated:
		animation_player.play("hurt_when_modulated")
	else:
		animation_player.play("hurt")

func play_heal():
	if modulated:
		animation_player.play("heal_when_modulated")
	else:
		animation_player.play("heal")

func reset_anim():
	if modulated:
		animation_player.play("RESET_MODULATED")
	else:
		animation_player.play("RESET")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	reset_anim()

# STAT BUTTONS
func _on_hp_down_pressed() -> void:
	if not can_select:
		return
	GameManager.net_update_player_health.rpc(player_num, -1)
	log.make_log_message("Decreased hp.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_hp_up_pressed() -> void:
	if not can_select:
		return
	GameManager.net_update_player_health.rpc(player_num, 1)
	log.make_log_message("Increased hp.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_actions_down_pressed() -> void:
	if not can_select:
		return
	GameManager.net_update_player_actions.rpc(player_num, -1)
	log.make_log_message("Decreased actions.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_actions_up_pressed() -> void:
	if not can_select:
		return
	GameManager.net_update_player_actions.rpc(player_num, 1)
	log.make_log_message("Increased actions.")
	audio.confirm_sfx.play()
	start_selection_buffer()

# SPECIFIC BUTTONS
func _on_end_turn_pressed() -> void:
	if not can_select:
		return
	GameManager.client_start_attack_phase.rpc()
	log.make_log_message("Ended turn.")
	audio.confirm_sfx.play()
	start_selection_buffer()

# TIMERS
func _on_input_timer_timeout() -> void:
	input_timer_label.text = "0"
	can_select = true

# BUTTONS
func _on_main_button_pressed() -> void:
	if not can_select:
		return
	if in_deck_mode:
		grab_card_from_deck_logic()
	elif in_discard_mode:
		grab_card_from_discards_logic()
	else:
		draw_card_logic()
	log.make_log_message("Card drawn.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_sub_button_pressed() -> void:
	if not can_select:
		return
	discard_card_logic()
	log.make_log_message("Discarded card.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_main_switch_toggled(toggled_on: bool) -> void:
	if not can_select:
		return
	if toggled_on:
		update_player_discards_display()
		log.make_log_message("Switched to discard display.")
	else:
		update_player_hand_display()
		log.make_log_message("Switched to hand display.")

func _on_additional_options_pressed() -> void:
	if not can_select:
		return
	enable_additional_options()
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_deck_options_pressed() -> void:
	if not can_select:
		return
	enable_deck_options()
	audio.confirm_sfx.play()
	start_selection_buffer()

# Deck
func _on_deck_view_pressed() -> void:
	if not can_select:
		return
	update_player_deck_display()
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_deck_view_top_x_cards_pressed() -> void:
	if not can_select:
		return
	if scry_num.text.is_valid_int():
		update_scry_player_deck_display(int(scry_num.text))
	else:
		log.make_log_message("Invalid scry number!")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_deck_shuffle_pressed() -> void:
	if not can_select:
		return
	shuffle_deck_logic()
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_deck_draw_bottom_pressed() -> void:
	if not can_select:
		return
	draw_bottom_card_logic()
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_deck_add_top_pressed() -> void:
	if not can_select:
		return
	add_card_to_top_deck_logic()
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_deck_add_bottom_pressed() -> void:
	if not can_select:
		return
	add_card_to_bottom_deck_logic()
	audio.confirm_sfx.play()
	start_selection_buffer()

# Additional
func _on_delete_from_game_pressed() -> void:
	if not can_select:
		return
	remove_card_logic()
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_give_to_opp_pressed() -> void:
	if not can_select:
		return
	give_opp_card_logic()
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_add_card_to_hand_pressed() -> void:
	if not can_select:
		return
	grab_card_from_play_logic()
	audio.confirm_sfx.play()
	start_selection_buffer()

var og_index: Array[int] = []
func _on_hand_mouse_entered() -> void:
	if not hand_player.is_playing():
		hand_player.play("fan_cards")
		for card in hand.get_children():
			og_index.append(card.z_index)
			card.z_index = 99

func _on_hand_mouse_exited() -> void:
	if not hand_player.is_playing():
		hand_player.play("unfan_cards")
		for card in hand.get_children():
			var idx = og_index.pop_front()
			if idx != null:
				card.z_index = idx
		og_index = []

func _on_card_selection_timer_timeout() -> void:
	update_selected_card_image("fart")
