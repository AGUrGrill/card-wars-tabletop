extends Node2D

@onready var win_image: Sprite2D = $WinImage
@onready var lose_image: Sprite2D = $LoseImage
@onready var result_label: Label = $ResultLabel
@onready var audio: Node = $Audio

func _ready() -> void:
	if multiplayer.get_unique_id() == GameManager.player1_id:
		if GameManager.who_won == false:
			win_image.visible = true
			result_label.text = "YOU WIN!"
		elif GameManager.who_won == true:
			lose_image.visible = true
			result_label.text = "YOU LOSE..."
	if multiplayer.get_unique_id() == GameManager.player2_id:
		if GameManager.who_won == true:
			win_image.visible = true
			result_label.text = "YOU WIN!"
		#p1 and p2
		elif GameManager.who_won == false:
			lose_image.visible = true
			result_label.text = "YOU LOSE..."
	


func _on_return_menu_pressed() -> void:
	NetworkHandler.peer.disconnect_peer(multiplayer.get_unique_id())
	audio.confirm_sfx.play()
	#await get_tree().create_timer(0.5).timeout
	#get_tree().change_scene_to_file("res://main_menu.tscn")
