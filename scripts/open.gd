extends Button

# TODO - save and load z-index

@export var open_dialog : FileDialog
@export var canvas      : Node2D
@export var menu_box    : Panel

func _ready() -> void:
	open_dialog.current_dir = "/"

func _on_button_down() -> void:
	open()

func open() -> void:
	menu_box.hide()
	open_dialog.show()

func _on_open_dialog_file_selected(path: String = "") -> void:
	var img : String = FileAccess.get_file_as_string(path)
	var new_image : Dictionary = json_to_dict(img).duplicate(true)
	for shape in new_image:
		var xxx = shape_from_strings(new_image[shape])
		canvas.image[int(shape)] = xxx
		canvas.add_collider(xxx, str(int(shape)))
	canvas.zindex.clear()
	for id in canvas.image:
		canvas.zindex.append(int(id))
	canvas.deselect_all()
	canvas.queue_redraw()

func string_to_vector2(string : String = "") -> Vector2:
	if string:
		var new_string : String = string
		new_string = new_string.erase(0, 1)
		new_string = new_string.erase(new_string.length() - 1, 1)
		var array : Array = new_string.split(", ")
		return Vector2(int(array[0]), int(array[1]))
	return Vector2.ZERO

func string_to_color(color_string: String = "") -> Color:
	var trimmed_string = color_string.strip_edges()
	trimmed_string = trimmed_string.erase(trimmed_string.length() - 1, 1)
	trimmed_string = trimmed_string.erase(0, 1)
	var components = trimmed_string.split(",")
	if components.size() != 4:
		return Color()
	var r = components[0].to_float()
	var g = components[1].to_float()
	var b = components[2].to_float()
	var a = components[3].to_float()
	return Color(r, g, b, a)

func string_array_to_vector2_array(string_array: Array) -> Array:
	var vector2_array = []
	for character in string_array:
		if not character.begins_with("(") or not character.ends_with(")"):
			continue
		var trimmed_string = character
		trimmed_string = trimmed_string.erase(trimmed_string.length() - 1, 1)
		trimmed_string = trimmed_string.erase(0, 1)
		var components = trimmed_string.split(",")
		if components.size() != 2:
			continue
		var x = components[0].to_float()
		var y = components[1].to_float()
		vector2_array.append(Vector2(x, y))
	return vector2_array

func shape_from_strings(dict_in : Dictionary) -> Dictionary:
	var rec_dict : Dictionary
	for prop in dict_in:
		match prop:
				"border":
					rec_dict["border"] = bool(dict_in["border"])
				"bulk":
					rec_dict["bulk"] = bool(dict_in["bulk"])
				"rounded":
					rec_dict["rounded"] = bool(dict_in["rounded"])
				"rows":
					rec_dict["rows"] = int(dict_in["rows"])
				"cols":
					rec_dict["cols"] = int(dict_in["cols"])
				"border_color":
					rec_dict["border_color"] = string_to_color(dict_in["border_color"])
				"path":
					rec_dict["path"] = str(dict_in["path"])
				"texture":
					rec_dict["texture"] = load("res://image.png")
				"points":
					rec_dict["points"] = string_array_to_vector2_array(dict_in["points"])
				"start":
					rec_dict["start"] = int(dict_in["start"])
				"end":
					rec_dict["end"] = int(dict_in["end"])
				"term_size":
					rec_dict["term_size"] = float(dict_in["term_size"])
				"control_points":
					rec_dict["control_points"] = string_array_to_vector2_array(dict_in["control_points"])
				"start_angle":
					rec_dict["start_angle"] = float(dict_in["start_angle"])
				"end_angle":
					rec_dict["end_angle"] = float(dict_in["end_angle"])
				"pie":
					rec_dict["pie"] = bool(dict_in["pie"])
				"closed":
					rec_dict["closed"] = bool(dict_in["closed"])
				"position":
					rec_dict["position"] = string_to_vector2(dict_in["position"])
				"size":
					rec_dict["size"] = string_to_vector2(dict_in["size"])
				"sides":
					rec_dict["sides"] = int(dict_in["sides"])
				"filled":
					rec_dict["filled"] = bool(dict_in["filled"])
				"text":
					rec_dict["text"] = str(dict_in["text"])
				"font_size":
					rec_dict["font_size"] = float(dict_in["font_size"])
				"text_color":
					rec_dict["text_color"] = string_to_color(dict_in["text_color"])
				"corner_radius":
					rec_dict["corner_radius"] = float(dict_in["corner_radius"])
				"type":
					rec_dict["type"] = int(dict_in["type"])  # global.string_to_shape_map.get(dict_in["type"], null)
				"locked":
					rec_dict["locked"] = bool(dict_in["locked"])
				"antialiased":
					rec_dict["antialiased"] = bool(dict_in["antialiased"])
				"group":
					rec_dict["group"] = int(dict_in["group"])
				"opacity":
					rec_dict["opacity"] = float(dict_in["opacity"])
				"rotation":
					rec_dict["rotation"] = float(dict_in["rotation"])
				"border_width":
					rec_dict["border_width"] = float(dict_in["border_width"])
				"color":
					rec_dict["color"] = string_to_color(dict_in["color"])
				"fill_color":
					rec_dict["fill_color"] = string_to_color(dict_in["fill_color"])
				"visible":
					rec_dict["visible"] = bool(dict_in["visible"])
				"chache":
					rec_dict["chache"] = {}
	return rec_dict

func json_to_dict(json : String = "") -> Dictionary:
	var J : JSON = JSON.new()
	var data_received : Dictionary
	var error = J.parse(json)
	if error == OK:
		data_received = J.data
	return data_received
