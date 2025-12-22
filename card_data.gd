extends Area2D

const TEMP_IMG = preload("uid://bkuqpel75myiu")
const CARD_LOCATION: String = "res://Assets/Cards/"

@onready var card_image: Sprite2D = $Image
@onready var attack_node: Control = $Attack
@onready var defense_node: Control = $Defense
@onready var floop_button: Button = $FloopButton
@onready var card: Area2D = $"."
@onready var attack_label: Label = $Attack/AttackLabel
@onready var defense_label: Label = $Defense/DefenseLabel
@onready var landscape = $".." # Can be hand or landscape so leave vague

# CARD DATA
@export var card_landscape: String = ""
@export var card_type: String = ""
@export var card_name: String = ""
@export var card_description: String = ""
@export var card_cost: int = 0
@export var card_attack: int = 0
@export var card_defense: int = 0
@export var is_flooped: bool = false
@export var is_in_hand: bool = false
var selected = false

func _ready() -> void:
	remove_card_data()
	if is_in_hand:
		attack_node.visible = false
		defense_node.visible = false
		floop_button.visible = false

func change_card_data(landscape: String, type: String, _name: String, desc: String, cost: int, attack: int, defense: int, _is_flooped: bool):
	update_card_image(_name)
	card_landscape = landscape
	card_type = type
	card_name = _name
	card_description = desc
	card_cost = cost
	card_attack = attack
	attack_label.text = str(card_attack)
	card_defense = defense
	defense_label.text = str(card_defense)
	if _is_flooped:
		floop_card()

func remove_card_data():
	card_image.texture = TEMP_IMG
	card_landscape = "templandscape"
	card_type = "temptype"
	card_name = "tempname"
	card_description = "tempdescription"
	card_cost = 0
	card_attack = 0
	card_defense = 0

func update_card_on_server():
	print("Updating " + str(card_type) + " on landscape" + str(landscape.landscape_num) + " for P" + str(landscape.player.player_num) + "(" + str(multiplayer.get_unique_id()) + ")")
	update_card_on_client(landscape.player.player_num, landscape.landscape_num, card_type, card_attack, card_defense, is_flooped)
	if GameManager.player1_id == multiplayer.get_unique_id():
		GameManager.update_card_on_landscape.rpc_id(GameManager.player2_id, landscape.player.player_num, landscape.landscape_num, card_type, card_attack, card_defense, is_flooped)
	elif GameManager.player2_id == multiplayer.get_unique_id():
		GameManager.update_card_on_landscape.rpc_id(GameManager.player1_id, landscape.player.player_num, landscape.landscape_num, card_type, card_attack, card_defense, is_flooped)

func update_card_on_client(player_num: int, landscape_num: int, card_type: String, attack: int, defense: int, is_flooped: bool):
	print("Updating " + str(card_type) + " on landscape" + str(landscape_num) + " for P" + str(player_num) + "(" + str(multiplayer.get_unique_id()) + ")")
	if player_num == 1:
		if card_type == "Creature":
			GameManager.player1_played_creatures[landscape_num]["Attack"] = attack
			GameManager.player1_played_creatures[landscape_num]["Defense"] = defense
			GameManager.player1_played_creatures[landscape_num]["Floop Status"] = is_flooped
		elif card_type == "Building":
			GameManager.player1_played_buildings[landscape_num]["Floop Status"] = is_flooped
	elif player_num == 2:
		if card_type == "Creature":
			GameManager.player2_played_creatures[landscape_num]["Attack"] = attack
			GameManager.player2_played_creatures[landscape_num]["Defense"] = defense
			GameManager.player2_played_creatures[landscape_num]["Floop Status"] = is_flooped
		elif card_type == "Building":
			GameManager.player2_played_buildings[landscape_num]["Floop Status"] = is_flooped

# CARD FUNCTIONS
func update_card_image(_name: String):
	var img_path: String = ""
	var dir := DirAccess.open(CARD_LOCATION)
	if dir == null: printerr("Could not open folder"); return
	dir.list_dir_begin()
	for file: String in dir.get_files():
		if (_name == file.trim_suffix(".png")):
			img_path = dir.get_current_dir() + "/" + file
	var img: Image = Image.load_from_file(img_path)
	if img != null:
		img.resize(140, 210)
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	card_image.texture = texture

func update_card_attack(modifier: int):
	var temp_attack = card_attack + modifier
	if temp_attack >= 0:
		card_attack = temp_attack
	else:
		card_attack = 0
	attack_label.text = str(card_attack)
	update_card_on_server()

func update_card_defense(modifier: int):
	var temp_defense = card_defense + modifier
	if temp_defense >= 0:
		card_defense = temp_defense
	else:
		card_defense = 0
	defense_label.text = str(card_defense)
	update_card_on_server()

func floop_card():
	if !is_flooped:
		is_flooped = true
		card.rotation = 90
	else:
		is_flooped = false
		card.rotation = 0
	update_card_on_server()

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
	floop_card()

# Focus Card
func _on_mouse_entered() -> void:
	card.z_index = 99

func _on_mouse_exited() -> void:
	card.z_index = 9

# Select Card
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_pressed():
		GameManager.player_selected_card.clear()
		
		if not selected:
			card.modulate = "aeaeae"
			selected = true
			
			var card_data: Dictionary = {
				"Card Name": card_name,
				"Card Type": card_type,
				"Landscape": card_landscape,
				"Ability": card_description,
				"Cost": card_cost,
				"Attack": card_attack,
				"Defense": card_defense,
				"Floop Status": is_flooped
			}
			
			GameManager.player_selected_card = card_data
		else:
			card.modulate = "ffffff"
			selected = false
