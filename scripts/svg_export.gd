extends Button

# SVG exporter

@export var export_dialog : FileDialog
@export var canvas        : Node2D

func _ready() -> void:
	export_dialog.current_dir = "/"

func _on_button_down() -> void:
	export_show()

func export_show() ->void:
	export_dialog.show()

func export(image : Dictionary = {}) -> String:
	var ret_string : String = ""
	ret_string = """<?xml version="1.0" encoding="UTF-8" standalone="no"?>"""
	ret_string += "<svg>"
	for shape in image:
		match shape["type"]:
			_:
				pass
	ret_string += "</svg>"
	return ret_string

func _on_svg_export_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_line(export(canvas.image))
