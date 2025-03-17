extends Node

# Functions for individual shapes.

func get_and_gate_points(half: Vector2) -> PackedVector2Array:
	var return_array: PackedVector2Array = []
	var num_points: int = int(PI * max(half.x, half.y))

	return_array.resize(num_points + 1)

	return_array[0] = Vector2(-half.x, -half.y)
	for i in range(num_points + 1):
		# Adjust angle range for the right half (from -PI/2 to PI/2)
		if i == 0:
			continue
		var angle: float = lerp(-PI / 2.0, PI / 2.0, float(i) / num_points)
		return_array[i] = Vector2(half.x * cos(angle), half.y * sin(angle))
	return_array[num_points] = Vector2(-half.x, half.y)
	return return_array

func get_arc_points(start_angle : float, end_angle : float, half : Vector2, pie : bool) -> PackedVector2Array:
	var angle_range: float = end_angle - start_angle if end_angle > start_angle else TAU - (start_angle - end_angle)
	var max_radius: float = max(half.x, half.y)
	var arc_length: float = angle_range * max_radius
	var num_points: int = maxi(8, ceili(arc_length * 0.5))
	var step: float = angle_range / (num_points - 1)
	
	var return_array: PackedVector2Array = PackedVector2Array()
	return_array.resize(num_points + 1 if pie else num_points)
	
	for i in num_points:
		var angle: float = start_angle + i * step
		return_array[i] = Vector2(
			half.x * cos(angle - PI / 2.0),
			half.y * sin(angle - PI / 2.0)
		)

	return_array[num_points - 1] = Vector2(
		half.x * cos(end_angle - PI / 2.0),
		half.y * sin(end_angle - PI / 2.0)
	)

	if pie:
		return_array[num_points] = Vector2(0, 0)

	return return_array

func get_rectangle_points(half : Vector2) -> PackedVector2Array:
	return [-half, Vector2(half.x, -half.y),
			 half, Vector2(-half.x, half.y)]

func get_buffer_points(half : Vector2) -> PackedVector2Array:
	return [Vector2(-half.x, half.y),
			Vector2(half.x, 0),
			Vector2(-half.x, -half.y)]

func get_circle_points(radius_vector : Vector2) -> PackedVector2Array:
	var return_array : PackedVector2Array = []
	var max_radius : float = max(radius_vector.x, radius_vector.y)
	var num_points : int = maxi(12, ceil(PI * max_radius))
	return_array.resize(num_points)

	for i in range(num_points):
		var angle : float = TAU * i / num_points
		return_array[i] = Vector2(radius_vector.x * cos(angle), radius_vector.y * sin(angle))
	
	return return_array

func get_or_gate_points(half: Vector2) -> PackedVector2Array:
	var return_array: PackedVector2Array
	var first_array : PackedVector2Array
	var second_array : PackedVector2Array
	var left_array : PackedVector2Array
	var num_points : int = int(PI * max(half.x, half.y))
	first_array.resize(num_points + 1)
	second_array.resize(num_points + 1)
	left_array.resize(num_points + 1)
	return_array.resize(3 * (num_points + 1) - 1)

	for i in range(num_points + 1):
		var t = half.x * sqrt(3.0)/2.0 # cos(deg_to_rad(30))
		var angle: float = lerp(-PI / 2.0, -deg_to_rad(30), float(i) / num_points)
		var left_angle = lerp(-deg_to_rad(30), deg_to_rad(30), float(i) / num_points)
		var point = 2.0 * Vector2(half.x * cos(angle), half.y * sin(angle))
		var left_point = 2.0 * Vector2(half.x * cos(left_angle), half.y * sin(left_angle))
		first_array[i] = Vector2(point.x, point.y) - Vector2((1.5/2.0) * half.x, -half.y)
		second_array[i] = Vector2(point.x, -point.y) - Vector2((1.5/2.0) * half.x, half.y)
		left_array[i] = Vector2(
								left_point.x - t - 1.75 * half.x,
								left_point.y)
		
	#first_array.pop_front()
	#second_array.pop_front()
	
	second_array.reverse()
	second_array.remove_at(0)
	left_array.reverse()
	var i : int = 0
	for pr in first_array:
		return_array[i] = pr
		i += 1
	for pr in second_array:
		return_array[i] = pr
		i += 1
	for pr in left_array:
		return_array[i] = pr
		i += 1
	return return_array

