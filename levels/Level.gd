extends Node2D

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var coords = %TileMap.local_to_map(event.global_position)
		print(event.global_position)
		print(coords)
		print()
