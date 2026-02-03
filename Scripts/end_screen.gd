extends Node2D

@onready var win_image: Sprite2D = $WinImage
@onready var lose_image: Sprite2D = $LoseImage
@onready var result_label: Label = $ResultLabel
@onready var audio: Node = $Audio

func _ready() -> void:
	end_game_logic()

func _on_return_menu_pressed() -> void:
	audio.confirm_sfx.play()
	GameManager.game_ended = false
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func end_game_logic():
	NetworkHandler.peer.disconnect_peer(multiplayer.get_unique_id())
	var player_data = load_from_file()
	var wins: int = 0
	var losses: int = 0
	if player_data.is_empty():
		player_data = "Wins\n"+str(wins)+"\nLosses\n"+str(losses)
	var prev_line: String
	for line in player_data:
		if prev_line == "Wins":
			wins = int(line)
		elif prev_line == "Losses":
			losses = int(line)
		prev_line = line
	if multiplayer.get_unique_id() == GameManager.player1_id:
		if GameManager.who_won == false:
			win_image.visible = true
			result_label.text = "YOU WIN!"
			wins+=1
		elif GameManager.who_won == true:
			lose_image.visible = true
			result_label.text = "YOU LOSE..."
			losses+=1
	if multiplayer.get_unique_id() == GameManager.player2_id:
		if GameManager.who_won == true:
			win_image.visible = true
			result_label.text = "YOU WIN!"
			wins+=1
		#p1 and p2
		elif GameManager.who_won == false:
			lose_image.visible = true
			result_label.text = "YOU LOSE..."
			losses+=1
	player_data = "Wins\n"+str(wins)+"\nLosses\n"+str(losses)
	save_to_file(player_data)

func save_to_file(content):
	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	file.store_string(content)
	print("Wrote data to file!")
	print(content)

func load_from_file():
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if file == null:
		return ""
	var content = file.get_as_text()
	return content
