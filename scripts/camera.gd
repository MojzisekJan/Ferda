extends Camera2D

# Input handling

const VZERO : Vector2 = Vector2(0, 0)
const F : bool = false
const T : bool = true
const OFFSET_LIMIT = 1000
const MIN_ZOOM = 0.2
const MAX_ZOOM = 3.0
const RECT_FILL_COLOR: Color = Color("008cf222")
const RECT_OUTLINE_COLOR: Color = Color("99d1f922")
const OUTLINE_THICKNESS: float = -1.0

enum MAIN {IDLE, SELECTING, DRAGSTART, DRAGGING, ROTSTART, ROTATING}
enum HANDLES {ROT, TOP_LEFT, TOP_CENTER, TOP_RIGHT, LEFT, RIGHT, BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT}

@export var c            : Node2D
@export var style        : Panel
@export var context_menu : Panel
@export var laser        : Line2D
@export var editor       : Node2D
@export var tool_panel   : Panel
@export var open_button  : Button
@export var help         : Panel

var pan_speed       : float = 1.0
var rotate_speed    : float = 1.0
var can_pan         : bool = T
var can_zoom        : bool = T
var can_rotate      : bool = F
var sum_relative_x  : int = 0
var sum_relative_y  : int = 0
var start_distance  : float = 0.0
var start_angle     : float = 0.0
var current_angle   : float = 0.0
var start_zoom      : Vector2 = VZERO
var selection_start : Vector2 = VZERO
var selection_end   : Vector2 = VZERO
var pan_start       : Vector2 = VZERO
var press_point     : Vector2 = VZERO
var touch_points    : Dictionary = {}
var active_tool     : global.TOOLS = global.TOOLS.SELECT
var selection_rect  : Rect2
var is_panning      : bool = F
var mouse_left_down : bool = F
var is_selecting    : bool = F
var dragging        : bool = F
var main_state      : MAIN = MAIN.IDLE

func check_selected_and_move(direction: String) -> bool:
	if c.selected.is_empty():
		return F
	
	var directions: Dictionary = {
		"right": Vector2(c.grid_size, 0),
		"left": Vector2(-c.grid_size, 0),
		"up": Vector2(0, -c.grid_size),
		"down": Vector2(0, c.grid_size),
	}
	
	var diff: Vector2 = directions.get(direction, VZERO)
	if diff == VZERO:
		return F
	
	for j in c.selected:
		c.image[j]["position"] += diff
	
	c.queue_redraw()
	return T

func _unhandled_input(event : InputEvent) -> void:
	var ctrl : bool = Input.is_action_pressed("ctrl")
	#var shift : bool = Input.is_action_pressed("shift")
	# handle arrows for movement
	if Input.is_action_pressed("arrow_right"):
		if not check_selected_and_move("right"):
			position.x += 100
	if Input.is_action_pressed("arrow_left"):
		if not check_selected_and_move("left"):
			position.x -= 100
	if Input.is_action_pressed("arrow_up"):
		if not check_selected_and_move("up"):
			position.y -= 100
	if Input.is_action_pressed("arrow_down"):
		if not check_selected_and_move("down"):
			position.y += 100
	if Input.is_action_pressed("open"):
		open_button.open()
		
	if Input.is_action_pressed("delete"):
		#c.delete_selected()
		c.edit_image("delete", c.selected, {})
	elif Input.is_action_just_pressed("select_all"):
		c.select_all()
		global.undoStack.push_front({
			"action": global.ACTION.SELECT_ALL
		})
	elif Input.is_action_just_pressed("backspace"):
		#c.delete_selected()
		c.edit_image("delete", c.selected, {})
	elif Input.is_action_just_pressed("copy"):
		c.copy()
	elif Input.is_action_just_pressed("cut"):
		c.copy()
		#c.delete_selected()
		c.edit_image("delete", c.selected, {})
	elif Input.is_action_just_pressed("paste"):
		c.paste()
	elif Input.is_action_just_pressed("duplicate"):
		c.copy()
		c.paste()
	elif Input.is_action_just_pressed("undo"):
		global.do_undo()
	elif Input.is_action_just_pressed("redo"):
		pass
	elif Input.is_action_just_pressed("esc"):
		if active_tool in [global.TOOLS.POLYLINE, global.TOOLS.CURVE]:
			active_tool = global.TOOLS.SELECT
			tool_panel.set_tool_icon("select")
		c.deselect_all()
	elif Input.is_action_pressed("group"):
		c.group_selected()
		#var new_group_id : int = global.get_new_group_id()
		#for id in c.selected:
			#c.image[id]["group"] = new_group_id
		
	if event is InputEventScreenTouch and c.mouse_in_canvas:
		handle_touch(event)
	elif event is InputEventScreenDrag and c.mouse_in_canvas:
		handle_drag(event)
		
	# Mouse
	elif event is InputEventMouse and c.mouse_in_canvas:
		var zoom_speed : float = 0.3
		var mouse_position : Vector2 = get_global_mouse_position()
		if event.is_action_released('zoom_out'):
			zoom_camera(-zoom_speed, mouse_position)
		if event.is_action_released('zoom_in'):
			zoom_camera(zoom_speed, mouse_position)
		if event.is_action_pressed('pan'):
			is_panning = T
			pan_start = get_local_mouse_position()
		if event.is_action_released('pan'):
			is_panning = F
		if event is InputEventMouseMotion:
			handle_mouse_motion(event)
		if event is InputEventMouseButton:
			handle_mouse_button(event, ctrl)

