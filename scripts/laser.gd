extends Line2D

const MAX_POINTS : int = 160

var active  : bool = false
var pressed : bool = false
var laser   : Array

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pressed = true
			else:
				pressed = false

func _process(_delta : float) -> void:
	if active and pressed:
		var pos = get_local_mouse_position()
		laser.push_front(pos)
	else:
		laser.pop_back()
	if laser.size() > MAX_POINTS:
		laser.pop_back()
	clear_points()
	
	for point in laser:
		add_point(point)


func _on_laser_button_down() -> void:
	active = not active
	
	if(active):
		$"../CanvasLayer/Control/actions/menu/HBoxContainer/laser".icon = load("res://img/laser_active.svg")
	else:
		$"../CanvasLayer/Control/actions/menu/HBoxContainer/laser".icon = load("res://img/laser.svg")
