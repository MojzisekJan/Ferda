extends Button

# Saving image.

@export var save_dialog : FileDialog
@export var canvas      : Node2D

var save_path : String = "user://image.json"

func _ready() -> void:
	save_dialog.current_dir = "/"

func _on_button_down() -> void:
	save()

func save() ->void:
	save_dialog.show()

func _on_save_dialog_file_selected(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_line(image_to_string())

func image_to_string() -> String:
	# Save in order given by the canvas.zindex Array.
	return JSON.stringify(canvas.image)
