extends Area2D

const TEMP_IMG = preload("uid://bkuqpel75myiu")

@onready var card_image: Sprite2D = $Image
@onready var attack_node: Control = $Attack
@onready var defense_node: Control = $Defense
@onready var floop_button: Button = $FloopButton
@onready var card: Area2D = $"."
@onready var attack_label: Label = $Attack/AttackLabel
@onready var defense_label: Label = $Defense/DefenseLabel
@onready var steal: Button = $Steal
@onready var landscape = $".." # Can be hand or landscape so leave vague


# CARD DATA
var card_landscape: String = ""
var card_type: String = ""
var card_name: String = ""
var card_description: String = ""
var card_cost: int = 0
var card_attack: int = 0
var card_defense: int = 0
var card_base_attack: int = 0
var card_base_defense: int = 0
var is_flooped: bool = false
var is_in_hand: bool = true
var is_dead: bool = false
var card_owner: int

func _ready() -> void:
	remove_card_data()

func change_card_data(_landscape: String, type: String, _name: String, desc: String, cost: int, attack: int, defense: int, _is_flooped: bool):
	if card_name != "tempname": # If card was already played and now replaced, send to discards
		return
	
	update_card_image(_name)
	card_landscape = _landscape
	card_type = type
	if type == "Creature":
		hide_buttons(false)
	elif type == "Building":
		hide_buttons(true)
	elif type == "Spell":
		hide_buttons(true)
	card_name = _name
	card_description = desc
	card_cost = cost
	card_attack = attack
	card_base_attack = attack
	attack_label.text = str(card_attack)
	card_defense = defense
	card_base_defense = defense
	defense_label.text = str(card_defense)
	card_owner = get_card_player_num()
	if _is_flooped:
		floop_card(true, false)
		print("Flooping")
	hide_card(false)
	if is_in_hand:
		hide_buttons(true)
	if card_defense <= 0 and not is_in_hand and card_type == "Creature":
		remove_card()

func remove_card():
	GameManager.net_add_card_to_player_discards.rpc(1, get_card_data(true))
	GameManager.net_remove_creature_from_landscape_array.rpc(get_card_player_num(), get_card_landscape_num())

func remove_card_data():
	card_image.texture = null
	card_landscape = "templandscape"
	card_type = "temptype"
	card_name = "tempname"
	card_description = "tempdescription"
	card_cost = 0
	card_attack = 0
	card_defense = 0
	hide_card(true)

func update_played_card_info_to_server():
	GameManager.net_update_creature_in_landscape_array.rpc(get_card_player_num(), get_card_landscape_num(), card_type, card_attack, card_defense, is_flooped)
	GameManager.net_tell_clients_to_refresh_hand.rpc()
	GameManager.net_tell_clients_to_refresh_stats.rpc()

func hide_buttons(should_hide: bool):
	if should_hide:
		attack_node.visible = false
		defense_node.visible = false
		floop_button.visible = false
		steal.visible = false
	else:
		attack_node.visible = true
		defense_node.visible = true
		floop_button.visible = true
		steal.visible = true

func hide_card(should_hide: bool):
	hide_buttons(should_hide)
	if should_hide:
		card.visible = false
		card.input_pickable = false
	else:
		card.visible = true
		card.input_pickable = true

func hide_image():
	update_card_image("card_back")

# CARD FUNCTIONS
func update_card_image(_name: String):
	var tex: Texture2D = GameManager.db.cards.get(_name)
	if tex == null:
		print("error printing " + _name)
		return
	var img: Image = tex.get_image()
	img.resize(150, 210, Image.INTERPOLATE_LANCZOS)
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	card_image.texture = texture

func old_update_card_image(_name: String):
	var img_path: String = ""
	var dir := DirAccess.open(GameManager.CARD_LOCATION)
	if dir == null: printerr("Could not open folder"); return
	dir.list_dir_begin()
	for file: String in dir.get_files():
		if (_name == file.trim_suffix(".png") or _name == file.trim_suffix(".jpg") or _name == file.trim_suffix(".webp")):
			img_path = dir.get_current_dir() + "/" + file
	var img: Image = Image.new()
	img.load(img_path)
	if img != null:
		img.resize(150, 210, Image.INTERPOLATE_LANCZOS)
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	card_image.texture = texture

