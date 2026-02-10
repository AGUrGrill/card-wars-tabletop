extends Node2D

@onready var audio: Node = $Audio
@onready var log: Node2D = $Log

@onready var search_name: LineEdit = $SearchName
@onready var search_ability: LineEdit = $SearchAbility
@onready var search_cost: LineEdit = $SearchCost
@onready var search_attack: LineEdit = $SearchAttack
@onready var search_defense: LineEdit = $SearchDefense
@onready var type_landscape: OptionButton = $TypeLandscape
@onready var deck_name: LineEdit = $DeckName
@onready var type_card: OptionButton = $TypeCard
@onready var search_cards: HBoxContainer = $SearchCards/CardDisplayPanel
@onready var choosen_cards: HBoxContainer = $ChoosenCards/CardDisplayPanel
@onready var choosen_landscapes: HBoxContainer = $ChoosenLandscapes/CardDisplayPanel
@onready var hero_image: Sprite2D = $HeroImage
@onready var current_deck_build_nums: Label = $CurrentDeckBuildNums

var hero: String
var landscapes: Array[String]
var creatures: Array[String]
var spells: Array[String]
var buildings: Array[String]

const TEMPLATE_CARD = preload("uid://cuyc4dl7cnc3m")

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	get_cards("", "", "", "", "", "", "")
	log.make_log_message("")

func update_deck_nums():
	var total_cards: int = creatures.size() + spells.size() + buildings.size()
	current_deck_build_nums.text = "Cards: " + str(total_cards) + " | Creatures: " + str(creatures.size()) + " | Spells: " + str(spells.size()) + " | Buildings: " + str(buildings.size())

func get_cards(_name: String, card_type: String, card_ability: String, landscape_type: String, cost: String, attack: String, defense: String):
	for child in search_cards.get_children():
		search_cards.remove_child(child)
	
	var json_data = GameManager.load_json_file(GameManager.CARD_LIST)
	if !json_data:
		return
	
	var name_filter: bool = false
	var card_type_filter: bool = false
	var card_ability_filter: bool = false
	var landscape_type_filter: bool = false
	var cost_filter: bool = false
	var attack_filter: bool = false
	var defense_filter: bool = false
	
	var max_cards: int = GameManager.MAX_CARDS
	var exclusions: Array[int] = [1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15, 17, 19, 20, 21, 567, 568]
	for num in max_cards:
		if num in exclusions:
			continue
		var card_data = json_data[str(num)]
		if card_data["Name"] == "Unknown" or card_data == null:
			continue
		elif card_data["Card Type"] == "Teamwork":
			continue
		
		if _name != "":
			name_filter = true
		if card_type != "" and card_type != "All Card Types":
			card_type_filter = true
		if not card_ability.is_empty():
			card_ability_filter = true
		if landscape_type != "" and landscape_type != "All Landscape Types":
			landscape_type_filter = true
		if not cost.is_empty():
			cost_filter = true
		if not attack.is_empty():
			attack_filter = true
		if not defense.is_empty():
			defense_filter = true
		
		var has_ability: bool = false
		var has_landscape: bool = false
		var has_cost: bool = false
		var has_attack: bool = false
		var has_defense: bool = false
		for key in card_data:
			if key == "Ability":
				has_ability = true
			elif key == "Landscape":
				has_landscape = true
			elif key == "Cost":
				has_cost = true
			elif key == "Attack":
				has_attack = true
			elif key == "Defense":
				has_defense = true
		
		if name_filter and not card_data["Name"].to_lower().contains(_name.to_lower()):
			print(card_data["Name"] + " does not contain " + _name)
			continue
		if card_type_filter and card_data["Card Type"] != card_type:
			print(card_data["Card Type"] + " is not " + card_type)
			continue
		if card_ability_filter:
			if not has_ability:
				continue
			if not card_data["Ability"].to_lower().contains(card_ability.to_lower()):
				print(card_data["Ability"] + " is not " + card_ability)
				continue
		if landscape_type_filter:
			if not has_landscape:
				continue
			if card_data["Landscape"] != landscape_type:
				print(card_data["Landscape"] + " is not " + landscape_type)
				continue
		if cost_filter:
			if not has_cost:
				continue
			if card_data["Cost"] != cost:
				print(card_data["Cost"] + " is not " + cost)
				continue
		if attack_filter:
			if not has_attack:
				continue
			if card_data["Attack"] != attack:
				print(card_data["Attack"] + " is not " + attack)
				continue
		if defense_filter:
			if not has_defense:
				continue
			if card_data["Defense"] != defense:
				print(card_data["Defense"] + " is not " + defense)
				continue
		
		var new_card = TEMPLATE_CARD.instantiate()
		search_cards.add_child(new_card)
		new_card.texture = get_card_image(card_data["Name"])
		new_card.card_name = card_data["Name"]
		new_card.card_type = card_data["Card Type"]
		new_card.scale = Vector2(1, 1)

