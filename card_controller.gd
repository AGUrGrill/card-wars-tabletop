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
@export var card_base_attack: int = 0
@export var card_base_defense: int = 0
@export var is_flooped: bool = false
@export var is_in_hand: bool = true
var is_dead: bool = false
var selected: bool = false

func _ready() -> void:
	remove_card_data()

func change_card_data(landscape: String, type: String, _name: String, desc: String, cost: int, attack: int, defense: int, _is_flooped: bool):
	if card_name != "tempname": # If card was already played and now replaced, send to discards
		return
	
	update_card_image(_name)
	card_landscape = landscape
	card_type = type
	card_name = _name
	card_description = desc
	card_cost = cost
	card_attack = attack
	card_base_attack = attack
	attack_label.text = str(card_attack)
	card_defense = defense
	card_base_defense = defense
	defense_label.text = str(card_defense)
	if _is_flooped:
		floop_card()
		print("Flooping")
	hide_card(false)

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

func hide_card(should_hide: bool):
	if should_hide:
		card.visible = false
		card.input_pickable = false
		attack_node.visible = false
		defense_node.visible = false
		floop_button.visible = false
	else:
		card.visible = true
		card.input_pickable = true
		attack_node.visible = true
		defense_node.visible = true
		floop_button.visible = true

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

func update_card_defense(modifier: int):
	var temp_defense = card_defense + modifier
	if temp_defense >= 0:
		card_defense = temp_defense
	else:
		card_defense = 0
		is_dead = true
	defense_label.text = str(card_defense)

func floop_card():
	if !is_flooped:
		is_flooped = true
		card.rotation = 90
	else:
		is_flooped = false
		card.rotation = 0

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
			"Landscape Played": get_card_landscape_num()
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
			"Landscape Played": get_card_landscape_num()
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
	floop_card()

# Focus Card
func _on_mouse_entered() -> void:
	card.z_index = 99

func _on_mouse_exited() -> void:
	card.z_index = 9

# Select Card
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_pressed():
		GameManager.net_update_player_selected_card.rpc(get_card_player_num(), {})
		if not selected:
			card.modulate = "aeaeae"
			selected = true
			GameManager.net_update_player_selected_card.rpc(get_card_player_num(), get_card_data(false))
		else:
			card.modulate = "ffffff"
			selected = false