func update_card_attack(modifier: int):
	var temp_attack = card_attack + modifier
	if temp_attack >= 0:
		card_attack = temp_attack
	else:
		card_attack = 0
	attack_label.text = str(card_attack)
	update_played_card_info_to_server()

func update_card_defense(modifier: int):
	var temp_defense = card_defense + modifier
	if temp_defense >= 0:
		card_defense = temp_defense
	else:
		card_defense = 0
		remove_card()
	defense_label.text = str(card_defense)
	update_played_card_info_to_server()

func floop_card(should_floop: bool, update_to_server: bool):
	# fix to double floop issue when second call is made
	if should_floop:
		is_flooped = true
		card.rotation_degrees = 90
	else:
		is_flooped = false
		card.rotation_degrees = 0
	if update_to_server:
		update_played_card_info_to_server()

func get_card_data(is_base: bool) -> Dictionary:
	var card_data: Dictionary
	if is_base: 
		card_data = {
			"Name": card_name,
			"Card Type": card_type,
			"Landscape": card_landscape,
			"Ability": card_description,
			"Cost": card_cost,
			"Attack": card_base_attack,
			"Defense": card_base_defense,
			"Floop Status": is_flooped,
			"Landscape Played": get_card_landscape_num(),
			"Owner": card_owner
		}
	else:
		card_data = {
			"Name": card_name,
			"Card Type": card_type,
			"Landscape": card_landscape,
			"Ability": card_description,
			"Cost": card_cost,
			"Attack": card_attack,
			"Defense": card_defense,
			"Floop Status": is_flooped,
			"Landscape Played": get_card_landscape_num(),
			"Owner": card_owner
		}
	return card_data

func get_card_player_num() -> int:
	var player_num: int
	if landscape.get_class() == "HBoxContainer": # If hand get player num via metadata
		player_num = landscape.get_meta("player_num")
	else:
		player_num = landscape.player.player_num
	return player_num

func get_card_landscape_num() -> int:
	var landscape_num: int
	if landscape.get_class() == "HBoxContainer": # If hand get player num via metadata
		landscape_num = 99
	else:
		landscape_num = landscape.landscape_num
	return landscape_num

# BUTTONS
func _on_attack_up_pressed() -> void:
	update_card_attack(1)

func _on_attack_down_pressed() -> void:
	update_card_attack(-1)

func _on_defense_up_pressed() -> void:
	update_card_defense(1)

func _on_defense_down_pressed() -> void:
	update_card_defense(-1)

func _on_floop_button_pressed() -> void:
	if is_flooped:
		floop_card(false, true)
	else:
		floop_card(true, true)

# Focus Card
func _on_mouse_entered() -> void:
	card.z_index = 99

func _on_mouse_exited() -> void:
	card.z_index = 9

# Select Card
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_pressed():
		if get_card_landscape_num() == 99:
			$"../..".update_selected_card_image(card_name)
		else:
			if $"../..".can_select == false:
				return
			landscape.player.update_selected_card_image(card_name)
		GameManager.net_update_player_selected_card.rpc(get_card_player_num(), get_card_data(false))
		GameManager.net_tell_clients_to_refresh_landscapes.rpc()
		print("Selected " + card_name + " for " + str(get_card_player_num()))


func _on_steal_pressed() -> void:
	if card_owner == 1:
		GameManager.net_remove_creature_from_landscape_array.rpc(1, get_card_landscape_num())
		GameManager.net_add_card_to_player_hand.rpc(2, get_card_data(true))
	elif card_owner == 2:
		GameManager.net_remove_creature_from_landscape_array.rpc(2, get_card_landscape_num())
		GameManager.net_add_card_to_player_hand.rpc(1, get_card_data(true))
