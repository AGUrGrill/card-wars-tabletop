extends Node2D

@onready var win_image: Sprite2D = $WinImage
@onready var lose_image: Sprite2D = $LoseImage
@onready var result_label: Label = $ResultLabel

func _ready() -> void:
	if GameManager.who_won == false and multiplayer.get_unique_id() == GameManager.player1_id:
		win_image.visible = true
		result_label.text = "YOU WIN!"
	elif GameManager.who_won == true and multiplayer.get_unique_id() == GameManager.player1_id:
		lose_image.visible = true
		result_label.text = "YOU LOSE..."
	elif GameManager.who_won == true and multiplayer.get_unique_id() == GameManager.player2_id:
		win_image.visibile = true
		result_label.text = "YOU WIN!"
	elif GameManager.who_won == false and multiplayer.get_unique_id() == GameManager.player2_id:
		lose_image.visible = true
		result_label.text = "YOU LOSE..."