func handle_mouse_press(ev : InputEventMouseButton) -> void:
	mouse_left_down = T
	match main_state:
		MAIN.IDLE:
			selection_start = get_global_mouse_position()
			if c.hovered.size() == 0:
				if not c.inside_rotate and c.inside_handle != "0":
					main_state = MAIN.DRAGSTART
					dragging = T
				else:
					if c.inside_rotate:
						main_state = MAIN.ROTSTART
					else:
						is_selecting = T
						main_state = MAIN.SELECTING
			else:
				if c.selected.size() > 0:
					if c.inside_rotate:
						main_state = MAIN.ROTSTART
					else:
						main_state = MAIN.DRAGSTART
						c.id_being_dragged = c.hovered[0]
						c.update_guides(F)
						dragging = T
		MAIN.DRAGSTART:
			pass
		MAIN.DRAGGING:
			if c.inside_handle != "0":
				c.drag_handle = T
		MAIN.SELECTING:
			if not ev.pressed:
				end_selecting()
				main_state = MAIN.IDLE

func rotate_point(x : float, y : float, _center : Vector2, angle : float) -> Vector2:
	# Rotates a point (x, y) around a given center or (0,0) by an angle (in radians).
	var dx : float = x - _center.x
	var dy : float = y - _center.y
	var sin_angle : float = sin(angle)
	var cos_angle : float = cos(angle)
	return Vector2(
		dx * cos_angle - dy * sin_angle + _center.x,
		dx * sin_angle + dy * cos_angle + _center.y
	)

func project_point_to_line(line_a: Vector2, line_b: Vector2, point: Vector2) -> Vector2:
	var AB = line_b - line_a
	var AC = point - line_a
	var coeff = (AB.x * AC.x + AB.y * AC.y) / (AB.x * AB.x + AB.y * AB.y)
	return line_a + AB * coeff

func modify_rect(rect : Rect2, newXY : Vector2, angle : float, handle : HANDLES) -> Rect2:
	var return_rect : Rect2 = Rect2(0, 0, 0, 0)
	var newX = newXY.x
	var newY = newXY.y
	var center : Vector2 = Vector2(
	rect.position.x + rect.size.x / 2,
	rect.position.y + rect.size.y / 2)
	#
	#   A -- B
	#	|    |
	#   C -- D
	#
	match handle:
		
		#HANDLES.TOP_LEFT, HANDLES.TOP_RIGHT, HANDLES.BOTTOM_LEFT, HANDLES.BOTTOM_RIGHT:
			## Determine the opposite corner based on the handle (anchor)
			#var opposite_corner : Vector2
			#if handle == HANDLES.TOP_LEFT:
				#opposite_corner = rect.position + rect.size
			#elif handle == HANDLES.TOP_RIGHT:
				##opposite_corner = rect.position + Vector2(0, rect.size.y)
				#opposite_corner = Vector2(rect.position.x, rect.position.y + rect.size.y)
			#elif handle == HANDLES.BOTTOM_LEFT:
				#opposite_corner = rect.position + Vector2(rect.size.x, 0)
			#else:  # HANDLES.BOTTOM_RIGHT
				#opposite_corner = rect.position