func get_xor_gate_arc_points(half: Vector2) -> PackedVector2Array:
	var return_array: PackedVector2Array
	var first_array : PackedVector2Array
	var second_array : PackedVector2Array
	var left_array : PackedVector2Array
	var num_points : int = int(PI * max(half.x, half.y))
	first_array.resize(num_points + 1)
	second_array.resize(num_points + 1)
	left_array.resize(num_points + 1)
	return_array.resize(3 * (num_points + 1) - 2)

	for i in range(num_points + 1):
		var t = half.x * sqrt(3.0)/2.0 # cos(deg_to_rad(30))
		var angle: float = lerp(-PI / 2.0, -deg_to_rad(30), float(i) / num_points)
		var left_angle = lerp(-deg_to_rad(30), deg_to_rad(30), float(i) / num_points)
		var point = 2.0 * Vector2(half.x * cos(angle), half.y * sin(angle))
		var left_point = 2.0 * Vector2(half.x * cos(left_angle), half.y * sin(left_angle))
		first_array[i] = Vector2(point.x, point.y) - Vector2((1.5/2.0) * half.x, -half.y)
		second_array[i] = Vector2(point.x, -point.y) - Vector2((1.5/2.0) * half.x, half.y)
		left_array[i] = Vector2(
								left_point.x - t - 1.75 * half.x - 10.0,
								left_point.y)

	second_array.reverse()
	second_array.remove_at(0)
	left_array.reverse()

	var i : int = 0

	for pr in first_array:
		return_array[i] = pr
		i += 1
	for pr in second_array:
		return_array[i] = pr
		i += 1
	for pr in left_array:
		return_array[i - 1] = pr
		i += 1

	return return_array

func get_triangle_points(half : Vector2) -> PackedVector2Array:
	return [Vector2(-half.x, half.y),
			Vector2(half.x, half.y),
			Vector2(0, -half.y)]

func get_orthogonalTriangle_points(half : Vector2) -> PackedVector2Array:
	return [Vector2(-half.x, half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, -half.y)]

