extends Node2D

@onready var hp_label: Label = $StatPanel/HPLabel
@onready var actions_label: Label = $StatPanel/ActionsLabel
@onready var player_label: Label = $StatPanel/PlayerLabel
@onready var opponent_hp_label: Label = $StatPanel/OpponentHPLabel

@onready var player: Node2D = $"."
@onready var draw_card: Button = $DrawCard
@onready var discard_card: Button = $DiscardCard
@onready var end_turn: Button = $EndTurn
@onready var deck_switch: CheckButton = $DeckSwitch
@onready var landscape_1_creature: Area2D = $Landscape1/Card
@onready var landscape_2_creature: Area2D = $Landscape2/Card
@onready var landscape_3_creature: Area2D = $Landscape3/Card
@onready var landscape_4_creature: Area2D = $Landscape4/Card
@onready var landscape_1_building: Area2D = $Building1/Card
@onready var landscape_2_building: Area2D = $Building2/Card
@onready var landscape_3_building: Area2D = $Building3/Card
@onready var landscape_4_building: Area2D = $Building4/Card
@onready var selected_card: Sprite2D = $SelectedCard
@onready var spell_area_card: Area2D = $SpellArea/Card
@onready var actions_down: Button = $StatPanel/ActionsLabel/ActionsDown
@onready var actions_up: Button = $StatPanel/ActionsLabel/ActionsUp
@onready var hp_up: Button = $StatPanel/HPLabel/HPUp
@onready var hp_down: Button = $StatPanel/HPLabel/HPDown
@onready var hand: HBoxContainer = $Hand
const CARD = preload("uid://dycs2rc7imye2")
@onready var hero_image: Sprite2D = $HeroImage
@onready var input_timer: Timer = $InputTimer
@onready var input_timer_label: Label = $InputTimerLabel
@onready var log_label: Label = $LogLabel
@onready var log_timer: Timer = $LogTimer

@export var player_num: int
var is_player_board: bool
var in_discard_mode: bool
var disabled: bool = true
@onready var audio: Node = $Audio
var can_select: bool = true

# need to fix where cards discard

func _ready() -> void:
	hand.set_meta("player_num", player_num)
	if player_num == 1 and not multiplayer.get_unique_id() == GameManager.player1_id:
		audio.audio_type = "Disabled"
	elif player_num == 2 and not multiplayer.get_unique_id() == GameManager.player2_id:
		audio.audio_type = "Disabled"
	disabled = true
	disable_inputs(false, true)

func _process(delta: float) -> void:
	determine_display_visibility()
	if GameManager.game_ended:
		get_tree().change_scene_to_file("res://end_screen.tscn")
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
	if player_num == 2 and multiplayer.get_unique_id() == GameManager.player2_id:
		if GameManager.p2_turn and disabled:
			disable_inputs(false, false)
			disabled = false
		elif not GameManager.p2_turn and not disabled:
			disable_inputs(false, true)
			disabled = true

func disable_inputs(should_disable: bool, should_modulate: bool):
	if should_disable:
		actions_up.disabled = true
		actions_down.disabled = true
		hp_up.disabled = true
		hp_down.disabled = true
		draw_card.disabled = true
		discard_card.disabled = true
		end_turn.disabled = true
		deck_switch.disabled = true
	else:
		actions_up.disabled = false
		actions_down.disabled = false
		hp_up.disabled = false
		hp_down.disabled = false
		draw_card.disabled = false
		discard_card.disabled = false
		end_turn.disabled = false
		deck_switch.disabled = false
	if should_modulate:
		player.modulate = "7a7a7a"
	else:
		player.modulate = "ffffff"

func update_hero_image():
	var _name: String
	if player_num == 1:
		_name = GameManager.player1_hero
	elif player_num == 2:
		_name = GameManager.player2_hero
	
	var tex = GameManager.db.cards.get(_name)
	hero_image.texture = tex

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
	print("Discarded " + selected_card["Name"] + " from P" + str(player_num))

func draw_card_logic():
	if player_num == 1:
		GameManager.net_add_card_to_player_hand.rpc(1, GameManager.draw_card(1))
	if player_num == 2:
		GameManager.net_add_card_to_player_hand.rpc(2, GameManager.draw_card(2))

func grab_card_logic():
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

func change_to_discard_layout():
	draw_card.text = "GRAB CARD"
	discard_card.disabled = true
	discard_card.visible = false
	in_discard_mode = true

