extends Node

var state_buffer = []


class StateBufferFrame:
	var tick: int
	var data: Dictionary
	
	func _init(tick, data):
		self.tick = tick
		self.data = data

class Perspective:
	func _init():
		pass


func update():
	var data = get_tree().get_nodes_in_group("tracked_state")
	
	for item in data:
		item.state_priority += item.state_importance
	
	data.sort_custom(self,"_sort_func")


func _call_save_state() -> Dictionary:
	var state := {}
	var nodes: Array = get_tree().get_nodes_in_group('network_sync')
	for node in nodes:
		if node.has_method('_save_state') and node.is_inside_tree() and not node.is_queued_for_deletion():
			var node_path = str(node.get_path())
			if node_path != "":
				state[node_path] = node._save_state()
	return state


func _call_load_state(state: Dictionary) -> void:
	for node_path in state:
		if node_path == '$':
			continue
		var node = get_node_or_null(node_path)
		assert(node != null, "Unable to restore state to missing node: %s" % node_path)
		if node and node.has_method('_load_state'):
			node._load_state(state[node_path])


func _sort_func(a,b):
	return a.state_priority > b.state_priority
