extends Node

class StateManager:
	var data_ceiling = 256
	var tick = 0
	var frames := []
	var sync_nodes := NodeAccumulationBuffer.new()
	var buffer := StreamPeerBuffer.new()
	
	func update():
		
		sync_nodes.get_array(data_ceiling)
		
	
class RingBuffer:
	var data := []
	
	func put(value):
		data.append(value)
	
	func puts(values:Array):
		data.append_array(values)
	
	func pop():
		data.pop_front()

class StaticAccumulationBuffer:
	var data := []
	
	#subarray indicies
	const PRIORITY = 0
	const RATE = 1
	const DATA = 2
	
	func put(value:PoolByteArray, priority:float, rate:float):
		data.append([priority,rate,value])
	
	func increment():
		for element in data:
			element[PRIORITY]+=element[RATE]
			element[RATE]*=2
	
	func get_array(size:int = 256) -> Array:
		increment()
		data.sort_custom(self, "_sort_func")
		var dumbarray := []
		var v:PoolByteArray
		var this_size:int
		var total_size:int
		var idx = 0
		for value in data:
			v = value[DATA]
			this_size = v.size()
			dumbarray.append(v)
			total_size += this_size
			if total_size > size:
				print(total_size)
				break
			idx+=1
		
		#remove data being returned
		data = data.slice(idx+1,data.size()-1)
		return dumbarray
	
	func _sort_func(a:Array,b:Array):
		return a[PRIORITY]>b[PRIORITY]


class NodeAccumulationBuffer:
	var data := []
	var trackers = {}
	
	func put(value:Node, priority:float, rate:float):
		if value.has_method("save_state"):
			var statetrack = StateTrack.new(priority,rate,value)
			# with state synchronization we only need the instance_id to be unique
			# on the server.
			trackers[value.get_instance_id()] = statetrack
			data.append(statetrack)
		else:
			print_debug("Warn: node<"+value.name+"> does not have save_state funciton")
	
	func update():
		var element:StateTrack
		
		# Ugly code because GDScript
		for i in range(data.size()-1,-1,-1):
			element = data[i]
			element.priority += element.rate
			element.rate *= 2
			if element.node == null:
				data.remove(i)
	
	func get_array(size:int = 256) -> Array:
		update()
		data.sort_custom(self, "_sort_func")
		var dumbarray := []
		var v:PoolByteArray
		var this_size:int
		var total_size:int
		var idx = 0
		for element in data:
			v = element.get_data()
			if v == null:
				continue
			this_size = v.size()
			dumbarray.append(v)
			total_size += this_size
			if total_size > size:
				print(total_size)
				break
			idx+=1
		
		#remove data being returned
		data = data.slice(idx+1,data.size()-1)
		return dumbarray
	
	func _sort_func(a:StateTrack,b:StateTrack):
		return a.priority>b.priority


class StateTrack:
	var data := StreamPeerBuffer.new()
	var node = null
	
	var priority_start = 0
	var priority = 0
	
	var rate_start = 0
	var rate = 0
	
	func _init(priority, rate, value:Node):
		self.node = value
		self.priority_start = priority
		self.rate_start = rate
		reset()
	
	func reset():
		self.priority = self.priority_start
		self.rate = self.rate_start
		
	func get_data():
		if not is_instance_valid(node):
			#returning null tells us to get free'd
			self.node = null
			return null
		else:
			self.data.clear()
			node.save_state(data)
		reset()
		return data.data_array


var ab = NodeAccumulationBuffer.new()
func _ready():
	
	for child in get_children():
		ab.put(child,1,1)
	
	var b = StreamPeerBuffer.new()
	for v in ab.get_array():
		b.data_array = v
		print(b.get_string()," ",b.get_float()," ",b.get_float()," ",b.get_float())