func change_to_draw_layout():
	draw_card.text = "DRAW CARD"
	discard_card.disabled = false
	discard_card.visible = true
	in_discard_mode = false

func get_real_player_num():
	if multiplayer.get_unique_id() == GameManager.player1_id:
		return 1
	elif multiplayer.get_unique_id() == GameManager.player2_id:
		return 2

func update_selected_card_image(_name: String):
	if _name == "fart":
		selected_card.texture = null
		return
	
	var tex = GameManager.db.cards.get(_name)
	var img: Image = tex.get_image()
	img.resize(150, 210, Image.INTERPOLATE_LANCZOS)
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	selected_card.texture = texture

func start_selection_buffer():
	can_select = false
	input_timer.start()

func make_log_message(message: String):
	log_label.text = message
	log_timer.start()

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
	player_label.text = "PLAYER " + str(player_num)
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
	
	var max_length: float = hand.size.x
	var increment: float = max_length / main_hand.size()
	
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
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]), 0, 0, false, player_num)
		else:
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]),  int(card["Attack"]),  int(card["Defense"]), false, player_num)
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
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]), 0, 0, false, player_num)
		else:
			new_card.change_card_data(card["Landscape"], card["Card Type"], card["Name"], card_ability, int(card["Cost"]),  int(card["Attack"]),  int(card["Defense"]), false, player_num)
	print(discards_hand)

func update_player_landscapes():
	landscape_1_creature.remove_card_data()
	landscape_2_creature.remove_card_data()
	landscape_3_creature.remove_card_data()
	landscape_4_creature.remove_card_data()
	landscape_1_building.remove_card_data()
	landscape_2_building.remove_card_data()
	landscape_3_building.remove_card_data()
	landscape_4_building.remove_card_data()
	spell_area_card.remove_card_data()
	
	var creatures: Array[Dictionary]
	var buildings: Array[Dictionary]
	var spell: Dictionary
	var landscapes: Array[String]
	if player_num == 1:
		creatures = GameManager.player1_played_creatures
		buildings = GameManager.player1_played_buildings
		spell = GameManager.player1_current_spell
		landscapes = GameManager.player1_landscapes
	if player_num == 2:
		creatures = GameManager.player2_played_creatures
		buildings = GameManager.player2_played_buildings
		spell = GameManager.player2_current_spell
		landscapes = GameManager.player2_landscapes
	
	# LANDSCAPES
	if not landscapes[0].is_empty():
		$Landscape1.update_landscape_image(landscapes[0])
	if not landscapes[1].is_empty():
		$Landscape2.update_landscape_image(landscapes[1])
	if not landscapes[2].is_empty():
		$Landscape3.update_landscape_image(landscapes[2])
	if not landscapes[3].is_empty():
		$Landscape4.update_landscape_image(landscapes[3])
	
	# CREATURES
	if not creatures[0].is_empty():
		landscape_1_creature.is_in_hand = false
		landscape_1_creature.change_card_data(creatures[0]["Landscape"], creatures[0]["Card Type"], creatures[0]["Name"], creatures[0]["Ability"], creatures[0]["Cost"], creatures[0]["Attack"], creatures[0]["Defense"], creatures[0]["Floop Status"], player_num)
	if not creatures[1].is_empty():
		landscape_2_creature.is_in_hand = false
		landscape_2_creature.change_card_data(creatures[1]["Landscape"], creatures[1]["Card Type"], creatures[1]["Name"], creatures[1]["Ability"], creatures[1]["Cost"], creatures[1]["Attack"], creatures[1]["Defense"], creatures[1]["Floop Status"], player_num)
	if not creatures[2].is_empty():
		landscape_3_creature.is_in_hand = false
		landscape_3_creature.change_card_data(creatures[2]["Landscape"], creatures[2]["Card Type"], creatures[2]["Name"], creatures[2]["Ability"], creatures[2]["Cost"], creatures[2]["Attack"], creatures[2]["Defense"], creatures[2]["Floop Status"], player_num)
	if not creatures[3].is_empty():
		landscape_4_creature.is_in_hand = false
		landscape_4_creature.change_card_data(creatures[3]["Landscape"], creatures[3]["Card Type"], creatures[3]["Name"], creatures[3]["Ability"], creatures[3]["Cost"], creatures[3]["Attack"], creatures[3]["Defense"], creatures[3]["Floop Status"], player_num)
	
	# BUILDINGS
	if not buildings[0].is_empty():
		landscape_1_building.is_in_hand = false
		landscape_1_building.change_card_data(buildings[0]["Landscape"], buildings[0]["Card Type"], buildings[0]["Name"], buildings[0]["Ability"], buildings[0]["Cost"], buildings[0]["Attack"], buildings[0]["Defense"], buildings[0]["Floop Status"], player_num)
	if not buildings[1].is_empty():
		landscape_2_building.is_in_hand = false
		landscape_2_building.change_card_data(buildings[1]["Landscape"], buildings[1]["Card Type"], buildings[1]["Name"], buildings[1]["Ability"], buildings[1]["Cost"], buildings[1]["Attack"], buildings[1]["Defense"], buildings[1]["Floop Status"], player_num)
	if not buildings[2].is_empty():
		landscape_3_building.is_in_hand = false
		landscape_3_building.change_card_data(buildings[2]["Landscape"], buildings[2]["Card Type"], buildings[2]["Name"], buildings[2]["Ability"], buildings[2]["Cost"], buildings[2]["Attack"], buildings[2]["Defense"], buildings[2]["Floop Status"], player_num)
	if not buildings[3].is_empty():
		landscape_4_building.is_in_hand = false
		landscape_4_building.change_card_data(buildings[3]["Landscape"], buildings[3]["Card Type"], buildings[3]["Name"], buildings[3]["Ability"], buildings[3]["Cost"], buildings[3]["Attack"], buildings[3]["Defense"], buildings[3]["Floop Status"], player_num)
	
	# SPELL
	if not spell.is_empty():
		spell_area_card.change_card_data(spell["Landscape"], spell["Card Type"], spell["Name"], spell["Ability"], spell["Cost"], spell["Attack"], spell["Defense"], spell["Floop Status"], player_num)