#
			#var rotated_opposite = rotate_point(opposite_corner.x, opposite_corner.y, center, angle)
			#var new_center = (rotated_opposite + newXY) / 2
			#var new_top_left = rotate_point(newXY.x, newXY.y, new_center, -angle)
			#var new_bottom_right = rotate_point(rotated_opposite.x, rotated_opposite.y, new_center, -angle)
#
			#return_rect = Rect2(new_top_left, new_bottom_right - new_top_left)
		
		HANDLES.TOP_LEFT:
			var rotated_d = rotate_point(rect.position.x + rect.size.x, rect.position.y + rect.size.y, center, angle)
			var new_center = Vector2((rotated_d.x + newX) / 2, (rotated_d.y + newY) / 2)
			var new_bottom_right = rotate_point(rotated_d.x, rotated_d.y, new_center, -angle)
			var new_top_left = rotate_point(newX, newY, new_center, -angle)
			return_rect = Rect2(Vector2(new_top_left.x, new_top_left.y), Vector2(new_bottom_right.x - new_top_left.x, new_bottom_right.y - new_top_left.y))

		HANDLES.TOP_RIGHT:
			var rotatedC = rotate_point(rect.position.x, rect.position.y + rect.size.y, center, angle)
			var new_center = Vector2((rotatedC.x + newX) / 2, (rotatedC.y + newY) / 2)
			var new_bottom_left = rotate_point(rotatedC.x, rotatedC.y, new_center, -angle)
			var new_top_right = rotate_point(newX, newY, new_center, -angle)
			return_rect = Rect2(Vector2(new_bottom_left.x, new_top_right.y), Vector2(new_top_right.x - new_bottom_left.x, new_bottom_left.y - new_top_right.y))

		HANDLES.BOTTOM_LEFT:
			var rotatedB = rotate_point(rect.position.x + rect.size.x, rect.position.y, center, angle)
			var new_center = Vector2((rotatedB.x + newX) / 2, (rotatedB.y + newY) / 2)
			var new_top_right = rotate_point(rotatedB.x, rotatedB.y, new_center, -angle)
			var new_bottom_left = rotate_point(newX, newY, new_center, -angle)
			return_rect = Rect2(Vector2(new_bottom_left.x, new_top_right.y), Vector2(new_top_right.x - new_bottom_left.x, new_bottom_left.y - new_top_right.y))
		
		HANDLES.BOTTOM_RIGHT:
			var rotated_a = rotate_point(rect.position.x, rect.position.y, center, angle)
			var new_center = Vector2((rotated_a.x + newX) / 2, (rotated_a.y + newY) / 2)
			var new_top_left = rotate_point(rotated_a.x, rotated_a.y, new_center, -angle)
			var new_bottom_right = rotate_point(newX, newY, new_center, -angle)
			return_rect = Rect2(Vector2(new_top_left.x, new_top_left.y), Vector2(new_bottom_right.x - new_top_left.x, new_bottom_right.y - new_top_left.y))

		HANDLES.TOP_CENTER, HANDLES.BOTTOM_CENTER:
			var a : float = rect.position.x + 0.5 * rect.size.x
			var b : float = rect.position.y
			if handle == HANDLES.TOP_CENTER:
				b += rect.size.y
			var rotated_anchor : Vector2 = rotate_point(a, b, center, angle)
			var projected_point : Vector2 = project_point_to_line(center, rotated_anchor, newXY)
			var new_center : Vector2 = 0.5 * (rotated_anchor + projected_point)
			var new_height : float = (rotated_anchor - projected_point).length()
			var new_top_left : Vector2 = new_center - 0.5 * Vector2(rect.size.x, new_height)
			return_rect = Rect2(new_top_left, Vector2(rect.size.x, new_height))

		HANDLES.LEFT, HANDLES.RIGHT:
			var a : float = rect.position.x
			if handle == HANDLES.LEFT:
				a += rect.size.x
			var b : float = rect.position.y + 0.5 * rect.size.y
			var rotated_anchor : Vector2 = rotate_point(a, b, center, angle)
			var projected_point : Vector2 = project_point_to_line(center, rotated_anchor, newXY)
			var new_center : Vector2 = 0.5 * (rotated_anchor + projected_point)
			var new_width : float = (rotated_anchor - projected_point).length()
			var new_top_left : Vector2 = new_center - 0.5 * Vector2(new_width, rect.size.y)
			return_rect = Rect2(new_top_left, Vector2(new_width, rect.size.y))
		
		_:
			pass
	return check_rect(return_rect)

