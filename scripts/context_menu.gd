extends Panel

# Context menu

@export var canvas : Node2D
@export var rows : VBoxContainer
@export var camera : Camera2D
@export var editor : Node2D

# Actions are performed on objects in this Array.
# The Array is populated when the menu is opened.
var on_ids : Array = []

func set_menu_size(items : int) -> void:
	var height : float = items * 31 + 40
	var width : float = 180
	custom_minimum_size = Vector2(width, height)
	size = Vector2(width, height)

func open_menu(pos : Vector2) -> void:
	delete_menu()
	on_ids = []
	if canvas.selected.size() > 0 and canvas.hovered[0] in canvas.selected:
		for id in canvas.selected:
			on_ids.append(id)
		if canvas.image[canvas.hovered[0]]["type"] == global.S.polyline:
			print("aaa")
	elif canvas.hovered.size() > 0:
		on_ids.append(canvas.hovered[0])
	var item_count : int = create_menu()
	set_menu_size(item_count)
	
	
	position = pos
	show()

func close_menu() -> void:
	delete_menu()
	hide()

func delete_menu() -> void:
	for a in rows.get_children():
		rows.remove_child(a)
		a.call_deferred("queue_free")

func create_menu() -> int:
	var actions : Array
	var labels : Array
	var item_count : int = 0
	if on_ids.size() > 0:
		actions = ["delete", "cut", "copy", "duplicate", "locking", "to_front", "to_back", "forward", "backward"]
		labels = ["Delete", "Cut", "Copy", "Duplicate", "Lock", "Move front", "Move back", "Forward", "Backward"]
	else:
		actions = ["select_all", "undo", "redo"]
		labels = ["Select All", "Undo", "Redo"]
	
	item_count = actions.size()
	
	var i : int = 0
	for action in actions:
		var button = Button.new()
		button.text = labels[i]
		i += 1
		button.connect("button_down", Callable(self, "do_action").bind(action))
		rows.add_child(button)
	
	return item_count

func do_action(action : String) -> void:
	match action:
		"delete":
			canvas.deselect_all()
			for id in on_ids:
				canvas.delete_id(id)
		"cut":
			canvas.copy()
			camera._on_delete_pressed()
		"copy":
			canvas.copy()
		"duplicate":
			canvas.copy()
			editor.paste()
		"locking":
			for id in on_ids:
				canvas.image[id]["locked"] = !canvas.image[id]["locked"]
		"to_front":
			canvas.z_index_to_side(false)
		"to_back":
			canvas.z_index_to_side(true)
		"forward":
			canvas.z_index_up()
		"backward":
			canvas.z_index_lower()
		
	close_menu()
