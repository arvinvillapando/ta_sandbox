class_name CharacterList
extends Resource

@export var characters: Array[PackedScene] = []

func get_character_paths() -> Array[String]:
	var paths: Array[String] = []
	for character in characters:
		if character:
			paths.append(character.resource_path)
	return paths

func get_character_count() -> int:
	return characters.size()

func get_character_at_index(index: int) -> PackedScene:
	if index >= 0 and index < characters.size():
		return characters[index]
	return null
