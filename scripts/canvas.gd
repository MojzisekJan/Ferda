extends Node2D

# Drawing functions

const VZERO : Vector2 = Vector2(0, 0)
const F : bool = false
const T : bool = true
const SIZELESS : Array[global.S] = [global.S.line, global.S.arrow, global.S.polyline, global.S.curve]
const POL_CURVE : Array[global.S] = [global.S.polyline, global.S.curve]
const CONCAVE : Array[global.S] = [global.S.or_gate, global.S.xor_gate, global.S.star, global.S.heart, global.S.nor_gate]
const HOVER_COLOR : Color = Color("008cf2")


@export var control     : Control
@export var style       : Panel
@export var camera      : Camera2D
@export var tool_panel  : Panel
@export var grid_toggle : CheckButton
@export var bg_picker   : ColorPickerButton

var grid_size        : int = 20
var id_being_dragged : int = -1
var rotated_id       : int = -1
var id               : int = 0
var page_size        : Vector2 = Vector2(2000, 2000)
var rotation_center  : Vector2 = VZERO
var h_guide_a        : Vector2 = VZERO
var h_guide_b        : Vector2 = VZERO
var v_guide_a        : Vector2 = VZERO
var v_guide_b        : Vector2 = VZERO
var image            : Dictionary = {}
var clipboard        : Dictionary = {}
var text_font        : Font = ThemeDB.fallback_font
var inside_handle    : String = "0"
var last_handle      : String = ""
var hovered          : Array[int] = []
var selected         : Array[int] = []
var zindex           : Array[int] = []
var h_guides         : Array[float] = []
var v_guides         : Array[float] = []
var display_grid     : bool = T
var drag_handle      : bool = F
var mouse_in_canvas  : bool = F
var in_handle        : bool = F
var inside_rotate    : bool = F
var y_guide_active   : bool = F
var x_guide_active   : bool = F
var rot_in_progress  : bool = F

func _ready():
	RenderingServer.set_default_clear_color(bg_picker.color)

func get_new_id() -> int:
	id += 1
	return id

