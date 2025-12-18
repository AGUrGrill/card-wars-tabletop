extends Node2D

func _on_start_server_pressed() -> void:
	NetworkHandler.start_server()
	get_tree().change_scene_to_file("res://board.tscn")

func _on_start_client_pressed() -> void:
	NetworkHandler.start_client()
	get_tree().change_scene_to_file("res://board.tscn")
