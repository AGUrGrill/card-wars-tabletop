extends TextureRect

@onready var deck_creator = $"../../.."
var card_type: String
var is_choosen: bool = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clicked " + name)
		if is_choosen:
			if card_type == "Creature":
				deck_creator.remove_creature(name)
			elif card_type == "Spell":
				deck_creator.remove_spell(name)
			elif card_type == "Building":
				deck_creator.remove_building(name)
			elif card_type == "Landscape":
				deck_creator.remove_landscape(name)
			elif card_type == "Hero":
				deck_creator.remove_hero()
		else:
			if card_type == "Creature":
				deck_creator.add_creature(name, card_type)
			elif card_type == "Spell":
				deck_creator.add_spell(name, card_type)
			elif card_type == "Building":
				deck_creator.add_building(name, card_type)
			elif card_type == "Landscape":
				deck_creator.add_landscape(name, card_type)
			elif card_type == "Hero":
				deck_creator.add_hero(name)
