extends Panel

# This script indicates the current tool.

@export var icon : TextureRect

func _ready() -> void:
	icon.texture = load("res://img/select.svg")

func set_tool_icon(new_tool : String) -> void:
	match new_tool:
		"polyline":
			icon.texture = load("res://img/polyline.svg")
		"curve":
			icon.texture = load("res://img/curve.svg")
		"select":
			icon.texture = load("res://img/select.svg")