func get_card_image(_name: String) -> ImageTexture:
	var tex = GameManager.db.cards.get(_name)
	var img: Image = tex.get_image()
	img.resize(150, 210, Image.INTERPOLATE_LANCZOS)
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	return texture

func add_creature(_name: String, card_type: String):
	if creatures.count(_name) >= 3:
		log.make_log_message("Maximum number of " + _name + " added. (3)")
		return
	creatures.append(_name)
	var new_card = TEMPLATE_CARD.instantiate()
	choosen_cards.add_child(new_card)
	new_card.texture = get_card_image(_name)
	new_card.card_name = _name
	new_card.scale = Vector2(1, 1)
	new_card.is_choosen = true
	new_card.card_type = card_type
	update_deck_nums()

func add_building(_name: String, card_type: String):
	if buildings.count(_name) >= 3:
		log.make_log_message("Maximum number of " + _name + " added. (3)")
		return
	buildings.append(_name)
	var new_card = TEMPLATE_CARD.instantiate()
	choosen_cards.add_child(new_card)
	new_card.texture = get_card_image(_name)
	new_card.card_name = _name
	new_card.scale = Vector2(1, 1)
	new_card.is_choosen = true
	new_card.card_type = card_type
	update_deck_nums()

func add_spell(_name: String, card_type: String):
	if spells.count(_name) >= 3:
		log.make_log_message("Maximum number of " + _name + " added. (3)")
		return
	spells.append(_name)
	var new_card = TEMPLATE_CARD.instantiate()
	choosen_cards.add_child(new_card)
	new_card.texture = get_card_image(_name)
	new_card.card_name = _name
	new_card.scale = Vector2(1, 1)
	new_card.is_choosen = true
	new_card.card_type = card_type
	update_deck_nums()

func add_landscape(_name: String, card_type: String):
	if landscapes.size() >= 4:
		return
	landscapes.append(_name)
	var new_card = TEMPLATE_CARD.instantiate()
	choosen_landscapes.add_child(new_card)
	new_card.texture = get_card_image(_name)
	new_card.card_name = _name
	new_card.scale = Vector2(1, 1)
	new_card.is_choosen = true
	new_card.card_type = card_type

func add_hero(_name: String):
	hero = _name
	hero_image.texture = get_card_image(_name)

func remove_creature(_name: String):
	creatures.pop_at(creatures.find(_name))
	for child in choosen_cards.get_children():
		if child.card_name.contains(_name):
			choosen_cards.remove_child(child)
			return
	update_deck_nums()

func remove_building(_name: String):
	buildings.pop_at(buildings.find(_name))
	for child in choosen_cards.get_children():
		if child.card_name.contains(_name):
			choosen_cards.remove_child(child)
			return
	update_deck_nums()

func remove_spell(_name: String):
	spells.pop_at(spells.find(_name))
	for child in choosen_cards.get_children():
		if child.card_name.contains(_name):
			choosen_cards.remove_child(child)
			return
	update_deck_nums()

func remove_landscape(_name: String):
	landscapes.pop_at(landscapes.find(_name))
	for child in choosen_landscapes.get_children():
		if child.card_name.contains(_name):
			choosen_landscapes.remove_child(child)
			return

func remove_hero():
	hero = ""
	hero_image.texture = ImageTexture.new()

func get_formatted_landscapes():
	var formatted_landscapes: String
	for landscape in landscapes:
		if formatted_landscapes.contains(landscape):
			continue
		formatted_landscapes += str(landscapes.count(landscape)) + " - " + landscape + "\n"
	return formatted_landscapes

func get_formatted_creatures():
	var formatted_creatures: String
	for creature in creatures:
		if formatted_creatures.contains(creature):
			continue
		var count: int = creatures.count(creature)
		if count > 3:
			count = 3
		formatted_creatures += str(count) + " - " + creature + "\n"
	return formatted_creatures

