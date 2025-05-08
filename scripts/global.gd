extends Node

# Global declarations and variables.
# undo and redo

var group      : int
var debug_mode : bool = false
var undoStack  : Array = []
var redoStack  : Array = []
var user_name  : String = ""
var peer       : ENetMultiplayerPeer
var def_port   : int = 1705
var connected_users : Dictionary = {}

# Shapes
enum S {rectangle, line, polyline, arrow, text, trapezoid, circle, triangle, diamond, hexagon, parallelogram, ngon, star, drop, arc, orthogonalTriangle, image, table, invertor, and_gate, or_gate, nand_gate, nor_gate, xor_gate, buffer, diode, node, ground, heart, capacitor, resistor, inductor, nmos, pmos, pnp, npn, sine}
	
# Tools
enum TOOLS {SELECT, PEN, POLYLINE, LASER}

# Actions for undo / redo system
enum ACTION {DESELECT_ALL, SELECT_ALL, SELECT_SHAPE, SELECT_SHAPES, DESELECT_SHAPE, DESELECT_SHAPES, DELETE_SHAPE, DELETE_SHAPES, ADD_SHAPE, ADD_SHAPES, CHANGE_SHAPE, CHANGE_SHAPES}

# Arrow termination
enum ATERM {NONE, LINE_ARROW, FULL_ARROW, LINE, CIRCLE, RECTANGLE}

# undoStack Dictionary:
# = {
# 		"action": global.ACTION.SELECT_SHAPE
# 		"id": id
#   }

func do_undo() -> void:
	var canvas : Object = get_node("/root/editor/canvas")
	if undoStack.size() > 0:
		var undoData : Dictionary = undoStack[0]
		match undoData["action"]:
			ACTION.SELECT_SHAPE:
				canvas.deselect_id(undoData["id"])
			ACTION.DESELECT_ALL:
				canvas.select_all()
			ACTION.SELECT_ALL:
				canvas.deselect_all()
			ACTION.SELECT_SHAPES:
				pass
			ACTION.DESELECT_SHAPE:
				pass
			ACTION.DESELECT_SHAPES:
				pass
			ACTION.DELETE_SHAPE:
				pass
			ACTION.DELETE_SHAPES:
				pass
			ACTION.ADD_SHAPE:
				pass
				#canvas.delete_id(undoData["id"])
			ACTION.ADD_SHAPES:
				pass
			ACTION.CHANGE_SHAPE:
				pass
			ACTION.CHANGE_SHAPES:
				pass
		redoStack.push_front(undoData) # TODO modify the undo data
		undoStack.pop_front()
	canvas.queue_redraw()

func do_redo() -> void:
	pass

func get_new_group_id() -> int:
	group = group + 1
	return group

var string_to_shape_map = {
	"rect": global.S.rectangle,
	"text": global.S.text,
	"line": global.S.line,
	"polyline": global.S.polyline,
	"circle": global.S.circle,
	"arrow": global.S.arrow,
	"triangle": global.S.triangle,
	"diamond": global.S.diamond,
	"hexagon": global.S.hexagon,
	"parallelogram": global.S.parallelogram,
	"trapezoid": global.S.trapezoid,
	"n_gon": global.S.ngon,
	"star": global.S.star,
	"drop": global.S.drop,
	"arc": global.S.arc,
	"orthogonal_triangle": global.S.orthogonalTriangle,
	"image": global.S.image,
	"table": global.S.table,
	"and_gate": global.S.and_gate,
	"or_gate": global.S.or_gate,
	"buffer": global.S.buffer,
	"invertor": global.S.invertor,
	"nand_gate": global.S.nand_gate,
	"nor_gate": global.S.nor_gate,
	"xor_gate": global.S.xor_gate,
	"diode": global.S.diode,
	"node": global.S.node,
	"ground": global.S.ground,
	"heart": global.S.heart,
	"capacitor": global.S.capacitor,
	"resistor": global.S.resistor,
	"inductor": global.S.inductor,
	"nmos": global.S.nmos,
	"pmos": global.S.pmos,
	"pnp": global.S.pnp,
	"npn": global.S.npn,
	"sine": global.S.sine,
}

var button_to_tool_map = {
	"polyline": global.TOOLS.POLYLINE,
}

func host(new_name : String = "Unnamed") -> void:
	user_name = new_name
	peer = ENetMultiplayerPeer.new()
	peer.create_server(def_port)
	multiplayer.multiplayer_peer = peer

func add_user(ip : String, new_name : String = "Unnamed") -> void:
	user_name = new_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, def_port)
	multiplayer.multiplayer_peer = peer