func check_rect(input: Rect2) -> Rect2:
	# Ensures a Rect2's size components are non-negative, returning the corrected Rect2.
	var size = Vector2(
		max(input.size.x, 0),
		max(input.size.y, 0)
	)
	return Rect2(input.position, size)

func handle_mouse_button(event : InputEvent, ctrl : bool) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			handle_mouse_press(event)
			if active_tool == global.TOOLS.SELECT:
				use_select_tool_on_pressed(ctrl)
			elif active_tool == global.TOOLS.POLYLINE:
				use_polyline_tool(event.double_click)
				c.queue_redraw()
			elif active_tool == global.TOOLS.CURVE:
				use_curve_tool(event.double_click)
				c.update_curve_select_colliders(c.selected[0])
				c.queue_redraw()
		elif event.is_released():
			use_select_tool_on_released(ctrl)
			mouse_left_down = F
			selection_end = get_global_mouse_position()
			end_selecting()
			end_dragging()
			c.rot_in_progress = F
			main_state = MAIN.IDLE
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		context_menu.open_menu(event.position)

var allow_deselect : bool = F

# a) ctrl is pressed
#    1 click to void does nothing
#    2 released on non-selected object selects
#    3 released on selected object deselects it
#    4 drag does duplicate
# b) ctrl is not pressed
#    1 released in void deselects all
#    2 pressed on object selects it and deselect all other
#    3 pressed and released on selected does nothing
# c) when any number of object are selected and dragging is after press on already selected
#    all objects are dragged and none is deselected (useing the distance between press and release)
#
#   Drag and shift drags only along x or y axes

func use_select_tool_on_released(ctrl : bool) -> void:
	context_menu.close_menu()
	var drag_distance : float = press_point.distance_to(get_global_mouse_position())
	if drag_distance < 1:
		if ctrl:
			if c.hovered.size() > 0:
				if c.hovered[0] not in c.selected:
					c.select_id(c.hovered[0])
				else:
					c.deselect_id(c.hovered[0])
		else:
			if c.hovered.size() == 0:
				c.deselect_all()

func use_select_tool_on_pressed(ctrl : bool) -> void:
	context_menu.close_menu()
	press_point = get_global_mouse_position()
	if ctrl:
		pass
	else:
		if c.hovered.size() > 0:
			if c.hovered[0] not in c.selected:
				c.deselect_all()
				c.select_id(c.hovered[0])
	c.queue_redraw()

func use_polyline_tool(double_click : bool) -> void:
	var id : int = c.selected[0]
	var new_point : Vector2 = get_global_mouse_position()
	c.image[id]["points"].append(new_point)
	c.add_polyline_collider(id)
	if double_click: # end polyline
		c.delete_last_polyline_point(id)
		c.deselect_id(id)
		await get_tree().process_frame
		c.select_id(id)
		active_tool = global.TOOLS.SELECT
		tool_panel.set_tool_icon("select")

func use_curve_tool(double_click : bool) -> void:
	var id : int = c.selected[0]
	if c.image[id]["type"] != global.S.curve:
		print("Wrong call of use_curve_tool!")
		return
	var new_point : Vector2 = get_global_mouse_position()
	var point_in : Vector2 = new_point + Vector2(0, -100)
	var point_out : Vector2 = new_point + Vector2(0, 100)
	c.image[id]["control_points"].append(point_in)
	c.image[id]["control_points"].append(point_out)
	c.image[id]["curve_instance"].add_point(new_point, Vector2(0, -100), Vector2(0, 100))
	#c.add_polyline_collider(id)
	if double_click:
		c.delete_last_polyline_point(id)
		c.deselect_id(id)
		await get_tree().process_frame
		c.select_id(id)
		active_tool = global.TOOLS.SELECT
		tool_panel.set_tool_icon("select")