func get_formatted_spells():
	var formatted_spells: String
	for spell in spells:
		if formatted_spells.contains(spell):
			continue
		var count: int = spells.count(spell)
		if count > 3:
			count = 3
		formatted_spells += str(count) + " - " + spell + "\n"
	return formatted_spells

func get_formatted_buildings():
	var formatted_buildings: String
	for building in buildings:
		if formatted_buildings.contains(building):
			continue
		var count: int = buildings.count(building)
		if count > 3:
			count = 3
		formatted_buildings += str(count) + " - " + building + "\n"
	return formatted_buildings

func deck_valid():
	var num_of_cards_in_deck: int = 0
	for creature in creatures:
		num_of_cards_in_deck += 1
	for building in buildings:
		num_of_cards_in_deck += 1
	for spell in spells:
		num_of_cards_in_deck += 1
	if num_of_cards_in_deck < 40:
		log.make_log_message("Please add at least 40 cards.")
		return false
	
	if hero.is_empty():
		log.make_log_message("Please add at least 1 hero.")
		return false
	if landscapes.is_empty():
		log.make_log_message("Please add 4 landscapes.")
		return false
	if creatures.is_empty():
		log.make_log_message("Please add at least 1 creature.")
		return false
	if buildings.is_empty():
		log.make_log_message("No buildings found, continuing anyways.")
		buildings.append("")
	if spells.is_empty():
		log.make_log_message("No spells found, continuing anyways.")
		spells.append("")
	
	return true

func _on_return_to_menu_pressed() -> void:
	audio.confirm_sfx.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_save_deck_pressed() -> void:
	audio.confirm_sfx.play()
	if not deck_valid():
		return
	var formatted_content: String
	formatted_content = "Hero
" + hero + "

Landscapes
" + get_formatted_landscapes() + "

Creatures
" + get_formatted_creatures() + "

Spells
" + get_formatted_spells() + "

Buildings
" + get_formatted_buildings() + "
"
	save_to_file(formatted_content, deck_name.text)

func save_to_file(content: String, deck_name: String):
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("user://Decks"):
		dir.make_dir("Decks")
	var file = FileAccess.open("user://Decks/" + deck_name + ".dat", FileAccess.WRITE)
	file.store_string(content)
	log.make_log_message("\"" + deck_name + "\" deck created successfully!")

func _on_type_card_item_selected(index: int) -> void:
	get_cards(search_name.text, type_card.get_item_text(type_card.selected), search_ability.text, type_landscape.get_item_text(type_landscape.selected), search_cost.text, search_attack.text, search_defense.text)
	audio.confirm_sfx.play()

func _on_search_name_text_submitted(new_text: String) -> void:
	get_cards(search_name.text, type_card.get_item_text(type_card.selected), search_ability.text, type_landscape.get_item_text(type_landscape.selected), search_cost.text, search_attack.text, search_defense.text)
	audio.confirm_sfx.play()

func _on_search_ability_text_submitted(new_text: String) -> void:
	get_cards(search_name.text, type_card.get_item_text(type_card.selected), search_ability.text, type_landscape.get_item_text(type_landscape.selected), search_cost.text, search_attack.text, search_defense.text)
	audio.confirm_sfx.play()

func _on_search_cost_text_submitted(new_text: String) -> void:
	get_cards(search_name.text, type_card.get_item_text(type_card.selected), search_ability.text, type_landscape.get_item_text(type_landscape.selected), search_cost.text, search_attack.text, search_defense.text)
	audio.confirm_sfx.play()

func _on_search_attack_text_submitted(new_text: String) -> void:
	get_cards(search_name.text, type_card.get_item_text(type_card.selected), search_ability.text, type_landscape.get_item_text(type_landscape.selected), search_cost.text, search_attack.text, search_defense.text)
	audio.confirm_sfx.play()

func _on_search_defense_text_submitted(new_text: String) -> void:
	get_cards(search_name.text, type_card.get_item_text(type_card.selected), search_ability.text, type_landscape.get_item_text(type_landscape.selected), search_cost.text, search_attack.text, search_defense.text)
	audio.confirm_sfx.play()

func _on_type_landscape_item_selected(index: int) -> void:
	get_cards(search_name.text, type_card.get_item_text(type_card.selected), search_ability.text, type_landscape.get_item_text(type_landscape.selected), search_cost.text, search_attack.text, search_defense.text)
	audio.confirm_sfx.play()