func get_diamond_points(half : Vector2, corner_radius : float) -> PackedVector2Array:
	var return_array : PackedVector2Array
	if corner_radius <= 0:
		return [Vector2(0, -half.y),
				Vector2(half.x, 0),
				Vector2(0, half.y),
				Vector2(-half.x, 0)]
	else:
		var w : float = max(0.0, 2.0 * half.x)
		var h : float = max(0.0, 2.0 * half.y)
		var radius : float = corner_radius
		
		if w > h:
			if (h) < 4.0 * radius:
				radius = h / 4.0
		else:
			if (w) < 4.0 * radius:
				radius = w / 4.0
				
		#radius = r
		var right_array : PackedVector2Array
		var left_array : PackedVector2Array
		var top_array : PackedVector2Array
		var bottom_array : PackedVector2Array
		var num_points : int = int(PI * max(half.x, half.y))
		num_points = 6
		return_array.resize(4 * (num_points + 1))
		right_array.resize(num_points + 1)
		left_array.resize(num_points + 1)
		top_array.resize(num_points + 1)
		bottom_array.resize(num_points + 1)

		var real_right_angle : float = 180.0 - 2.0 * rad_to_deg(atan(half.y / half.x))
		var real_top_angle : float = 180.0 - 2.0 * rad_to_deg(atan(half.x / half.y))
		var rah : float = real_right_angle / 2.0
		var tah : float = real_top_angle / 2.0
		var p_l_r : float = (1.0 / tan(deg_to_rad(rah)))
		var p_t_b : float = (1.0 / tan(deg_to_rad(tah)))
		
		for i in range(num_points + 1):
			# Right
			var right_angle = lerp(deg_to_rad(-rah), deg_to_rad(rah), float(i) / num_points)
			var right_pt = 2.0 * Vector2(radius * cos(right_angle), radius * sin(right_angle))
			right_array[i] = Vector2(right_pt.x + half.x - 2.0 * radius - p_l_r, right_pt.y)
			# Bottom
			var bottom_angle = lerp(deg_to_rad(90-tah), deg_to_rad(90+tah), float(i) / num_points)
			var bottom_pt = 2.0 * Vector2(radius * cos(bottom_angle), radius * sin(bottom_angle))
			bottom_array[i] = Vector2(bottom_pt.x, bottom_pt.y + half.y - 2.0 * radius - p_t_b)
			# Left
			var left_angle = lerp(deg_to_rad(180-rah), deg_to_rad(180+rah), float(i) / num_points)
			var left_pt = 2.0 * Vector2(radius * cos(left_angle), radius * sin(left_angle))
			left_array[i] = Vector2(left_pt.x - half.x + 2.0 * radius + p_l_r, left_pt.y)
			# Top
			var top_angle = lerp(deg_to_rad(-90-tah), deg_to_rad(-90+tah), float(i) / num_points)
			var top_pt = 2.0 * Vector2(radius * cos(top_angle), radius * sin(top_angle))
			top_array[i] = Vector2(top_pt.x, top_pt.y - half.y + 2.0 * radius + p_t_b)
			
		var i : int = 0
		for p in right_array:
			return_array[i] = p
			i += 1
		for p in bottom_array:
			return_array[i] = p
			i += 1
		for p in left_array:
			return_array[i] = p
			i += 1
		for p in top_array:
			return_array[i] = p
			i += 1
		
	return return_array

func get_hexagon_points(half : Vector2) -> PackedVector2Array:
	return [Vector2(-half.x / 2.0, -half.y),
			Vector2(half.x / 2.0, -half.y),
			Vector2(half.x, 0.0),
			Vector2(half.x / 2.0, half.y),
			Vector2(-half.x / 2.0, half.y),
			Vector2(-half.x, 0.0)]

