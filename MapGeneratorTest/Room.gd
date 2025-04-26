extends RefCounted
class_name Room

var id: int
var position: Vector2i  # Changed to Vector2i for tile coordinates
var size: Vector2i     # Changed to Vector2i for tile dimensions
var metadata: Dictionary = {}  # Added type hint
var selected: bool = false
var connections: Array[Room] = []  # Added typed array

func _init(_id: int, _position: Vector2i, _size: Vector2i, _metadata: Dictionary = {}) -> void:
	id = _id
	position = _position
	size = _size
	metadata = _metadata 