@rpc("any_peer", "call_local", "reliable")
func add_shape(object_type : global.S) -> void:
	var newid : int = get_new_id()
	zindex.append(newid)
	var new_shape : Dictionary
	var center_position : Vector2 = snapped(camera.position, Vector2(grid_size, grid_size))
	match object_type:
		global.S.rectangle:
			new_shape = {
				"position": center_position, "size": Vector2(100, 100),
				"border": T,
				"rounded": T,
				"corner_radius": 4.0,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.table:
			new_shape = {
				"position": center_position, "size": Vector2(400, 400),
				"border": T,
				"rows": 3, "cols": 3,
				"filled": F,
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
				"corner_radius": 0.0,
			}
		global.S.image:
			var img : Resource = load("res://image.png")
			new_shape = {
				"position": center_position, "size": img.get_size(),
				"path": "",
				"texture": img,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.polyline:
			new_shape = {
				"position": center_position,
				"closed": F,
				"filled": F,
				"points": [],
			}
		global.S.line, global.S.arrow:
			new_shape = {
				"points": [center_position - Vector2(100,100), center_position + Vector2(100,100)],
				"start": global.ATERM.CIRCLE,
				"end": global.ATERM.LINE_ARROW,
				"antialliased": false,
				"term_size": 16, 
				"filled": F,
			}
		global.S.curve:
			new_shape = {
				"position": center_position,
				"control_points": [],
				"filled": F,
				"closed": F,
				"curve_instance": Curve2D.new(),
			}
		global.S.arc:
			new_shape = {
				"start_angle": 90.0,
				"end_angle": 44.0,
				"position": center_position, "size": Vector2(200, 200),
				"pie": F,
				"border": T,
				"closed": F,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.circle:
			new_shape = {
				"position": center_position, "size": Vector2(100, 100),
				"border": T,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.and_gate, global.S.or_gate, global.S.buffer, global.S.invertor, global.S.nand_gate, global.S.nor_gate, global.S.xor_gate, global.S.sine:
			new_shape = {
				"position": center_position, "size": Vector2(100, 80),
				"border": T,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.diode, global.S.ground:
			new_shape = {
				"position": center_position, "size": Vector2(40, 40),
				"border": T,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.capacitor, global.S.resistor, global.S.inductor:
			new_shape = {
				"position": center_position, "size": Vector2(20, 60),
				"border": T,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.pnp, global.S.npn:
			new_shape = {
				"position": center_position, "size": Vector2(30, 30),
				"border": T,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.nmos, global.S.pmos:
			new_shape = {
				"position": center_position, "size": Vector2(30, 30),
				"border": T,
				"filled": F,
				"bulk": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.node:
			new_shape = {
				"position": center_position, "size": Vector2(7, 7),
			}
		global.S.text:
			new_shape = {
				"text": "Text",
				"position": center_position, "size": Vector2(100, 20),
				"border": F,
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.triangle, global.S.orthogonalTriangle, global.S.hexagon, global.S.parallelogram, global.S.trapezoid, global.S.heart:
			new_shape = {
				"position": center_position, "size": Vector2(100, 100),
				"border": T,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.drop:
			new_shape = {
				"position": center_position, "size": Vector2(100, 150),
				"border": T,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
		global.S.diamond:
			new_shape = {
				"position": center_position, "size": Vector2(100, 100),
				"border": T,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
				"corner_radius": 4.0,
			}
			
		global.S.ngon:
			new_shape = {
				"position": center_position, "size": Vector2(100, 100),
				"border": T,
				"sides": 5,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}

		global.S.star:
			new_shape = {
				"position": center_position, "size": Vector2(100, 100),
				"inner_ratio": 0.5,
				"border": T,
				"sides": 5,
				"filled": F,
				"text": "",
				"font_size": 20.0,
				"text_color": Color(1, 1, 1),
			}
			
	new_shape["type"] = object_type
	new_shape["locked"] = F
	new_shape["antialiased"] = F
	new_shape["group"] = -1
	new_shape["opacity"] = 1.0
	new_shape["rotation"] = 0.0
	new_shape["border_width"] = 1.0
	new_shape["color"] = Color.WHITE
	new_shape["border_color"] = Color.WHITE
	new_shape["fill_color"] = Color.DARK_GRAY
	new_shape["visible"] = T
	new_shape["chache"] = {}
	new_shape["line"] = Line2D.new()
	new_shape["line"].begin_cap_mode = Line2D.LineCapMode.LINE_CAP_BOX
	new_shape["line"].end_cap_mode = Line2D.LineCapMode.LINE_CAP_BOX
	new_shape["line"].name = str(newid) + "_line"

	add_child(new_shape["line"])

	deselect_all()
	
	edit_image("add", [newid], new_shape)
	#image[newid] = new_shape
	#global.undoStack.push_front({
		#"action": global.ACTION.ADD_SHAPE,
		#"is": newid
	#})
	
	add_collider(new_shape, str(newid))
	select_id(newid)
	queue_redraw()

func _draw():
	if display_grid:
		draw_grid(Color(0.15, 0.15, 0.15), Color(0.2, 0.2, 0.2))
	#var start : int = Time.get_ticks_usec()
	draw_image()
	draw_tools()
	if y_guide_active:
		draw_line(v_guide_a, v_guide_b, Color.ORANGE)
	if x_guide_active:
		draw_line(h_guide_a, h_guide_b, Color.ORANGE)
	#var end : int = Time.get_ticks_usec()
	#print((start-end))

func z_index_up() -> void:
	# Shifts the z-index of the selected objects up (right) by 1.
	# The 0 item in the zindex array is drawn first (at the bottom),
	# and the last item is drawn at the top.
	# To move an item up, we swap it with the next element (shift th right).
	var was_unselected : bool = F
	var end : int = zindex.size() - 1
	while end >= 0:
		if selected.has(zindex[end]):
			# Do not shift until all are selected from the right.
			if was_unselected:
				# shift right
				var temp : int = zindex[end + 1]
				zindex[end + 1] = zindex[end]
				zindex[end] = temp
		else:
			was_unselected = T
		end -= 1
	queue_redraw()

func z_index_lower() -> void:
	# Shift the z-index of the selected objects down (left) by 1.
	# The 0 item in the zindex array is drawn first (at the bottom),
	# and the last item is drawn at the top.
	# To move an item down, we swap it with the previous element.
	for selected_id in selected:
		var selected_index : int = zindex.find(selected_id)
		if selected_index == -1:
			continue  # Skip if the ID is not found in zindex
		if selected_index > 0:
			var prev_index : int = zindex[selected_index - 1]
			zindex[selected_index - 1] = selected_id
			zindex[selected_index] = prev_index
	queue_redraw()

func z_index_to_side(bottom : bool) -> void:
	# Moves selected objects to top or bottom in the zindex Array.
	var order : Array[int] = []
	# 1. get selected IDs from zindex in correct order
	for idd in zindex:
		if selected.has(idd):
			order.append(idd)
	# 2. delete selected IDs from zindex
	for idd in order:
		zindex.erase(idd)
	# 3. reverse the order for pushing to front
	if bottom:
		order.reverse()
	# 4. push selected IDs in correct order to zindex
	if bottom: # check once
		for idd in order:
			zindex.push_front(idd)
	else:
		for idd in order:
			zindex.push_back(idd)
	queue_redraw()

func rotate_shape(angle : float) -> void:
	for shape in selected:
		image[shape]["rotation"] += angle
	queue_redraw()

func draw_dimensions_string(siz : Vector2, pos : Vector2) -> void:
	var text : String = str(snapped(siz.x, 0.01)) + " x " + str(snapped(siz.y, 0.01))
	var string_width : int = 75
	var string_height : int = 16
	var string_position : Vector2 = Vector2(
		pos.x + siz.x * 0.5 - string_width * 0.5, 
		pos.y + siz.y + 2.0 * string_height)
	draw_string(text_font, string_position, text)

func draw_image() -> void:
	# Drawing image without controls
	var clr : Color = Color.WHITE
	for a in zindex:
		if not image[a]["visible"]:
			continue
		clr = image[a]["color"]
		if hovered.size() > 0:
			if a == hovered[0]: # and hovered.find(a) == 0:
				clr = Color("008cf2")
		clr.a = image[a]["opacity"]
		
		var fill : Color = image[a]["fill_color"]
		fill.a = image[a]["opacity"]
		
		var col : Object
		var father : String # handles father
		# colliders
		if a in selected:
			if image[a]["type"] in POL_CURVE:
				col = get_node_or_null(str(a) + "x0")
			else:
				col = get_node_or_null(str(a))
			if col == null:
				print("ERROR col = null")
				return
			father = str(a) + "_"
			# Change handles colliders size according to camera zoom and shape size
			var children : Array[Node] = get_node_or_null(father).get_children()
			if children == null:
				print("Error in draw_image var children")
				return
			var xy : float = (1.0 / camera.zoom.x) * 16.0
			if image[a]["type"] in POL_CURVE:
				for z in children:
					z.get_child(0).shape.size = Vector2(xy, xy)
			else:
				for z in children:
					var shape_name : PackedStringArray = z.name.split("_")
					var extracted_name : int = int(shape_name[1])
					if extracted_name == 2 or extracted_name == 7:
						var handle_width_x : float = image[a]["size"].x - 2.0 * xy
						if handle_width_x < 0:
							handle_width_x = 0
						z.get_child(0).shape.size = Vector2(handle_width_x, xy)
					elif extracted_name == 4 or extracted_name == 5:
						var handle_width_y : float = image[a]["size"].y - 2.0 * xy
						if handle_width_y < 0:
							handle_width_y = 0
						z.get_child(0).shape.size = Vector2(xy, handle_width_y)
					elif extracted_name == 9 or extracted_name == 10:
						z.get_child(0).shape.size = Vector2(xy, xy) * 1.2
					else:
						z.get_child(0).shape.size = Vector2(xy, xy)
			
			# Display dimensions when resizing
			if id_being_dragged != -1 and image[id_being_dragged]["type"] not in SIZELESS:
				draw_dimensions_string(image[id_being_dragged]["size"], image[id_being_dragged]["position"])
		
		var half : Vector2
		var center : Vector2
		var collider_points : PackedVector2Array
		
		if image[a]["type"] not in SIZELESS:
			half = image[a]["size"] / 2.0
			center = image[a]["position"] + half
			draw_set_transform_matrix(get_shape_transform(center, image[a]["rotation"]))
		
		# Update Line2D here, because Line2D is for drawing and not data storage. 
		# It is also for points + center chache.
		update_shape_line_2d(a)

		match image[a]["type"]:
			global.S.table:
				draw_table(image[a]["rows"], image[a]["cols"], image[a]["position"], image[a]["size"], image[a]["border"], image[a]["corner_radius"] , image[a]["border_width"], clr)
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.line:
				if a in selected:
					col.position = 0.5 * (image[a]["points"][1] + image[a]["points"][0])
					var lenght : float = image[a]["points"][1].distance_to(image[a]["points"][0])
					var width : float =  image[a]["border_width"] + 10
					col.get_child(0).shape.size = Vector2(width, lenght)
					var dd : Vector2 = image[a]["points"][1] - image[a]["points"][0]
					var angle : float = atan2(dd.x, dd.y)
					col.rotation = -angle
					draw_controls(a, image[a]["type"], VZERO, VZERO, image[a]["points"])
			global.S.polyline:
				if image[a]["points"].size() == 0:
					continue
				elif image[a]["points"].size() == 1:
					draw_circle(image[a]["points"][0], -1, clr)
					continue
				elif image[a]["closed"] and image[a]["filled"]:
					image[a]["points"].append(image[a]["points"][0])
					draw_polygon(image[a]["points"], [image[a]["fill_color"]])
					image[a]["points"].pop_back()

				if a in selected:
					update_line_colliders(a)
					col.position = 0.5 * (image[a]["points"][1] + image[a]["points"][0])
					var lenght : float = image[a]["points"][1].distance_to(image[a]["points"][0])
					var width : float =  image[a]["border_width"] + 10
					col.get_child(0).shape.size = Vector2(width, lenght)
					var dif : Vector2 = image[a]["points"][1] - image[a]["points"][0]
					var angle : float = atan2(dif.x, dif.y)
					col.rotation = -angle
					draw_controls(a, image[a]["type"], VZERO, VZERO, image[a]["points"])
			global.S.curve:
				var anchors : PackedVector2Array = get_curve_anchors(a)
				if anchors.size() == 0:
					continue
				elif anchors.size() == 1:
					draw_circle(anchors[0], -1, clr)
					continue
				if image[a]["closed"]:
					anchors.append(anchors[0])
					draw_polyline(anchors, clr, image[a]["border_width"], image[a]["antialiased"])
					if image[a]["filled"]:
						draw_polygon(anchors, [image[a]["fill_color"]])
					anchors.remove_at(anchors.size() - 1)
				else:
					var points : PackedVector2Array = image[a]["curve_instance"].tessellate(6, 3)
					draw_polyline(points, clr, image[a]["border_width"], image[a]["antialiased"])
				if a in selected:
					update_line_colliders(a)
					draw_controls(a, image[a]["type"], VZERO, VZERO, anchors)
					# Draw control points
					var t : int = 0
					
					#var curve_control_points : Array
					#for i in range(image[a]["curve_instance"].get_point_count()):
						##var anchor = image[a]["curve_instance"].get_point_position(i)
						#var control_in = image[a]["curve_instance"].get_point_in(i)
						#curve_control_points.append(control_in)
						#var control_out = image[a]["curve_instance"].get_point_out(i)
						#curve_control_points.append(control_out)
					# tady asi vzdycky pricist dany anchor point
		
					for point in image[a]["control_points"]:
						if t == 1 or t == image[a]["control_points"].size() - 2:
							t = t + 1
							continue
						draw_circle(point, 5, Color.CORAL)
						draw_line(point, anchors[t / 2], Color.CORAL)
						t = t + 1
			global.S.arc:
				var start_angle : float = deg_to_rad(image[a]["start_angle"])
				var end_angle : float = deg_to_rad(image[a]["end_angle"])
				var pts : PackedVector2Array = shapes.get_arc_points(start_angle, end_angle, half, image[a]["pie"])
				image[a]["line"].set_points(pts)
				if image[a]["border"] and image[a]["border_width"] > 0:
					#if image[a]["closed"] or image[a]["pie"]:
					#	pts.append(pts[0])
					#draw_polyline(pts, clr, image[a]["border_width"], image[a]["antialiased"])
					if image[a]["filled"]:
						draw_polygon(pts, [image[a]["fill_color"]])
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
					start_angle = deg_to_rad(image[a]["start_angle"] - 90)
					end_angle = deg_to_rad(image[a]["end_angle"] - 90)
					var start : Vector2 = center + Vector2(half.x * cos(start_angle), half.y * sin(start_angle))
					var end : Vector2 = center + Vector2(half.x * cos(end_angle), half.y * sin(end_angle))
					draw_circle(start, 5, Color.CORAL, T)
					draw_circle(end, 5, Color.CORAL, T)
			global.S.arrow:
				draw_arrow(image[a], clr, true)
				if a in selected:
					col.position = 0.5 * (image[a]["points"][1] + image[a]["points"][0])
					var lenght : float = image[a]["points"][1].distance_to(image[a]["points"][0])
					var width : float =  image[a]["border_width"] + 10
					col.get_child(0).shape.size = Vector2(width, lenght)
					var dd : Vector2 = image[a]["points"][1] - image[a]["points"][0]
					var angle : float = atan2(dd.x, dd.y)
					col.rotation = -angle
					draw_controls(a, image[a]["type"], VZERO, VZERO, image[a]["points"])
			global.S.text:
				collider_points = shapes.get_rectangle_points(half)
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
				if a in hovered:
					draw_rect(Rect2(image[a]["position"], image[a]["size"]), clr, F, -1)
				if a in selected:
					col.get_child(0).position = center
					get_node(father).position = center
			global.S.image:
				draw_texture_rect(image[a]["texture"], Rect2(image[a]["position"], image[a]["size"]), F)
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.invertor:
				collider_points = shapes.get_buffer_points(half)
				var line_points : PackedVector2Array
				var circle_points : PackedVector2Array = shapes.get_circle_points(Vector2(half.x / 10.0, half.y * (5.0/8.0) / 5.0))
				var real_circle_points : PackedVector2Array
				for point in circle_points:
					var basic_point : Vector2 = point + center
					basic_point.x += half.x * 10.0/9.0
					real_circle_points.append(basic_point)
				for point in collider_points:
					line_points.append(point + center)
				if image[a]["filled"]:
					draw_polygon(line_points, [fill])
				if global.debug_mode:
					for poi in line_points:
						draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
				else:
					if image[a]["border"] and image[a]["border_width"] > 0:
						line_points.append(line_points[0])
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						# circle
						real_circle_points.append(real_circle_points[0])
						draw_polyline(real_circle_points, clr, image[a]["border_width"], image[a]["antialiased"])
					
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
			global.S.nand_gate:
				collider_points = shapes.get_and_gate_points(half)
				var line_points : PackedVector2Array
				var circle_points : PackedVector2Array = shapes.get_circle_points(Vector2(half.x / 10.0, half.y * (5.0/8.0) / 5.0))
				var real_circle_points : PackedVector2Array
				for point in circle_points:
					var basic_point : Vector2 = point + center
					basic_point.x += half.x * 10.0/9.0
					real_circle_points.append(basic_point)
				for point in collider_points:
					line_points.append(point + center)
				if image[a]["filled"]:
					draw_polygon(line_points, [fill])
				if global.debug_mode:
					for poi in line_points:
						draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
				else:
					if image[a]["border"] and image[a]["border_width"] > 0:
						line_points.append(line_points[0])
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						# circle
						real_circle_points.append(real_circle_points[0])
						draw_polyline(real_circle_points, clr, image[a]["border_width"], image[a]["antialiased"])
					
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
			global.S.nor_gate:
				collider_points = shapes.get_or_gate_points(half)
				var line_points : PackedVector2Array
				var circle_points : PackedVector2Array = shapes.get_circle_points(Vector2(half.x / 10.0, half.y * (5.0/8.0) / 5.0))
				var real_circle_points : PackedVector2Array
				for point in circle_points:
					var basic_point : Vector2 = point + center
					basic_point.x += half.x * 10.0/9.0
					real_circle_points.append(basic_point)
				for point in collider_points:
					line_points.append(point + center)
				if image[a]["filled"]:
					draw_polygon(line_points, [fill])
				if global.debug_mode:
					for poi in line_points:
						draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
				else:
					if image[a]["border"] and image[a]["border_width"] > 0:
						line_points.append(line_points[0])
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						# circle
						real_circle_points.append(real_circle_points[0])
						draw_polyline(real_circle_points, clr, image[a]["border_width"], image[a]["antialiased"])
					
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
			global.S.xor_gate:
				collider_points = shapes.get_or_gate_points(half)
				var arc_points : PackedVector2Array = shapes.get_xor_gate_arc_points(half)
				var real_arc_points : PackedVector2Array
				var line_points : PackedVector2Array
				for point in arc_points:
					real_arc_points.append(point + center)
				for point in collider_points:
					line_points.append(point + center)
				if image[a]["filled"]:
					draw_polygon(line_points, [fill])
				if global.debug_mode:
					for poi in line_points:
						draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
				else:
					if image[a]["border"] and image[a]["border_width"] > 0:
						line_points.append(line_points[0])
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						real_arc_points.append(real_arc_points[0])
						draw_polyline(real_arc_points, clr, image[a]["border_width"], image[a]["antialiased"])
					
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
			global.S.diode:
				collider_points = shapes.get_buffer_points(half)
				var line_points : PackedVector2Array
				for point in collider_points:
					line_points.append(point + center)
				if image[a]["filled"]:
					draw_polygon(line_points, [fill])
				if global.debug_mode:
					for poi in line_points:
						draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
				else:
					if image[a]["border"] and image[a]["border_width"] > 0:
						line_points.append(line_points[0])
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						var start : Vector2 = Vector2(half.x, -half.y) + center
						var end : Vector2 = half + center
						draw_line(start, end, clr, image[a]["border_width"], image[a]["antialiased"])
					
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
			global.S.ground:
				if image[a]["border"] and image[a]["border_width"] > 0:
					# top line
					draw_line(center + Vector2(0, -half.y), center, clr, image[a]["border_width"], image[a]["antialiased"])
					# horizontal lines
					draw_line(center + Vector2(-half.x, 0), center + Vector2(half.x, 0), clr, image[a]["border_width"], image[a]["antialiased"])
					draw_line(center + Vector2(-(2.0/3.0)*half.x, (1.0/2.0)*half.y), center + Vector2((2.0/3.0)*half.x, (1.0/2.0)*half.y), clr, image[a]["border_width"], image[a]["antialiased"])
					draw_line(center + Vector2(-(1.0/3.0)*half.x, (5.0/5.0)*half.y), center + Vector2((1.0/3.0)*half.x, (5.0/5.0)*half.y), clr, image[a]["border_width"], image[a]["antialiased"])
					
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
				
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.capacitor:
				if image[a]["border"] and image[a]["border_width"] > 0:
					# top line
					draw_line(center + Vector2(0, -half.y), center + Vector2(0, -half.y/3.0), clr, image[a]["border_width"], image[a]["antialiased"])
					# horizontal lines
					draw_line(center + Vector2(-half.x, -half.y/3.0), center + Vector2(half.x, -half.y/3), clr, image[a]["border_width"], image[a]["antialiased"])
					draw_line(center + Vector2(-half.x, (1.0/3.0)*half.y), center + Vector2(half.x, (1.0/3.0)*half.y), clr, image[a]["border_width"], image[a]["antialiased"])
					# bottom line
					draw_line(center + Vector2(0, half.y/3.0), center + Vector2(0, half.y), clr, image[a]["border_width"], image[a]["antialiased"])
					
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
				
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.node:
				draw_circle(center, image[a]["size"].x, clr)
				if a in selected:
					col.get_child(0).position = center
					collider_points = shapes.get_rectangle_points(half)
					get_node(father).position = center
					col.get_child(0).rotation = deg_to_rad(image[a]["rotation"])
					get_node(father).rotation = deg_to_rad(image[a]["rotation"])
			global.S.resistor:
				if image[a]["border"] and image[a]["border_width"] > 0:
					# top line
					draw_line(center + Vector2(0, -half.y), center + Vector2(0, -half.y*(2.0/3.0)), clr, image[a]["border_width"], image[a]["antialiased"])
					var r_points : PackedVector2Array = shapes.get_rectangle_points(Vector2(image[a]["size"].x / 2.0, (2.0/3.0) * half.y))
					var line_points : PackedVector2Array
					for point in r_points:
						line_points.append(point + center)
					if image[a]["filled"]:
						draw_polygon(line_points, [fill])
					if global.debug_mode:
						for poi in line_points:
							draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
					else:
						line_points.append(line_points[0])
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						
					# bottom line
					draw_line(center + Vector2(0, half.y*(2.0/3.0)), center + Vector2(0, half.y), clr, image[a]["border_width"], image[a]["antialiased"])
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
				
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.inductor:
				if image[a]["border"] and image[a]["border_width"] > 0:
					var rad : Vector2 = Vector2(image[a]["size"].x / 5.0, image[a]["size"].y / 10.0)
					var c_points : PackedVector2Array = shapes.get_arc_points(0, PI, rad, F)
					var line_points : PackedVector2Array
					line_points.append(center + Vector2(0, -half.y))
					for k in range(0, 3):
						for point in c_points:
							var basic : Vector2 = point + Vector2(0, 2.0 * k * image[a]["size"].y / 10.0)
							basic.y -= image[a]["size"].y / 5.0
							line_points.append(basic)
					line_points.append(center +Vector2(0, half.y))
					if image[a]["filled"]:
						draw_polygon(line_points, [fill])
					if global.debug_mode:
						for poi in line_points:
							draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
					else:
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
				
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.nmos:
				if image[a]["border"] and image[a]["border_width"] > 0:
					var gate_h_ratio : float = 2.0 / 3.0 
					var points : PackedVector2Array = [
						Vector2(half.x, -half.y),
						Vector2(half.x, -gate_h_ratio*half.y),
						Vector2(-(3.0/5.0)*half.x, -gate_h_ratio*half.y),
						Vector2(-(3.0/5.0)*half.x, gate_h_ratio*half.y),
						Vector2(half.x, gate_h_ratio*half.y),
						Vector2(half.x, half.y),
					]
					var gate_points : PackedVector2Array = [
						Vector2(-half.x, -gate_h_ratio*half.y),
						Vector2(-half.x, gate_h_ratio*half.y),
					]
					var arrow_points : PackedVector2Array = [
						Vector2(half.x*(1.0/3.0), gate_h_ratio*half.y - half.y/4.0),
						Vector2(half.x, gate_h_ratio*half.y),
						Vector2(half.x*(1.0/3.0), gate_h_ratio*half.y + half.y/4.0),
					]
					var line_points : PackedVector2Array
					var a_points : PackedVector2Array
					for point in points:
						line_points.append(point + center)
					for point in arrow_points:
						a_points.append(point + center)
					if image[a]["filled"]:
						draw_polygon(line_points, [fill])
					if global.debug_mode:
						for poi in line_points:
							draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
					else:
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						# gate
						draw_line(center + gate_points[0], center + gate_points[1], clr, image[a]["border_width"], image[a]["antialiased"])
						# bulk
						if image[a]["bulk"]:
							var b0 : Vector2 = Vector2(-(3.0/5.0)*half.x, 0) + center
							var b1 : Vector2 = Vector2(half.x, 0) + center
							draw_line(b0, b1, clr, image[a]["border_width"], image[a]["antialiased"])
						# arrow
						draw_polyline(a_points, clr, image[a]["border_width"], image[a]["antialiased"])
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
				
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.pmos:
				if image[a]["border"] and image[a]["border_width"] > 0:
					var gate_h_ratio : float = 2.0 / 3.0 
					var points : PackedVector2Array = [
						Vector2(half.x, -half.y),
						Vector2(half.x, -gate_h_ratio*half.y),
						Vector2(-(3.0/5.0)*half.x, -gate_h_ratio*half.y),
						Vector2(-(3.0/5.0)*half.x, gate_h_ratio*half.y),
						Vector2(half.x, gate_h_ratio*half.y),
						Vector2(half.x, half.y),
					]
					var gate_points : PackedVector2Array = [
						Vector2(-half.x, -gate_h_ratio*half.y),
						Vector2(-half.x, gate_h_ratio*half.y),
					]
					var arrow_points : PackedVector2Array = [
						Vector2((1.0/15.0)*half.x, -gate_h_ratio*half.y - half.y/4.0),
						Vector2(-(3.0/5.0)*half.x, -gate_h_ratio*half.y),
						Vector2((1.0/15.0)*half.x, -gate_h_ratio*half.y + half.y/4.0),
					]
					var line_points : PackedVector2Array
					var a_points : PackedVector2Array
					for point in points:
						line_points.append(point + center)
					for point in arrow_points:
						a_points.append(point + center)
					if image[a]["filled"]:
						draw_polygon(line_points, [fill])
					if global.debug_mode:
						for poi in line_points:
							draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
					else:
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						# gate
						draw_line(center + gate_points[0], center + gate_points[1], clr, image[a]["border_width"], image[a]["antialiased"])
						# bulk
						if image[a]["bulk"]:
							var b0 : Vector2 = Vector2(-(3.0/5.0)*half.x, 0) + center
							var b1 : Vector2 = Vector2(half.x, 0) + center
							draw_line(b0, b1, clr, image[a]["border_width"], image[a]["antialiased"])
						# arrow
						draw_polyline(a_points, clr, image[a]["border_width"], image[a]["antialiased"])
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
				
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.pnp:
				if image[a]["border"] and image[a]["border_width"] > 0:
					var gate_h_ratio : float = 2.0 / 3.0 
					var points : PackedVector2Array = [
						Vector2(half.x, -half.y),
						Vector2(half.x, -gate_h_ratio*half.y),
						Vector2(-(3.0/5.0)*half.x, -(3.0/10.0)*half.y),
						Vector2(-(3.0/5.0)*half.x, (3.0/10.0)*half.y),
						Vector2(half.x, gate_h_ratio*half.y),
						Vector2(half.x, half.y),
					]
					var gate_points : PackedVector2Array = [
						Vector2(-half.x+(2.0/5.0)*half.x, -gate_h_ratio*half.y),
						Vector2(-half.x+(2.0/5.0)*half.x, gate_h_ratio*half.y),
					]
					var gate_line : PackedVector2Array = [
						Vector2(-half.x, 0),
						Vector2(-half.x+(2.0/5.0)*half.x, 0),
					]
					var start : Vector2 = Vector2(half.x, -gate_h_ratio*half.y)
					var end : Vector2 = Vector2(-(3.0/5.0)*half.x, -(3.0/10.0)*half.y)
					var direction : Vector2 = (end - start).normalized()
					var v1 : Vector2 = start - (direction.rotated(deg_to_rad(135)) * half.y/2.0)
					var v2 : Vector2 = start - (direction.rotated(deg_to_rad(-135)) * half.y/2.0)
					var arrow_points : PackedVector2Array = [v1, Vector2(-(3.0/5.0)*half.x, -(3.0/10.0)*half.y), v2,]
					var line_points : PackedVector2Array
					var a_points : PackedVector2Array
					for point in points:
						line_points.append(point + center)
					for point in arrow_points:
						a_points.append(point + center)
					if image[a]["filled"]:
						draw_polygon(line_points, [fill])
					if global.debug_mode:
						for poi in line_points:
							draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
					else:
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						# gate
						draw_line(center + gate_points[0], center + gate_points[1], clr, image[a]["border_width"], image[a]["antialiased"])
						draw_line(center + gate_line[0], center + gate_line[1], clr, image[a]["border_width"], image[a]["antialiased"])
						# arrow
						draw_polyline(a_points, clr, image[a]["border_width"], image[a]["antialiased"])
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.npn:
				if image[a]["border"] and image[a]["border_width"] > 0:
					var gate_h_ratio : float = 2.0 / 3.0 
					var points : PackedVector2Array = [
						Vector2(half.x, -half.y),
						Vector2(half.x, -gate_h_ratio*half.y),
						Vector2(-(3.0/5.0)*half.x, -(3.0/10.0)*half.y),
						Vector2(-(3.0/5.0)*half.x, (3.0/10.0)*half.y),
						Vector2(half.x, gate_h_ratio*half.y),
						Vector2(half.x, half.y),
					]
					var gate_points : PackedVector2Array = [
						Vector2(-half.x+(2.0/5.0)*half.x, -gate_h_ratio*half.y),
						Vector2(-half.x+(2.0/5.0)*half.x, gate_h_ratio*half.y),
					]
					var gate_line : PackedVector2Array = [
						Vector2(-half.x, 0),
						Vector2(-half.x+(2.0/5.0)*half.x, 0),
					]
					var start : Vector2 = Vector2(-(3.0/5.0)*half.x, (3.0/10.0)*half.y)
					var end : Vector2 = Vector2(half.x, gate_h_ratio*half.y)
					var direction : Vector2 = (end - start).normalized()
					var v1 : Vector2 = start - (direction.rotated(deg_to_rad(135)) * half.y/2.0)
					var v2 : Vector2 = start - (direction.rotated(deg_to_rad(-135)) * half.y/2.0)
					var arrow_points : PackedVector2Array = [v1, Vector2(half.x, gate_h_ratio*half.y), v2,]
					var line_points : PackedVector2Array
					var a_points : PackedVector2Array
					for point in points:
						line_points.append(point + center)
					for point in arrow_points:
						a_points.append(point + center)
					if image[a]["filled"]:
						draw_polygon(line_points, [fill])
					if global.debug_mode:
						for poi in line_points:
							draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
					else:
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
						# gate
						draw_line(center + gate_points[0], center + gate_points[1], clr, image[a]["border_width"], image[a]["antialiased"])
						draw_line(center + gate_line[0], center + gate_line[1], clr, image[a]["border_width"], image[a]["antialiased"])
						# arrow
						draw_polyline(a_points, clr, image[a]["border_width"], image[a]["antialiased"])
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			global.S.sine:
				if image[a]["border"] and image[a]["border_width"] > 0:
					var line_points : PackedVector2Array
					var points : PackedVector2Array = shapes.get_sine_points(half)
					for point in points:
						line_points.append(point + center)
					if global.debug_mode:
						for poi in line_points:
							draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
					else:
						draw_polyline(line_points, clr, image[a]["border_width"], image[a]["antialiased"])
				if a in selected:
					collider_points = shapes.get_rectangle_points(half)
			_:
				var line_points : PackedVector2Array
				
				match image[a]["type"]:
					global.S.rectangle:
						if image[a]["rounded"] == T and image[a]["corner_radius"] > 2:
							collider_points = shapes.get_rounded_rectangle_points(half, image[a]["corner_radius"])
						else:
							collider_points = shapes.get_rectangle_points(half)
					global.S.circle:
						collider_points = shapes.get_circle_points(half)
					global.S.and_gate:
						collider_points = shapes.get_and_gate_points(half)
					global.S.or_gate:
						collider_points = shapes.get_or_gate_points(half)
					global.S.triangle:
						collider_points = shapes.get_triangle_points(half)
					global.S.orthogonalTriangle:
						collider_points = shapes.get_orthogonalTriangle_points(half)
					global.S.diamond:
						collider_points = shapes.get_diamond_points(half, image[a]["corner_radius"])
					global.S.hexagon:
						collider_points = shapes.get_hexagon_points(half)
					global.S.drop:
						collider_points = shapes.get_drop_points(half)
					global.S.parallelogram:
						collider_points = shapes.get_parallelogram_points(half)
					global.S.trapezoid:
						collider_points = shapes.get_trapezoid_points(half)
					global.S.ngon:
						collider_points = shapes.get_ngon_points(half, image[a]["sides"])
					global.S.star:
						collider_points = shapes.get_star_points(image[a]["size"], image[a]["sides"], image[a]["inner_ratio"])
					global.S.heart:
						collider_points = shapes.get_heart_points(half)
					global.S.buffer:
						collider_points = shapes.get_buffer_points(half)

				image[a]["line"].set_points(collider_points)		

				for point in collider_points:
					line_points.append(point + center)

				image[a]["line"].closed = true

				if image[a]["filled"]:
					draw_polygon(line_points, [fill])
				if global.debug_mode:
					for poi in line_points:
						draw_circle(poi, 2, Color(1, 1, 1, 0.5), 1)
					
				draw_text_to_rect(image[a]["text"], image[a]["size"], image[a]["position"], image[a]["font_size"], image[a]["text_color"])
		
		draw_set_transform(VZERO, 0, Vector2(1, 1))
		
		if image[a]["type"] not in SIZELESS and a in selected:
			if image[a]["type"] in CONCAVE:
				collider_points = shapes.get_rectangle_points(half) # convex
			col.get_child(0).shape.points = collider_points
		
		# Update handles position
		if image[a]["type"] == global.S.polyline:
			var i : int = 0
			for h in get_tree().get_nodes_in_group(str(a)):
				h.position = image[a]["points"][i]
				i = i + 1
		elif image[a]["type"] == global.S.curve:
			var i : int = 0
			var j : int = image[a]["curve_instance"].get_point_count()
			var anchors : PackedVector2Array = get_curve_anchors(a)
			for h in get_tree().get_nodes_in_group(str(a)):
				if i < j: # anchor handle
					h.position = anchors[i]
				else: # control point
					h.position = image[a]["control_points"][i - j]
				i = i + 1
		else:
			for h in get_tree().get_nodes_in_group(str(a)):
				var parts : PackedStringArray = h.name.split("_")
				match parts[1]:
					"0":
						if image[a]["type"] == global.S.line or image[a]["type"] == global.S.arrow:
							h.position = image[a]["points"][0]
						else:
							h.position = Vector2(0, -50.0  * (1.0 / camera.zoom.x) - half.y)
					"1":
						if image[a]["type"] == global.S.line or image[a]["type"] == global.S.arrow:
							h.position = image[a]["points"][1]
						else:
							h.position = -half
					"2":
						h.position = Vector2(0, -half.y)
					"3":
						h.position = Vector2(half.x, -half.y)
					"4":
						h.position = Vector2(-half.x, 0)
					"5":
						h.position = Vector2(half.x, 0)
					"6":
						h.position = Vector2(-half.x, half.y)
					"7":
						h.position = Vector2(0, half.y)
					"8":
						h.position = half
					"9":
						if image[a]["type"] == global.S.arc:
							var start_angle : float = deg_to_rad(image[a]["start_angle"] - 90)
							h.position = Vector2(half.x * cos(start_angle), half.y * sin(start_angle))
					"10":
						if image[a]["type"] == global.S.arc:
							var end_angle : float = deg_to_rad(image[a]["end_angle"] - 90)
							h.position = Vector2(half.x * cos(end_angle), half.y * sin(end_angle))


func update_shape_line_2d(shape_id : int) -> void:
	var line : Object = get_node_or_null(str(shape_id) + "_line")
	if line:
		if image[shape_id].has("position") and image[shape_id].has("size"):
			line.position = image[shape_id]["position"] + image[shape_id]["size"] / 2.0
		if image[shape_id].has("points"):
			line.set_points(image[shape_id]["points"])
		if image[shape_id].has("antialiased"):
			line.antialiased = image[shape_id]["antialiased"]
		if image[shape_id].has("border_width"):
			line.width = image[shape_id]["border_width"]
		if image[shape_id].has("closed"):
			line.closed = image[shape_id]["closed"]
		if image[shape_id].has("rotation"):
			line.rotation = deg_to_rad(image[shape_id]["rotation"])
		if image[shape_id].has("border_color"):
			var border_color : Color = image[shape_id]["border_color"]
			border_color.a = image[shape_id]["opacity"]
			if hovered.size() > 0:
				if shape_id == hovered[0]:
					border_color = HOVER_COLOR
			else:
				border_color.a = image[shape_id]["opacity"]
			line.default_color = border_color
		if image[shape_id].has("border"):
			line.visible = image[shape_id]["border"]
		

func draw_arrow(arrow : Dictionary, clr : Color, draw_ends : bool = true) -> void:
	var start : Vector2 = arrow["points"][0]
	var end : Vector2 = arrow["points"][1]
	# This shouldn't always be calculated when drawing!
	# Calculate the direction from start to end
	if draw_ends:
		var direction : Vector2 = (end - start).normalized()
		# Draw arrow start
		match arrow["start"]:
			global.ATERM.NONE:
				pass
			global.ATERM.LINE_ARROW:
				var v1 : Vector2 = start - (direction.rotated(deg_to_rad(135)) * arrow["term_size"])
				var v2 : Vector2 = start - (direction.rotated(deg_to_rad(-135)) * arrow["term_size"])
				draw_polyline([v1, start, v2], clr, arrow["border_width"], arrow["antialiased"])
			global.ATERM.FULL_ARROW:
				var v1 : Vector2 = start - (direction.rotated(deg_to_rad(135)) * arrow["term_size"])
				var v2 : Vector2 = start - (direction.rotated(deg_to_rad(-135)) * arrow["term_size"])
				draw_polygon([v1, start, v2], [clr])
			global.ATERM.CIRCLE:
				draw_circle(start, arrow["term_size"] / 2.0, clr, F, arrow["border_width"])
			global.ATERM.LINE:
				var v1 : Vector2 = start - (direction.rotated(deg_to_rad(90)) * arrow["term_size"])
				var v2 : Vector2 = start - (direction.rotated(deg_to_rad(-90)) * arrow["term_size"])
				draw_polyline([v1, v2], clr, arrow["border_width"], arrow["antialiased"])
			global.ATERM.RECTANGLE:
				draw_rect(Rect2(start - Vector2(arrow["term_size"] / 2.0, arrow["term_size"] / 2.0), Vector2(arrow["term_size"], arrow["term_size"])), clr, F, arrow["border_width"])
		# Draw arrow end
		match arrow["end"]:
			global.ATERM.NONE:
				pass
			global.ATERM.LINE_ARROW:
				var v1 : Vector2 = end - (direction.rotated(deg_to_rad(45)) * arrow["term_size"])
				var v2 : Vector2 = end - (direction.rotated(deg_to_rad(-45)) * arrow["term_size"])
				draw_polyline([v1, end, v2], clr, arrow["border_width"], arrow["antialiased"])
			global.ATERM.FULL_ARROW:
				var v1 : Vector2 = end - (direction.rotated(deg_to_rad(45)) * arrow["term_size"])
				var v2 : Vector2 = end - (direction.rotated(deg_to_rad(-45)) * arrow["term_size"])
				draw_polygon([v1, end, v2], [clr])
			global.ATERM.CIRCLE:
				draw_circle(end, arrow["term_size"] / 2.0, clr, F, arrow["border_width"])
			global.ATERM.LINE:
				var v1 : Vector2 = end - (direction.rotated(deg_to_rad(90)) * arrow["term_size"])
				var v2 : Vector2 = end - (direction.rotated(deg_to_rad(-90)) * arrow["term_size"])
				draw_polyline([v1, v2], clr, arrow["border_width"], arrow["antialiased"])
			global.ATERM.RECTANGLE:
				draw_rect(Rect2(end - Vector2(arrow["term_size"] / 2.0, arrow["term_size"] / 2.0), Vector2(arrow["term_size"], arrow["term_size"])), clr, F, arrow["border_width"])
	# Arrow middle part
	draw_line(start, end, clr, arrow["border_width"], arrow["antialiased"])
	#if a in selected:
		#col.position = 0.5 * (arrow["points"][1] + arrow["points"][0])
		#var lenght : float = arrow["points"][1].distance_to(arrow["points"][0])
		#var width : float =  arrow["border_width"] + 10
		#col.get_child(0).shape.size = Vector2(width, lenght)
		#var dd : Vector2 = arrow["points"][1] - arrow["points"][0]
		#var angle : float = atan2(dd.x, dd.y)
		#col.rotation = -angle
		#draw_controls(a, arrow["type"], VZERO, VZERO, arrow["points"])


func draw_tools() -> void:
	# Drawing handles, control points and other tool related shapes
	if selected.size() == 0:
		return
	for a in zindex:
		if image[a]["visible"] and a in selected:
			var col # ? type
			var father : String # handles father
			# colliders
			if image[a]["type"] in POL_CURVE:
				col = get_node_or_null(str(a) + "x0")
			else:
				col = get_node_or_null(str(a))
			if col == null:
				print("ERROR: col = null (2)")
				return
			father = str(a) + "_"
			# Change handles colliders size according to camera zoom and shape size
			var s : Object = get_node_or_null(father)
			if s == null:
				print("ERROR: children = null")
				return
			var children : Array = s.get_children()
			var xy : float = (1.0 / camera.zoom.x) * 16.0
			if image[a]["type"] in POL_CURVE:
				for z in children:
					z.get_child(0).shape.size = Vector2(xy, xy)
			else:
				for z in children:
					var shape_name : PackedStringArray = z.name.split("_")
					var extracted_name : int = int(shape_name[1])
					if extracted_name == 2 or extracted_name == 7:
						var handle_width_x : float = image[a]["size"].x - 2.0 * xy
						if handle_width_x < 0:
							handle_width_x = 0
						z.get_child(0).shape.size = Vector2(handle_width_x, xy)
					elif extracted_name == 4 or extracted_name == 5:
						var handle_width_y : float = image[a]["size"].y - 2.0 * xy
						if handle_width_y < 0:
							handle_width_y = 0
						z.get_child(0).shape.size = Vector2(xy, handle_width_y)
					elif extracted_name == 9 or extracted_name == 10:
						z.get_child(0).shape.size = Vector2(xy, xy) * 1.2
					else:
						z.get_child(0).shape.size = Vector2(xy, xy)
						
			if image[a]["type"] not in SIZELESS:
				var half : Vector2 = image[a]["size"] / 2.0
				var center : Vector2 = image[a]["position"] + half
			
				col.get_child(0).position = center
				get_node(father).position = center
				col.get_child(0).rotation = deg_to_rad(image[a]["rotation"])
				get_node(father).rotation = deg_to_rad(image[a]["rotation"])
				
				draw_set_transform_matrix(get_shape_transform(center, image[a]["rotation"]))
				draw_controls(a, image[a]["type"], image[a]["position"], image[a]["size"], [])
				draw_set_transform(VZERO, 0, Vector2(1, 1))
				draw_rotation_angle(center, image[a]["rotation"], Color.SANDY_BROWN)

func draw_text_to_rect(text : String, siz : Vector2, pos : Vector2, font_siz : float, clr : Color) -> void:
	var text_dimensions : Vector2 = text_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, siz.x, font_siz, -1)
	var half_text : float = text_dimensions.y / 2.0
	var padding_top : float = (siz.y / 2.0) - half_text + font_siz
	var text_position : float = padding_top + pos.y
			
	draw_multiline_string(text_font, Vector2(pos.x, text_position), text, HORIZONTAL_ALIGNMENT_CENTER, siz.x, font_siz, -1, clr)

func get_curve_anchors(curve_id : int) -> PackedVector2Array:
	var anchors : PackedVector2Array = []
	for i in range(image[curve_id]["curve_instance"].get_point_count()):
		anchors.append(image[curve_id]["curve_instance"].get_point_position(i))
	return anchors

func get_shape_transform(center : Vector2, angle : float) -> Transform2D:
	var to_center : Transform2D = Transform2D(0, center)
	var rot : Transform2D = Transform2D(deg_to_rad(angle), VZERO)
	var back : Transform2D = Transform2D(0, -center)
	return to_center * rot * back

func draw_rotation_angle(center : Vector2, angle : float, color: Color) -> void:
	if rot_in_progress:
		var angle_rect : Rect2 = Rect2(center - Vector2(10, 20), Vector2(80, 30))
		draw_rect(angle_rect, Color(0, 0, 0, 0.5), T, -1)
		draw_string(text_font, center, str(snapped(angle, 0.01)) + "°", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)

func draw_table(row: int, col : int, pos : Vector2, siz : Vector2, border: bool, corner_radius: float, border_width : float, border_color : Color) -> void:
	# draw background
	
	# draw borders
	if border:
	# around
		if corner_radius > 0:
			var points : PackedVector2Array = shapes.get_rounded_rectangle_points(0.5 * siz, corner_radius)
			var line_points : PackedVector2Array
			var center : Vector2 = pos + 0.5 * siz
			for point in points:
					line_points.append(point + center)
			if border_width > 0:
				line_points.append(line_points[0])
				draw_polyline(line_points, border_color, border_width, T)
		
		else:
			draw_rect(Rect2(pos, siz), border_color, F, border_width, T)
		var line_height : float = siz.y / row
		var col_width : float = siz.x / col
		# draw rows
		for a in range(row - 1):
			draw_line(Vector2(pos.x, pos.y + (a + 1) * line_height),
			Vector2(pos.x + siz.x, pos.y + (a + 1) * line_height), border_color, border_width, T)
		# draw columns
		for b in range(col - 1):
			draw_line(Vector2(pos.x + col_width * (b + 1), pos.y),
			Vector2(pos.x + col_width * (b + 1), pos.y + siz.y), border_color, border_width, T)

func update_line_colliders(a : int) -> void:
	# collide names for polyline with id i:
	# "i" + n * "ixj"
	print("update_line_colliders", a)
	if image[a]["type"] == global.S.curve:
		return
	var number_of_colliders : int
	var ex_array : PackedVector2Array
	if image[a]["type"] == global.S.curve:
		number_of_colliders = image[a]["curve_instance"].get_point_count()
		ex_array = get_curve_anchors(a)
	else:
		number_of_colliders = image[a]["points"].size() - 2
		ex_array = image[a]["points"]
	# go trough nodes
	var col
	
	for q in range(number_of_colliders):
		col = get_node_or_null(str(a) + "x" + str(q + 1))
		if col == null:
			print("ERROR: col = null (3)")
			return
		col.position = 0.5 *(ex_array[q+2] + ex_array[q+1])
		var lenght : float = ex_array[q+2].distance_to(ex_array[q+1])
		var width : float =  image[a]["border_width"] + 10.0
		col.get_child(0).shape.size = Vector2(width, lenght)
		var dd : Vector2 = ex_array[q+2] - ex_array[q+1]
		var angle : float = atan2(dd.x, dd.y)
		col.rotation = -angle

func draw_grid(grid_color_primary : Color, grid_color_secondary : Color) -> void:
	var grid_color : Color = grid_color_primary
	var grd_times_zoom : float = grid_size
	var grid_primary_size : int  = 4 * grid_size
	var end_index : int = int(page_size.x / grd_times_zoom) + 1
	# Vertical Lines
	for i in range(0, end_index):
		if int((i * int(grd_times_zoom)) % grid_primary_size):
			grid_color = grid_color_primary
		else:
			grid_color = grid_color_secondary
		draw_line(Vector2(i * grd_times_zoom, 0), Vector2(i*grd_times_zoom, page_size.y), grid_color)
		
	end_index = int(page_size.y / grd_times_zoom) + 1
		
	# Horizontal Lines
	for i in range(0, end_index):
		if int((i * int(grd_times_zoom)) % grid_primary_size):
			grid_color = grid_color_primary
		else:
			grid_color = grid_color_secondary
		draw_line(Vector2(0, i * grd_times_zoom), Vector2(page_size.x, i * grd_times_zoom), grid_color)

func add_collider(shape : Dictionary, collider_name : String) -> void:
	# Collider for shape movement and hover
	# Always present
	var collider : StaticBody2D = StaticBody2D.new()
	var collision : CollisionShape2D = CollisionShape2D.new()
	var collider_position : Vector2
	
	match shape["type"]:
		global.S.line, global.S.arrow:
			collision.shape = RectangleShape2D.new()
			collider_position = shape["points"][0]
		global.S.polyline, global.S.curve:
			collision.shape = RectangleShape2D.new()
			collider_position = VZERO
		_:
			collision.shape = ConvexPolygonShape2D.new()
			collider_position = VZERO

	collision.debug_color = Color(1,0,0)
	collider.position = collider_position
	
	if shape["type"] in POL_CURVE:
		collider.name = collider_name + "x0"
	else:
		collider.name = collider_name
	
	collider.connect("mouse_entered", Callable(self, "_entered").bind(collider_name))
	collider.connect("mouse_exited", Callable(self, "_exited").bind(collider_name))
	collider.input_pickable = T
	add_child(collider)
	collider.add_child(collision)

func _entered(pas : String) -> void:
	var index : int
	if pas.length() > 1:
		if pas[1] == "x":   # polyline segment handle
			index = int(pas.split("x")[0])
		elif pas[1] == "A": # curve segment handle
			index = int(pas.split("A")[0])
	else:
		index = int(pas)
	if !drag_handle:
		for J in image:
			if J == index:
				hovered.push_back(J)
				sort_hovered_by_z_index()
		queue_redraw()

func sort_hovered_by_z_index() -> void:
	var idx : int = zindex.size() - 1
	var temp : int
	if hovered.size() > 1:  # or > 0?
		while idx >= 0:
			if hovered.has(zindex[idx]):
				temp = zindex[idx]
				break
			idx = idx - 1
		hovered.remove_at(hovered.find(temp))
		hovered.push_front(temp)

func _exited(pas : String) -> void:
	var index : int
	set_resize_cursor("-1", 0.0)
	if pas.length() > 1:
		if pas[1] == "x":   # polyline segment handle
			index = int(pas.split("x")[0])
		elif pas[1] == "A": # curvve segment handle
			index = int(pas.split("A")[0])
	else:
		index = int(pas)
	if hovered.size() > 0:
		for J in image:
			if J == index:
				hovered.remove_at(hovered.find(J))
		if hovered.size() > 0:
			var zero : int = hovered.pop_front()
			hovered.push_front(zero)
	sort_hovered_by_z_index()
	queue_redraw()

func select_id(id_to_select : int) -> void:
	## This is the primary function for selecting objects.
	if not image.has(id_to_select):
		print("ERROR: wrong call of select_id.")
		return
	var type : global.S = image[id_to_select]["type"]
	if selected.has(id_to_select) or image[id_to_select]["locked"]: # return if already selected
		return
	else:
		selected.append(id_to_select)
		# Create 9 Handles: 0 for rotation and 1 to 8 for size
		# + control points for arc shape
		# Handles are for specific shape ID
		# StaticBody2D > CollisionShape2D > RectangleShape2D
		var number_of_handles : int = 9
		match type:
			global.S.line, global.S.arrow:
				number_of_handles = 2
			global.S.polyline:
				number_of_handles = image[id_to_select]["points"].size()
			global.S.curve:
				number_of_handles = image[id_to_select]["curve_instance"].get_point_count() * 3
			global.S.arc:
				number_of_handles = 11
			_:
				pass
		create_handles(id_to_select, number_of_handles)
	# Update style form
	style.update()

func create_handles(handles_id : int, number : int) -> void:
	var father : Node2D = Node2D.new() # parent of all handles
	father.name = str(handles_id) + "_"
	add_child(father)
	
	# no rotation for polyline and curve -> first handle name is: "n_1"
	var t : int = 0
	var o : int = 0
	if image[handles_id]["type"] in POL_CURVE:
		t = 1
	for i in range(0, number):
		var identifier : String = str(handles_id) + "_" + str(t)
		if image[handles_id]["type"] == global.S.curve and i > image[handles_id]["curve_instance"].get_point_count() - 1: # name for controls
			var again : int = t - image[handles_id]["curve_instance"].get_point_count()
			var side : String = "_l"
			if again % 2 == 0:
				side = "_r"
				o = o + 1
			again = again - o
			
			identifier = str(handles_id) + "_" + str(again) + side
		t = t + 1
		if get_node_or_null(identifier):
			continue

		var collider : StaticBody2D = StaticBody2D.new()
		collider.z_index = 3
		collider.name = identifier
		collider.connect("mouse_entered", Callable(self, "_entered_handle").bind(identifier))
		collider.connect("mouse_exited", Callable(self, "_exited_handle").bind(identifier))
		collider.input_pickable = T
		father.add_child(collider)
		var rect_shape = RectangleShape2D.new()
		var ext : float = (1.0 / camera.zoom.x) * 8.0
		rect_shape.extents = Vector2(ext, ext)
		var collision = CollisionShape2D.new()
		collision.shape = rect_shape
		collision.position = VZERO
		if i < 9:
			collision.debug_color = Color(0,1,0)
		else:
			collision.debug_color = Color.ORANGE # for control points (arc)
		collider.add_child(collision)
		collider.add_to_group(str(handles_id))

func _entered_handle(passed : String) -> void:
	in_handle = T
	control.mouse_default_cursor_shape = Control.CursorShape.CURSOR_MOVE
	# mouse entered handle
	if !drag_handle:  # Ignore handles while dragging
		inside_handle = passed
		last_handle = passed
		var new_arr : PackedStringArray = passed.split("_")
		var ary : Array[global.S] = [global.S.line, global.S.arrow]
		set_resize_cursor(new_arr[1], image[int(new_arr[0])]["rotation"])
		if image[int(new_arr[0])]["type"] in ary:
			inside_rotate = F
		elif new_arr[1] == "0":
			inside_rotate = T
			rotated_id = int(new_arr[0])
		else:
			inside_rotate = F
		queue_redraw()

func set_resize_cursor(type : String, angle : float) -> void:
	var cursor : Control.CursorShape = Control.CursorShape.CURSOR_ARROW
	match type:
		"1", "8":
			cursor = Control.CursorShape.CURSOR_FDIAGSIZE
		"3", "6":
			cursor = Control.CursorShape.CURSOR_BDIAGSIZE
		"2", "7":
			cursor = Control.CursorShape.CURSOR_VSIZE
		"4", "5":
			cursor = Control.CursorShape.CURSOR_HSIZE
		_: 
			cursor = Control.CursorShape.CURSOR_ARROW
	cursor = get_cursor_for_angle(cursor, angle)
	control.mouse_default_cursor_shape = cursor

func get_cursor_for_angle(cursor: Control.CursorShape, angle: float) -> Control.CursorShape:
	var cursors : Array[Control.CursorShape] = [ Control.CursorShape.CURSOR_VSIZE,
							Control.CursorShape.CURSOR_FDIAGSIZE,
							Control.CursorShape.CURSOR_HSIZE,
							Control.CursorShape.CURSOR_BDIAGSIZE]
	var index : int = cursors.find(cursor)
	var ret_cursor : Control.CursorShape
	if index >= 0:
		var a : int = int(angle / (PI / 4.0))
		ret_cursor = cursors[(index + a) % cursors.size()]
	return ret_cursor

func _exited_handle(passed : String) -> void:
	set_resize_cursor("-1", 0.0)
	in_handle = F
	last_handle = passed
	if drag_handle:
		return
	else:
		inside_handle = "0"
	queue_redraw()

func delete_poly_colliders(id_to_delete : int, segment_count : int) -> void:
	var number_of_segments : int = segment_count
	for a in range(number_of_segments):
		var node_name : String = str(id_to_delete) + "x" + str(a)
		var node : Object = get_node_or_null(node_name)
		if node:
			node.queue_free()

func delete_id(id_to_delete : int) -> void:
	if image[id_to_delete]["type"] == global.S.polyline:
		delete_poly_colliders(id_to_delete, image[id_to_delete]["points"].size() - 1)
	elif image[id_to_delete]["type"] == global.S.curve:
		delete_poly_colliders(id_to_delete, image[id_to_delete]["curve_instance"].get_point_count() - 1)
	else:
		var collider : Object = get_node_or_null(str(id_to_delete))
		if collider:
			collider.queue_free()
		collider = get_node_or_null(str(id_to_delete) + ("_"))
		if collider:
			collider.queue_free()
	
	# Delete Line2D
	var line : Object = get_node_or_null(str(id_to_delete) + "_line")
	if line:
		line.queue_free()

	# Delete z-index
	image.erase(id_to_delete)
	zindex.erase(id_to_delete)
	style.hide()
	update_guides()

func draw_controls(key: int, type : global.S, pos: Vector2, siz: Vector2, points : Array) -> void:
	var dims : Vector2 = (1.0 / camera.zoom.x) * Vector2(16, 16)
	var half_dims : Vector2 = dims / 2.0
	var half_siz : Vector2 = siz / 2.0
	var col : Color = Color("008cf2")
	var border_color : Color = Color("008cf2")

	if type in SIZELESS:
		if type == global.S.polyline:
			if camera.tool == global.TOOLS.POLYLINE:
				# Draw last polyline orange
				for a in range(points.size()-1):
					draw_rect(Rect2(points[a] - half_dims, dims), col, T, -1)
				draw_rect(Rect2(points[points.size()-1] - half_dims, dims), Color.ORANGE, T, -1)
			else:
				for point in points:
					draw_rect(Rect2(point - half_dims, dims), col, T, -1)
		else:
			for point in points:
				draw_rect(Rect2(point - half_dims, dims), col, T, -1)
	elif type == global.S.curve:
		var anchors : PackedVector2Array = get_curve_anchors(key)
		for point in anchors:
			draw_rect(Rect2(point - half_dims, dims), col, T, -1)
	else:
		# Around
		draw_rect(Rect2(pos, siz), col, F)
		draw_rect(Rect2(pos, siz), border_color, F)
		# Left Top
		draw_rect(Rect2(pos-half_dims, dims), gt(1, key), T)
		draw_rect(Rect2(pos-half_dims, dims), border_color, F)
		# Left Bottom
		draw_rect(Rect2(Vector2(pos.x, pos.y+siz.y)-half_dims, dims), gt(6, key), T)
		draw_rect(Rect2(Vector2(pos.x, pos.y+siz.y)-half_dims, dims), border_color, F)
		# Right Top
		draw_rect(Rect2(Vector2(pos.x+siz.x, pos.y)-half_dims, dims), gt(3, key))
		draw_rect(Rect2(Vector2(pos.x+siz.x, pos.y)-half_dims, dims), border_color, F)
		# Right Bottom
		draw_rect(Rect2(Vector2(pos.x+siz.x, pos.y+siz.y)-half_dims, dims), gt(8, key))
		draw_rect(Rect2(Vector2(pos.x+siz.x, pos.y+siz.y)-half_dims, dims), border_color, F)
		# Rotate
		var h : Vector2 = Vector2(pos.x + half_siz.x, pos.y - (50.0 / camera.zoom.x))
		draw_circle(h, dims.x / 2.0, gt(0, key), T, -1)
		draw_circle(h, dims.x / 2.0, border_color, F, -1)

func gt(a : int, key : int) -> Color:
	# Get handle hover color
	if inside_handle == str(key) + "_" + str(a):
		return Color("7fc5f8")
	else:
		return Color("202020")

func deselect_all() -> void:
	## Deselect all objects
	for i in selected:
		var node : Object = get_node_or_null(str(i) + "_")
		if node:
			node.queue_free() # detele Handles
	selected.clear()
	queue_redraw()

func deselect_id(id_to_delelect : int) -> void:
	## Deselecting objects.
	var node : Object
	if selected.size() > 0:
		node = get_node_or_null(str(id_to_delelect) + "_")
		if node:
			node.queue_free()
		#node = str(id_to_delelect)
	if selected.has(id_to_delelect):
		selected.remove_at(selected.find(id_to_delelect))

func select_all() -> void:
	for J in image:
		select_id(J)
	queue_redraw()

func select_rectnagle_content(start : Vector2, end : Vector2) -> void:
	#print("Start: " + str(start) + " end: " + str(end))
	if start.distance_to(end) < 1.0:
		return
	if global.debug_mode:
		print("Selecting rectangle content.")
	var new_start : Vector2
	var new_end : Vector2
	# selection rectangle:
	if start.x > end.x:
		new_start = end
		new_end = start
	else:
		new_start = start
		new_end = end
	if new_start.y > new_end.y:
		var temp : float = new_start.y
		new_start.y = new_end.y
		new_end.y = temp
	
	var pos_sel_rect : Rect2 = Rect2(new_start, new_end - new_start)
	for J in image:
		match image[J]["type"]:
			global.S.line, global.S.arrow:
				# Both points inside the selection rectangle.
				if pos_sel_rect.has_point(image[J]["points"][0]):
					if pos_sel_rect.has_point(image[J]["points"][1]):
						select_id(J)
			global.S.polyline:
				# All points from the polyline must be inside the selection rectangle.
				var has_all_points : bool = T
				for point in image[J]["points"]:
					if not pos_sel_rect.has_point(point):
						has_all_points = F
				if has_all_points:
					select_id(J)
			global.S.curve:
				# All points from the polyline must be inside the selection rectangle.
				var has_all_points : bool = T
				var anchors : PackedVector2Array = get_curve_anchors(J)
				for point in anchors:
					if not pos_sel_rect.has_point(point):
						has_all_points = F
				if has_all_points:
					select_id(J)
			_:
				# Both position and (position+size) inside the selection rectangle.
				if pos_sel_rect.has_point(image[J]["position"]):
					if pos_sel_rect.has_point(image[J]["position"] + image[J]["size"]):
						select_id(J)
		queue_redraw()

func copy() -> void:
	clipboard.clear()
	for selectedObject in selected:
		clipboard[selectedObject] = image[selectedObject]

func flip_horizontal() -> void:
	for shape in selected:
		if image[shape]["type"] == global.S.line or image[shape]["type"] == global.S.arrow:
			var pt0 : Vector2 = image[shape]["points"][0]
			var pt1 : Vector2 = image[shape]["points"][1]
			image[shape]["points"][0].x = pt1.x
			image[shape]["points"][1].x = pt0.x
	queue_redraw()

func flip_vertical() -> void:
	for shape in selected:
		if image[shape]["type"] == global.S.line or image[shape]["type"] == global.S.arrow:
			var pt0 : Vector2 = image[shape]["points"][0]
			var pt1 : Vector2 = image[shape]["points"][1]
			image[shape]["points"][0].y = pt1.y
			image[shape]["points"][1].y = pt0.y
	queue_redraw()

func add_polyline_collider(polyline_id : int) -> void:
	var collider : StaticBody2D = StaticBody2D.new()
	var collision : CollisionShape2D = CollisionShape2D.new()
	var shape_x : RectangleShape2D
	var size : int 
	if image[polyline_id]["type"] == global.S.curve:
		size = image[polyline_id]["curve_instance"].get_point_count()
	else:
		size = image[polyline_id]["points"].size()
	if size <= 2:
		return
	var collider_name : String = str(polyline_id) + "x" + str(size - 2)
	shape_x = RectangleShape2D.new()
	collision.shape = shape_x
	collision.debug_color = Color(1,0,0)
	collider.position = VZERO
	collider.name = collider_name
	collider.connect("mouse_entered", Callable(self, "_entered").bind(collider_name))
	collider.connect("mouse_exited", Callable(self, "_exited").bind(collider_name))
	collider.input_pickable = T
	add_child(collider)
	collider.add_child(collision)

func delete_last_polyline_point(polyline_id : int) -> void:
	if image[polyline_id]["type"] == global.S.polyline:
		# delete collider
		var last_num : int = image[polyline_id]["points"].size()
		var collider : Object = get_node_or_null(str(polyline_id) + "x" + str(last_num - 2))
		if collider == null:
			print("ERROR: collider = null.")
			return
		collider.queue_free()
		# delete point from array
		image[polyline_id]["points"].pop_back()
		queue_redraw()

func paste() -> void:
	var paste_offset : Vector2 = Vector2(20, 20)
	deselect_all()
	for item in clipboard:
		var new_id : int = get_new_id()
		var copied : Dictionary = image[item].duplicate(T)
		if copied["type"] == global.S.line or copied["type"] == global.S.arrow:
			copied["points"][0] = copied["points"][0] + paste_offset
			copied["points"][1] = copied["points"][1] + paste_offset
		else:
			copied["position"] = copied["position"] + paste_offset
		
		image[new_id] = copied
		zindex.append(new_id)
		add_collider(copied, str(new_id))
		select_id(new_id)
		
		# Put the pasted object in front of the original one
		var temp : int = zindex[0]
		zindex[0] = zindex[1]
		zindex[1] = temp

# Add Shape
func _on_add_button(button_name: String) -> void:
	var object_type : global.S = global.string_to_shape_map.get(button_name, null)
	if object_type != null:
		add_shape.rpc(object_type)
	if button_name in global.button_to_tool_map:
		camera.tool = global.button_to_tool_map[button_name]
		tool_panel.set_tool_icon(button_name)

func delete_selected() -> void:
	for shape in selected:
		delete_id(shape)
	deselect_all()

func group_selected() -> void:
	var new_group_id : int = global.get_new_group_id()
	for selected_id in selected:
		image[selected_id]["group"] = new_group_id

func draw_guides(_tolerance : float = grid_size / 2.0) -> void:
	# Get h and v points for dragged shape.
	if id_being_dragged == -1:
		print("ERROR in draw_guides id_being_dragged = -1.")
		return
	if image[id_being_dragged]["type"] in SIZELESS:
		return
	var shape_pos : Vector2 = image[id_being_dragged]["position"]
	var shape_siz : Vector2 = image[id_being_dragged]["size"]
	var h1 : float = shape_pos.y
	var h2 : float = shape_pos.y + shape_siz.y
	var v1 : float = shape_pos.x
	var v2 : float = shape_pos.x + shape_siz.x
	
	y_guide_active = F
	check_vertical_guide(v1, _tolerance)
	check_vertical_guide(v2, _tolerance)
	
	x_guide_active = F
	check_horizontal_guide(h1, _tolerance)
	check_horizontal_guide(h2, _tolerance)

func check_vertical_guide(x_pos : float, _tolerance: float) -> void:
	for pt in v_guides:
		if abs(x_pos - pt) < _tolerance:
			v_guide_a = Vector2(pt, -5000)
			v_guide_b = Vector2(pt, 5000)
			y_guide_active = T
			queue_redraw()
			break

func check_horizontal_guide(y_pos : float, _tolerance: float) -> void:
	for pt in h_guides:
		if abs(y_pos - pt) < _tolerance:
			h_guide_a = Vector2(-5000, pt)
			h_guide_b = Vector2(5000, pt)
			x_guide_active = T
			queue_redraw()
			break

func update_guides(_include_dragged : bool = T) -> void:
	h_guides.clear()
	v_guides.clear()
	for L in image:
		if not _include_dragged and L == id_being_dragged:
			continue
		if image[L]["type"] not in SIZELESS: # add guides
		# horizontal
			h_guides.append(image[L]["position"].y)
			h_guides.append(image[L]["position"].y + image[L]["size"].y)
		# vertical
			v_guides.append(image[L]["position"].x)
			v_guides.append(image[L]["position"].x + image[L]["size"].x)

func _on_grid_toggle_pressed() -> void:
	display_grid = grid_toggle.button_pressed
	queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func edit_image(action : String, ids_i : Array, data : Dictionary) -> void:
	match action:
		"delete":
			print("deleting")
			for shape in ids_i:
				delete_id(shape)
				deselect_all()
		"add":
			print("adding")
			for i in ids_i:
				image[i] = data
		"modify":
			print("modifying")
			for i in ids_i:
				for prop in data:
					image[i][prop] = data[prop]


func add_curve_collider(polyline_id : int, num : int) -> void:
	var collider : StaticBody2D = StaticBody2D.new()
	var collision : CollisionShape2D = CollisionShape2D.new()
	var shape_x : RectangleShape2D
	var size : int 
	if image[polyline_id]["type"] == global.S.curve:
		size = image[polyline_id]["curve_instance"].get_point_count()
	else:
		size = image[polyline_id]["points"].size()
	if size <= 2:
		return
	var collider_name : String = str(polyline_id) + "A" + str(num)
	shape_x = RectangleShape2D.new()
	collision.shape = shape_x
	collision.debug_color = Color(1,0,0)
	collider.position = VZERO
	collider.name = collider_name
	collider.connect("mouse_entered", Callable(self, "_entered").bind(collider_name))
	collider.connect("mouse_exited", Callable(self, "_exited").bind(collider_name))
	collider.input_pickable = T
	add_child(collider)
	collider.add_child(collision)

func update_curve_select_colliders(c_id : int) -> void:
	# Delete colliders
	var segment_id : int = 0
	while T:
		var cl : Object = get_node_or_null(str(c_id) + "A" + str(segment_id))
		if cl:
			cl.queue_free()
			segment_id += 1
		else:
			break
	await get_tree().process_frame # ?
	# Sample points
	var points : PackedVector2Array = image[c_id]["curve_instance"].tessellate(3, 2)
	var new_segment_id : int = 0
	for po in points:
		add_curve_collider(c_id, new_segment_id)
		new_segment_id += 1
	update_curve_colliders(c_id, points.size(), points)

func update_curve_colliders(curve_id : int, collider_count : int, points : PackedVector2Array) -> void:
	if collider_count < 3 or points.size() < 3:
		return
	var number_of_colliders : int = collider_count - 2
	var border_width : float = image[curve_id]["border_width"] 
	var collider_width : float = border_width + 10.0
	for segment_idx in range(number_of_colliders):
		var collider : Node2D = get_node_or_null(str(curve_id) + "A" + str(segment_idx + 1))
		if not collider:
			print("ERROR: collider = null (4)")
			continue
		var point1: Vector2 = points[segment_idx + 1]
		var point2: Vector2 = points[segment_idx + 2]
		collider.position = 0.5 * (point1 + point2)
		
		var lenght : float = points[segment_idx+2].distance_to(points[segment_idx+1])
		var dd : Vector2 = points[segment_idx+2] - points[segment_idx+1]
		var angle : float = atan2(dd.x, dd.y)
		collider.get_child(0).shape.size = Vector2(collider_width, lenght)
		collider.rotation = -angle
		