func get_parallelogram_points(half : Vector2) -> PackedVector2Array:
	var offset : float = half.x * 0.6
	return [Vector2(offset - half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(-offset + half.x, half.y),
			Vector2(-half.x, half.y)]

func get_trapezoid_points(half : Vector2) -> PackedVector2Array:
	var top_width = half.x * 1.2
	var top_left = Vector2((-0.5*top_width), -half.y)
	var top_right = top_left + Vector2(top_width, 0)
	var bottom_left = Vector2(-half.x, half.y)
	var bottom_right = half
	return [top_left, top_right, bottom_right, bottom_left]

func get_ngon_points(half : Vector2, sides : int) -> PackedVector2Array:
	var return_array : PackedVector2Array
	var n : int = maxi(3, sides)
	return_array.resize(n + 1)
	
	for i in range(n):
		var angle : float = (TAU * i) / n
		if n % 2 == 1:
			angle = angle - (0.5 * PI / n)
		var point := Vector2(
			half.x * cos(angle),
			half.y * sin(angle)
		)
		return_array[i] = point

	if return_array.size() > 0:
		return_array[n] = return_array[0]

	return return_array

func get_star_points(siz : Vector2, sides : int, inner_ratio : float = 0.5) -> PackedVector2Array:
	var return_array : PackedVector2Array
	var n : int = maxi(3, sides)
	inner_ratio = clampf(inner_ratio, 0.1, 0.9)	
	var outer_radius : float = min(siz.x, siz.y) / 2.0
	var inner_radius : float = outer_radius * inner_ratio
	return_array.resize(n * 2)

	for i in range(n * 2):
		var angle : float = TAU * i / (n * 2)
		if n % 2 == 1:
			angle -= TAU / (n * 4)
		var radius : float = outer_radius if i % 2 == 0 else inner_radius
		var point : Vector2 = Vector2(cos(angle), sin(angle)) * radius
		return_array[i] = point
	
	if return_array.size() > 0:
		return_array.append(return_array[0])
		
	return return_array

func get_drop_points(half : Vector2) -> PackedVector2Array:
	var return_array : PackedVector2Array = []
	var radius : float = minf(half.x, half.y)
	var top_angle : float = 2.0 * asin(radius / (2.0 * half.y - radius))
	var arc_offset : float = 0.5 * top_angle
	
	var num_points: int = ceili((PI + 2.0 * arc_offset) / 0.05)
	return_array.resize(num_points + (1 if half.x <= half.y else 0))

	for i in num_points:
		var angle: float = lerp(-arc_offset, PI + arc_offset, float(i) / (num_points - 1))
		return_array[i] = Vector2(
			radius * cos(angle),
			radius * sin(angle) + half.y - radius
		)
	
	if half.x <= half.y:
		return_array[num_points] = Vector2(0, -half.y)

	return return_array

func get_rounded_rectangle_points(half: Vector2, corner_radius: float) -> PackedVector2Array:
	var return_array : PackedVector2Array = []
	var radius: float = min(corner_radius, min(half.x, half.y))
	var points_per_corner : int = max(8, int(radius * 0.3))
	#return_array.resize(4 * (points_per_corner + 1))

	for corner in range(4):
		var start_angle: float = corner * PI / 2.0
		var corner_center := Vector2(
			half.x - radius if corner in [0, 3] else -half.x + radius,
			half.y - radius if corner < 2 else -half.y + radius
		)
		
		for i in range(points_per_corner + (1 if corner == 3 else 0)):
			var angle: float = start_angle + (PI/2) * float(i) / points_per_corner
			var point := Vector2(
				radius * cos(angle),
				radius * sin(angle)
			) + corner_center
			# [i + corner * (points_per_corner + 1)]
			return_array.append(point)

	return return_array


func get_heart_points(half : Vector2) -> PackedVector2Array:
	var return_array : PackedVector2Array = []
	var x : float = -2.0
	while x < 2.0:
		var y : float = half.y * sqrt(1.0 - pow(abs(x) - 1.0, 2.0))
		var pt : Vector2 = Vector2(half.x * x / 2.0, -y / 2.0 - half.y/2.0)
		if return_array.size() > 0:
			var a = return_array[return_array.size() - 1]
			var distance  = a.distance_to(pt)
			if distance < 4:
				x = x + 0.02
				continue
		return_array.append(pt)
		x = x + 0.02
	x = -2.0
	return_array.remove_at(0)
	while x < 2.01:
		var y : float = acos(1.0 - abs(x)) - PI
		var pt : Vector2 = Vector2(half.x * x / 2.0, -half.y*y/2.0 - half.y/2.0)
		if return_array.size() > 0:
			var a = return_array[0]
			var distance  = a.distance_to(pt)
			if distance < 4:
				x = x + 0.02
				continue
		return_array.insert(0, pt)
		x = x + 0.02
	return return_array

func get_sine_points(half: Vector2) -> PackedVector2Array:
	var return_array: PackedVector2Array = []
	var points_per_unit: float = 2.0
	var num_points: int = max(10, int(half.x * points_per_unit))
	return_array.resize(num_points + 1)

	for i in range(num_points + 1):
		var t: float = float(i) / num_points
		var x: float = lerp(-half.x, half.x, t)
		var y: float = half.y * sin(x * PI / (half.x))
		return_array[i] = Vector2(x, y)
	
	return return_array
