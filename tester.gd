extends Node2D

func _ready():
	pass # Replace with function body.

func spawn():
	pass

func despawn():
	pass

func load_state(stream:StreamPeerBuffer):
	self.name = stream.get_string()
	self.position.x = stream.get_float()
	self.position.y = stream.get_float()
	self.rotation = stream.get_float()

func save_state(stream:StreamPeerBuffer):
	stream.put_string(self.name)
	stream.put_float(self.position.x)
	stream.put_float(self.position.y)
	stream.put_float(self.rotation)
