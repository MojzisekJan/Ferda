extends Node2D

# Script for the main editor scene.

@export var camera         : Camera2D
@export var canvas         : Node2D
@export var zoom_label     : Button
@export var settings       : Panel
@export var cursor_label   : Label
@export var tool_panel     : Panel
@export var actions_panel  : Panel
@export var tools_panel    : Panel
@export var zoom_panel     : Panel
@export var cursor_panel   : Panel
@export var menu_panel     : Panel
@export var help_panel     : Panel
@export var settings_panel : Panel
@export var connect_popup  : Popup
@export var name_input     : LineEdit
@export var ip_input       : LineEdit
@export var main_menu      : Popup

func _ready() -> void:
	animate_panels()

func animate_panels() -> void:
	var twn : Tween = create_tween()
	const t : float = 1.0
	const p : String = "position"
	var w_siz : Vector2 = get_viewport_rect().size
	var half_w_siz : Vector2 = w_siz / 2.0
	twn.set_trans(Tween.TRANS_ELASTIC)
	twn.parallel().tween_property(tool_panel, p, Vector2(half_w_siz.x - tool_panel.size.x/2.0, 0), t)
	twn.parallel().tween_property(actions_panel, p, Vector2(half_w_siz.x - actions_panel.size.x/2.0, w_siz.y - actions_panel.size.y), t)
	twn.parallel().tween_property(tools_panel, p, Vector2(0, half_w_siz.y - tools_panel.size.y/2.0), t)
	twn.parallel().tween_property(zoom_panel, p, Vector2(0, w_siz.y - zoom_panel.size.y), t)
	twn.parallel().tween_property(cursor_panel, p, Vector2(w_siz.x - cursor_panel.size.x, w_siz.y - cursor_panel.size.y), t)
	twn.parallel().tween_property(menu_panel, p, Vector2(0, 0), t)

func _process(_delta) -> void:
	canvas.mouse_in_canvas = is_mouse_in_ui()
	update_cursor_label()

func is_mouse_in_ui() -> bool:
	# Check if the cursor is inside one of the UI Panels.
	for node in $Camera2D/CanvasLayer/Control.get_children():
		if node.visible and node is Panel:
			if Rect2(node.position, node.size).has_point(get_viewport().get_mouse_position()):
				return false
	return true

func update_zoom_label(new_zoom : float) -> void:
	zoom_label.text = str(int(new_zoom * 100)) + str(" %")
	
func update_cursor_label() -> void:
	var pos : Vector2 = get_global_mouse_position()
	cursor_label.text = "( " + str(int(pos.x)) + " , " + str(int(pos.y)) + " )"

func _on_minus_button_down() -> void:
	camera.zoom = camera.zoom * 0.9
	update_zoom_label(camera.zoom.x)

func _on_plus_button_down() -> void:
	camera.zoom = camera.zoom * 1.1
	update_zoom_label(camera.zoom.x)

func _on_zoom_button_down() -> void:
	camera.zoom = Vector2(1.0, 1.0)
	update_zoom_label(camera.zoom.x)

func _on_menu_button_down() -> void:
	main_menu.popup(Rect2(Vector2(0,0),Vector2(250, get_viewport().size.y)))
	
# Mouse in window:
func _notification(event : int) -> void:
	if event == NOTIFICATION_WM_MOUSE_ENTER:
		canvas.mouse_in_canvas = true
	elif event == NOTIFICATION_WM_MOUSE_EXIT:
		canvas.mouse_in_canvas = false

func _on_undo_button_down() -> void:
	global.do_undo()
func _on_redo_button_down() -> void:
	global.do_redo()
func _on_menu_settings_button_down() -> void:
	settings.show()
func _on_control_resized() -> void:
	animate_panels()
func _on_exit_pressed() -> void:
	get_tree().quit()
func _on_button_pressed() -> void:
	help_panel.hide()
	settings_panel.hide()

func _on_color_picker_button_color_changed(color: Color) -> void:
	RenderingServer.set_default_clear_color(color)


func _on_connect_button_down() -> void:
	var pnl_size : Vector2 = get_viewport_rect().size
	connect_popup.popup_centered(Vector2(pnl_size.x / 3.0, pnl_size.y / 2.0))

func _on_connect_close_button_down() -> void:
	connect_popup.hide()

func dis() -> void:
	$Camera2D/CanvasLayer/Control/connect_popup/MarginContainer/Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer3/host.disabled = true
	$Camera2D/CanvasLayer/Control/connect_popup/MarginContainer/Panel/VBoxContainer/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer3/join.disabled = true

func _on_host_button_down() -> void:
	global.host(name_input.text)
	dis()
func _on_join_button_down() -> void:
	global.add_user(ip_input.text, name_input.text)
	dis()
func _on_start_button_down() -> void:
	pass # Replace with function body.

func _on_cursor_toggle_pressed() -> void:
	cursor_panel.visible = not cursor_panel.visible
func _on_zoom_toggle_pressed() -> void:
	zoom_panel.visible = not zoom_panel.visible