# UPDATE BUTTON CHANGES
func _on_hp_down_pressed() -> void:
	if not can_select:
		return
	GameManager.net_update_player_health.rpc(player_num, -1)
	make_log_message("Decreased hp.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_hp_up_pressed() -> void:
	if not can_select:
		return
	GameManager.net_update_player_health.rpc(player_num, 1)
	make_log_message("Increased hp.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_actions_down_pressed() -> void:
	if not can_select:
		return
	GameManager.net_update_player_actions.rpc(player_num, -1)
	make_log_message("Decreased actions.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_actions_up_pressed() -> void:
	if not can_select:
		return
	GameManager.net_update_player_actions.rpc(player_num, 1)
	make_log_message("Increased actions.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_draw_card_pressed() -> void:
	if not can_select:
		return
	if in_discard_mode:
		grab_card_logic()
	else:
		draw_card_logic()
	make_log_message("Card drawn.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_discard_card_pressed() -> void:
	if not can_select:
		return
	discard_card_logic()
	make_log_message("Discarded card.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_deck_switch_toggled(toggled_on: bool) -> void:
	if not can_select:
		return
	if toggled_on:
		update_player_discards_display()
		make_log_message("Switched to discard display.")
	else:
		update_player_hand_display()
		make_log_message("Switched to hand display.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_end_turn_pressed() -> void:
	if not can_select:
		return
	GameManager.client_start_attack_phase.rpc()
	make_log_message("Ended turn.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_remove_card_pressed() -> void:
	if not can_select:
		return
	remove_card_logic()
	make_log_message("Removed card.")
	audio.confirm_sfx.play()
	start_selection_buffer()

func _on_swap_owner_pressed() -> void:
	if not can_select:
		return
	if player_num == 1:
		if not GameManager.player2_selected_card.is_empty():
			var modified_card: Dictionary = GameManager.player2_selected_card
			modified_card["Owner"] = 1
			GameManager.net_update_player_selected_card.rpc(1, modified_card)
			GameManager.net_update_player_selected_card.rpc(2, {})
	elif player_num == 2:
		if not GameManager.player1_selected_card.is_empty():
			var modified_card: Dictionary = GameManager.player1_selected_card
			modified_card["Owner"] = 2
			GameManager.net_update_player_selected_card.rpc(2, modified_card)
			GameManager.net_update_player_selected_card.rpc(1, {})
	make_log_message("Swapped card owner.")
	audio.confirm_sfx.play()
	start_selection_buffer()


func _on_input_timer_timeout() -> void:
	input_timer_label.text = "0"
	can_select = true


func _on_log_timer_timeout() -> void:
	log_label.text = ""
