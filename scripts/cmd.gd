extends LineEdit

# Command line interface - Ferda Language
# Commands:
# quit / exit / end
# help / ?
# undo / redo
# save
# export
# add
# copy / paste
# duplicate [times]
# delete
# select [all]
# select rectangles
# grup
# rotate [angle]
# move
# laser
# flip  - h / v
# fill - set filled to true for selected shapes
# border
# say - for collaborative editing

const MAX_HISTORY   : int = 100

@export var help     : Panel
@export var settings : Panel
@export var canvas   : Node2D
@export var laser    : Line2D
@export var open     : Button
@export var save     : Button
@export var export   : Button

var history : Array = []

func _on_text_submitted(new_text: String) -> void:
	self.text = ""
	var input : Array = new_text.strip_edges().to_lower().split(" ")
	var non_empty : Array
	for string in input:
		if string != "":
			non_empty.append(string)
	if non_empty.size() == 0:
		return
	if history.size() == MAX_HISTORY:
		history.pop_back()
	history.append(non_empty)
	var command = non_empty.pop_front() # non_empty is only args now
	var args_count : int = non_empty.size()
	match command:
		"about":
			pass
		"quit", "exit", "end":
			get_tree().quit()
		"help", "?":
			help.show()
		"undo":
			global.do_undo()
		"redo":
			global.do_redo()
		"save", "s":
			save.save()
		"settings":
			settings.show()
		"export":
			export.export_show()
		"open", "o":
			open.open()
		"add":
			if args_count == 1:
				var object_type = global.string_to_shape_map.get(non_empty[0], null)
				if object_type != null:
					canvas.add_shape(object_type)
		"copy", "cpy":
			canvas.copy()
		"paste", "pst":
			canvas.paste()
		"duplicate", "dpl":
			canvas.copy()
			canvas.paste()
		"delete", "del":
			if args_count == 0:
				canvas.delete_selected()
		"select", "sel":
			canvas.select_all()
		"group", "grp":
			canvas.group_selected()
		"rotate", "rot", "r":
			pass
		"move", "m":
			pass
		"laser":
			laser._on_laser_button_down()
		"flip":
			pass
		"say", "!":
			print(non_empty)
		"debug":
			global.debug_mode = not global.debug_mode
			canvas.queue_redraw()
		"zoom":
			pass
		_:
			print("Unknown command " + command)
