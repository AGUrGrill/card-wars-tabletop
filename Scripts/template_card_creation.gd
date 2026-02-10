extends TextureRect

@onready var deck_creator = $"../../.."
var card_type: String
var card_name: String
var is_choosen: bool = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clicked " + card_name)
		if is_choosen:
			if card_type == "Creature":
				deck_creator.remove_creature(card_name)
			elif card_type == "Spell":
				deck_creator.remove_spell(card_name)
			elif card_type == "Building":
				deck_creator.remove_building(card_name)
			elif card_type == "Landscape":
				deck_creator.remove_landscape(card_name)
			elif card_type == "Hero":
				deck_creator.remove_hero()
		else:
			if card_type == "Creature":
				deck_creator.add_creature(card_name, card_type)
			elif card_type == "Spell":
				deck_creator.add_spell(card_name, card_type)
			elif card_type == "Building":
				deck_creator.add_building(card_name, card_type)
			elif card_type == "Landscape":
				deck_creator.add_landscape(card_name, card_type)
			elif card_type == "Hero":
				deck_creator.add_hero(card_name)
