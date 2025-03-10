extends Panel

# This script implements the style panel functionality for a given object.

@export var canvas : Node2D
@export var rows   : VBoxContainer

func update() -> void:
	delete_form()
	create_form()

func _process(_delta: float) -> void:
	# Why is the scroll hiding?
	var scroll = get_node_or_null("styleScroll/_v_scroll")
	if scroll != null:
		scroll.show()

func create_form() -> void:
	if canvas.selected.size() == 1 and canvas.image.size() > 0 and canvas.image.has(canvas.selected[0]):
		show()
		var id : int = canvas.selected[0]
		
		for key in canvas.image[id]:
			if key in ["type", "visible", "chache"]:
				continue
			var nam = Label.new()
			nam.text = key
			rows.add_child(nam)
			match type_string(typeof(canvas.image[id][key])):
				"String":
					var string_edit = LineEdit.new()
					string_edit.name = str(id) + "#" + key
					string_edit.set_theme(load("res://styles/dark.tres"))
					string_edit.text = canvas.image[id][key]
					string_edit.connect("text_changed", Callable(self, "_data_to_image_dictionary"))
					rows.add_child(string_edit)
				"Vector2":
					var vector_x_edit = LineEdit.new()
					vector_x_edit.set_theme(load("res://styles/dark.tres"))
					vector_x_edit.name = str(id) + "#" + key
					vector_x_edit.text = str(canvas.image[id][key].x)
					vector_x_edit.name = str(id) + "#" + key + "#x"
					vector_x_edit.connect("text_changed", Callable(self, "_data_to_image_dictionary"))
					var vector_y_edit = LineEdit.new()
					vector_y_edit.set_theme(load("res://styles/dark.tres"))
					vector_y_edit.name = str(id) + "#" + key + "#y"
					vector_y_edit.text = str(canvas.image[id][key].y)
					vector_y_edit.connect("text_changed", Callable(self, "_data_to_image_dictionary"))
					var columns = HBoxContainer.new()
					rows.add_child(columns)
					columns.add_child(vector_x_edit)
					columns.add_child(vector_y_edit)
				"int", "float":
					var num_edit = LineEdit.new()
					var slid = HSlider.new()
					slid.step = 1.0
					slid.min_value = -10
					slid.max_value = 10
					slid.value = PI
					num_edit.set_theme(load("res://styles/dark.tres"))
					num_edit.name = str(id) + "#" + key
					num_edit.text = str(canvas.image[id][key])
					num_edit.connect("text_changed", Callable(self, "_data_to_image_dictionary"))
					rows.add_child(slid)
					rows.add_child(num_edit)
				"Color":
					var color_edit = ColorPickerButton.new()
					color_edit.set_theme(load("res://styles/dark.tres"))
					color_edit.name = str(id) + "#" + key
					color_edit.color = canvas.image[id][key]
					color_edit.connect("color_changed", Callable(self, "_data_to_image_dictionary"))
					rows.add_child(color_edit)
				"bool":
					var bool_edit = CheckBox.new()
					bool_edit.set_theme(load("res://styles/dark.tres"))
					bool_edit.name = str(id) + "#" + key
					#bool_edit.text = str(canvas.image[id][key])
					bool_edit.set_pressed_no_signal(canvas.image[id][key])
					bool_edit.connect("toggled", Callable(self, "_data_to_image_dictionary"))
					rows.add_child(bool_edit)
				"Array": # for a line
					var array_container = VBoxContainer.new()
					rows.add_child(array_container)
					for i in range(canvas.image[id][key].size()):
						var item = canvas.image[id][key][i]
						match type_string(typeof(item)):
							"int", "float":
								var num_edit = LineEdit.new()
								num_edit.set_theme(load("res://styles/dark.tres"))
								num_edit.name = str(id) + "#" + key + "#num#" + str(i)
								num_edit.text = str(item)
								num_edit.connect("text_changed", Callable(self, "_data_to_image_dictionary"))
								array_container.add_child(num_edit)
							"Vector2":
								var vector_x_edit = LineEdit.new()
								vector_x_edit.set_theme(load("res://styles/dark.tres"))
								vector_x_edit.name = str(id) + "#" + key + "#vec_x#" + str(i)
								vector_x_edit.text = str(item.x)
								vector_x_edit.connect("text_changed", Callable(self, "_data_to_image_dictionary"))
								var vector_y_edit = LineEdit.new()
								vector_y_edit.set_theme(load("res://styles/dark.tres"))
								vector_y_edit.name = str(id) + "##" + key + "#vec_y#" + str(i)
								vector_y_edit.text = str(item.y)
								vector_y_edit.connect("text_changed", Callable(self, "_data_to_image_dictionary"))
								var columns = HBoxContainer.new()
								array_container.add_child(columns)
								columns.add_child(vector_x_edit)
								columns.add_child(vector_y_edit)
			var divider = HSeparator.new()
			rows.add_child(divider)

func delete_form() -> void:
	for a in rows.get_children():
		rows.remove_child(a)
		a.call_deferred("queue_free")
	hide()

func _data_to_image_dictionary(_aaa) -> void:
	var id = canvas.selected[0]
	for child in rows.get_children():
		if child is LineEdit:
			var keys : Array = child.name.split("#")
			var key : String = keys[1]
			var value : String = child.text
				
			if key == "value":
				pass
			else:
				match typeof(canvas.image[id][key]):
					TYPE_STRING:
						canvas.image[id][key] = value
					TYPE_INT:
						canvas.image[id][key] = int(value)
					TYPE_FLOAT:
						canvas.image[id][key] = float(value)
					_:
						pass
		elif child is ColorPickerButton:
			var key : String = child.name.split("#")[1]
			canvas.image[id][key] = child.color
		elif child is CheckBox:
			var key : String = child.name.split("#")[1]
			canvas.image[id][key] = child.button_pressed
		elif child is HBoxContainer:
			for items in child.get_children():
				if items is LineEdit:
					var keys : Array = items.name.split("#")
					var key : String = keys[1]
					var sub_key : String
					if keys.size() > 2:
							sub_key = keys[2] # x or y
					var value = items.text
					if sub_key == "x" or sub_key == "y":
						var keint : int
						if sub_key == "x":
							keint = 0
						elif sub_key == "y":
							keint = 1
						canvas.image[id][key][keint] = float(value)
	canvas.queue_redraw()
