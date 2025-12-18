extends Node
@onready var player_stats: Label = $Player_Stats

@export var player_num: int
var local_health: int = GameManager.DEFAULT_HP
var local_actions: int = GameManager.DEFAULT_ACTIONS
var local_hand: Array

func _ready() -> void:
	update_player_stat_display()

func _process(delta: float) -> void:
	if NetworkHandler.is_peer_connected:
		check_player_stats()

# BUTTON ACTIONS
func _on_draw_card_pressed() -> void:
	GameManager.draw_card(player_num)

# UPDATES
func update_player_stat_display():
	player_stats.text = "Player " + str(player_num) + "\nHP: " + str(local_health) + "\nACTIONS: " + str(local_actions)

func update_player_hand_display():
	print("Player " + str(player_num) + "'s Hand:\n" + str(local_hand))

func check_player_stats():
	if player_num == 1:
		if local_health != GameManager.player1_health or local_actions != GameManager.player1_actions:
			print("Health: " + str(GameManager.player1_health))
			local_health = GameManager.player1_health
			local_actions = GameManager.player1_actions
			update_player_stat_display()
			print("Updated HP/Actions!")
		elif local_hand != GameManager.player1_hand:
			local_hand = GameManager.player1_hand
			update_player_hand_display()
			print("Updated Hand!")
	elif player_num == 2:
		if local_health != GameManager.player2_health or local_actions != GameManager.player2_actions:
			local_health = GameManager.player2_health
			local_actions = GameManager.player2_actions
			update_player_stat_display()
			print("Updated HP/Actions!")
		elif local_hand != GameManager.player2_hand:
			local_hand = GameManager.player2_hand
			update_player_hand_display()
			print("Updated Hand!")
