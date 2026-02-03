extends Node2D

@onready var audio: Node = $Audio
@onready var win_amt: Label = $WinsLabel/WinAmt
@onready var loss_amt: Label = $LosesLabel/LossAmt

func _ready() -> void:
	var player_data = load_from_file()
	var wins: int = 0
	var losses: int = 0
	if player_data.is_empty():
		player_data = "Wins\n"+str(wins)+"\nLosses\n"+str(losses)
	var formatted_info: PackedStringArray = player_data.split("\n", false)
	var prev_line: String
	for line in formatted_info:
		if prev_line == "Wins":
			wins = int(line)
		elif prev_line == "Losses":
			losses = int(line)
		prev_line = line
	win_amt.text = str(wins)
	loss_amt.text = str(losses)

func _on_return_to_menu_pressed() -> void:
	audio.confirm_sfx.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func load_from_file():
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if file == null:
		print("Error getting file data.")
		return ""
	var content = file.get_as_text()
	return content
