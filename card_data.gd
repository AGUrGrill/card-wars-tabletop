extends Node

# CARD DATA
@export var card_type: String = ""
@export var card_name: String = ""
@export var card_description: String = ""
@export var card_cost: int = 0
@export var card_attack: int = 0
@export var card_defense: int = 0
@export var is_flooped: bool = false

# CARD FUNCTIONS
func update_card_attack(modifier: int):
	var temp_attack = card_attack + modifier
	if temp_attack >= 0:
		card_attack = temp_attack
	else:
		card_attack = 0

func update_card_defense(modifier: int):
	var temp_defense = card_defense + modifier
	if temp_defense >= 0:
		card_defense = temp_defense
	else:
		card_defense = 0

func floop_card():
	if !is_flooped:
		is_flooped = true
	else:
		is_flooped = false