func handle_mouse_motion(ev : InputEvent) -> void:
	if is_panning:
		position -= ev.relative / zoom.x
	if is_selecting:
		var rect_size : Vector2 = get_global_mouse_position() - selection_start
		selection_rect = Rect2(selection_start, rect_size)
		queue_redraw()
	
	match main_state:
		MAIN.IDLE:
			if mouse_left_down and c.hovered.size() == 0:
				selection_end = get_global_mouse_position()
			elif mouse_left_down and c.selected.size() > 0:
				main_state = MAIN.DRAGSTART
		MAIN.DRAGSTART:
			allow_deselect = F
			if c.selected.size() > 0 or c.hovered.size() > 0:
				end_selecting()
				main_state = MAIN.DRAGGING
			if c.inside_handle != "0":
				c.drag_handle = T
		MAIN.DRAGGING:
			c.draw_guides()
			var diff : Vector2 = VZERO
			sum_relative_x += ev.relative.x
			sum_relative_y += ev.relative.y
			
			var snap_size : int = c.grid_size
			if abs(sum_relative_x) > snap_size:
				diff.x += (sum_relative_x - (sum_relative_x % snap_size))
				sum_relative_x = sum_relative_x % snap_size
			if abs(sum_relative_y) > snap_size:
				diff.y += (sum_relative_y - (sum_relative_y % snap_size))
				sum_relative_y = sum_relative_y % snap_size
			diff *= (1 / zoom.x)
			
			for J in c.selected:
				if not c.drag_handle:
					drag_shape(J, diff)
				else:
					var extracted : Array = c.inside_handle.split("_")
					var extracted_past = c.last_handle.split("_")
					c.id_being_dragged = int(extracted[0])
					
					if extracted[0] != extracted_past[0]:
						c.id_being_dragged = int(extracted_past[0])
						extracted = extracted_past
					
					if int(J) != int(extracted[0]): # Resize only the shape to which the used handle belongs.
						continue
					if c.image[J]["type"] in [global.S.line, global.S.arrow]:
						if extracted[1] == "0":
							c.image[J]["points"][0] += diff
						elif extracted[1] == "1":
							c.image[J]["points"][1] += diff
					elif c.image[J]["type"] == global.S.polyline:
						c.image[J]["points"][int(extracted[1]) - 1] += diff
					elif c.image[J]["type"] == global.S.curve:
						if extracted.size() == 2:
							var point : Vector2 = c.image[J]["curve_instance"].get_point_position(int(extracted[1]) - 1) + diff
							c.image[J]["curve_instance"].set_point_position(int(extracted[1]) - 1, point)
							# Move also anchors in ["control_points"]:
							# Or get rid of ["control_points"]
							#TODO FIXME...
						else:
							var idx : int = int(extracted[1]) - 1
							var p : Vector2
							var b : Vector2
							if extracted[2] == "l":
								p = c.image[J]["control_points"][2 * idx] + diff
								b = c.image[J]["curve_instance"].get_point_out(idx) + diff
								c.image[J]["curve_instance"].set_point_out(idx, b)
								c.image[J]["control_points"][2 * idx] = p
							elif extracted[2] == "r":
								p = c.image[J]["control_points"][2 * idx + 1] + diff
								b = c.image[J]["curve_instance"].get_point_in(idx) + diff
								c.image[J]["curve_instance"].set_point_in(idx, b)
								c.image[J]["control_points"][2 * idx + 1] = p
					else:
						if extracted[1] == "9" or extracted[1] == "10": # arc control
							var new_angle : float = get_angle_from_center(c.image[J]["position"]+ 0.5*c.image[J]["size"])
							new_angle -= c.image[J]["rotation"]
							if extracted[1] == "9":
								c.image[J]["startAngle"] = new_angle
							else:
								c.image[J]["endAngle"] = new_angle
						else:
							var hdl : HANDLES = str_to_handle(extracted[1])
							var nnew : Rect2 = modify_rect(Rect2(c.image[J]["position"], c.image[J]["size"]), get_global_mouse_position(), deg_to_rad(c.image[J]["rotation"]), hdl)
							c.image[J]["size"] = nnew.size
							c.image[J]["position"] = nnew.position
			c.queue_redraw()
		MAIN.ROTSTART:
			main_state = MAIN.ROTATING
			if c.selected.size() == 1:
				c.rot_in_progress = T
				c.rotation_center = c.image[ c.selected[0]]["position"] + 0.5 * c.image[c.selected[0]]["size"]
			if not mouse_left_down:
				main_state = MAIN.IDLE
				c.rot_in_progress = F
				c.rotated_id = -1
				style.update()
		MAIN.ROTATING:
			var angle : float = get_angle_from_center(c.rotation_center)
			if c.selected.size() > 0:
				if c.rotated_id != -1:
					c.image[c.rotated_id]["rotation"] = angle
			c.queue_redraw()

