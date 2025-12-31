@tool
extends EditorScript

const CARD_PATH := "res://Assets/Cards"

func _run():
	var db := CardDatabase.new()
	var dir := DirAccess.open(CARD_PATH)

	if dir == null:
		printerr("Cannot open card directory")
		return

	for file in dir.get_files():
		if file.get_extension() in ["png", "jpg", "webp"]:
			var key := file.get_basename()
			var tex := load(CARD_PATH + "/" + file)
			db.cards[key] = tex

	ResourceSaver.save(db, "res://Assets/Database/CardDatabase.tres")
	print("Card database built with ", db.cards.size(), " cards")
