tool
extends EditorPlugin

var _added_types = []

func add_custom_type_ext(_name, _base, _script, _icon = load("res://addons/GodotStateNetcode/icons/Node.png")):
	add_custom_type(_name,_base,_script,_icon)
	_added_types.append(_name)

func _enter_tree():
	add_custom_type_ext("TickTimer","Node",load("res://addons/GodotStateNetcode/nodes/TickTimer.gd"),load("res://addons/GodotStateNetcode/icons/Timer.png"))


func _exit_tree():
	for custom_type in _added_types:
		remove_custom_type(custom_type)