func drag_shape(id: int, distance : Vector2) -> void:
	if c.image[id]["type"] in [global.S.line, global.S.arrow]:
		c.image[id]["points"][0] += distance
		c.image[id]["points"][1] += distance
	elif c.image[id]["type"] == global.S.polyline:
		for i in range(c.image[id]["points"].size()):
			c.image[id]["points"][i] += distance
	else:
		c.image[id]["position"] += distance

func get_angle_from_center(center : Vector2) -> float:
	# Calculates the angle in degrees from a center point to the mouse position, 
	# counterclockwise from the up vector.
	var mouse_pos : Vector2 = get_global_mouse_position()
	var direction : Vector2 = (mouse_pos - center).normalized()
	var ret : float = rad_to_deg(Vector2.UP.angle_to(direction))
	ret = fmod(ret, 360)
	if ret < 0:
		ret += 360
	return ret

func end_dragging() -> void:
	c.update_guides()
	main_state = MAIN.IDLE
	c.id_being_dragged = -1
	c.drag_handle = F
	c.inside_handle = "0"
	sum_relative_x = 0
	sum_relative_y = 0
	style.update()

func end_selecting() -> void:
	is_selecting = F
	c.select_rectnagle_content(selection_start, selection_end)
	queue_redraw()
	main_state = MAIN.IDLE

func handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		dragging = F
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)
		
	# zoom
	if touch_points.size() == 2:
		var touch_point_positions = touch_points.values()
		start_distance = touch_point_positions[0].distance_to(touch_point_positions[1])
		start_angle = get_angle(touch_point_positions[0], touch_point_positions[1])
		start_zoom = zoom
	elif touch_points.size() < 2:
		start_distance = 0

func handle_drag(event: InputEventScreenDrag) -> void:
	dragging = T
	touch_points[event.index] = event.position
	if touch_points.size() == 1:
		if can_pan:
			var pan_vector = event.relative.rotated(rotation) * pan_speed
			position -= pan_vector
			limit_offset()
	elif touch_points.size() == 2:
		var touch_point_positions = touch_points.values()
		var current_distance = touch_point_positions[0].distance_to(touch_point_positions[1])
		current_angle = get_angle(touch_point_positions[0], touch_point_positions[1])
		var zoom_factor = start_distance / current_distance
		if can_zoom:
			zoom = start_zoom / zoom_factor
		if can_rotate:
			rotation -= (current_angle - start_angle) * rotate_speed
			start_angle = current_angle
		limit_zoom(zoom)

func zoom_camera(zoom_factor : float, mouse_position : Vector2) -> void:
	if not c.mouse_in_canvas:
		return
	zoom += zoom * zoom_factor
	limit_zoom(zoom)
	var new_mouse_pos = get_global_mouse_position()
	offset += mouse_position - new_mouse_pos
	editor.update_zoom_label(zoom.x)
	c.queue_redraw()

func clamp_vector(vec: Vector2, min_val: float, max_val: float) -> Vector2:
	return Vector2(
		clamp(vec.x, min_val, max_val),
		clamp(vec.y, min_val, max_val)
	)

func limit_offset() -> void:
	offset = clamp_vector(offset, -OFFSET_LIMIT, OFFSET_LIMIT)

func limit_zoom(new_zoom: Vector2) -> void:
	zoom = clamp_vector(new_zoom, MIN_ZOOM, MAX_ZOOM)
	
func str_to_handle(input_string: String) -> HANDLES:
	var handle_map = {
		"0": HANDLES.ROT,
		"1": HANDLES.TOP_LEFT,
		"2": HANDLES.TOP_CENTER,
		"3": HANDLES.TOP_RIGHT,
		"4": HANDLES.LEFT,
		"5": HANDLES.RIGHT,
		"6": HANDLES.BOTTOM_LEFT,
		"7": HANDLES.BOTTOM_CENTER,
		"8": HANDLES.BOTTOM_RIGHT,
	}
	return handle_map.get(input_string, null)

func get_angle(p1 : Vector2, p2 : Vector2) -> float:
	var delta : Vector2 = p2 - p1
	return fmod((atan2(delta.y, delta.x) + PI), (2 * PI))

func _draw() -> void:
	if is_selecting:
		draw_selection_rectangle()

func draw_selection_rectangle() -> void:
	if not laser.active:
		var adjusted_rect: Rect2 = selection_rect
		adjusted_rect.position -= position
		draw_rect(adjusted_rect, RECT_FILL_COLOR)
		draw_rect(adjusted_rect, RECT_OUTLINE_COLOR, F, OUTLINE_THICKNESS)
