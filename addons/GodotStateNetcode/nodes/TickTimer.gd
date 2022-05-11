extends Node

var _running := false

export(bool) var one_shot:bool = false
export(bool) var autostart:bool = false
export(bool) var paused:bool = false
export(bool) var hash_state := true
# for use when ticks are small as it cuts the size of the pack in half
export(bool) var int32 := false
const MASK_LEFT = 0b1111_1111_1111_1111_1111_1111_1111_1111 << 32
const MASK_RIGHT = 0b1111_1111_1111_1111_1111_1111_1111_1111

signal timeout

var _physics_fps = int(ProjectSettings.get_setting("physics/common/physics_fps"))

export(int) var wait_ticks:int = 10
var ticks_left:int = 0

export(int) var wait_time_ms:int setget _set_wait_time,_get_wait_time
var time_left_ms:int setget _set_time_left,_get_time_left

func _set_wait_time(value:int):
	wait_ticks = value/_physics_fps
func _get_wait_time():
	return wait_ticks * _physics_fps
func _set_time_left(value:int):
	ticks_left = value/_physics_fps
func _get_time_left():
	return ticks_left * _physics_fps

func _ready():
	add_to_group("state_actors")
	if autostart:
		start()

func _state_process(_state:Dictionary = {}) -> void:
	if not _running or paused: return
	ticks_left -= 1 
	if ticks_left <= 0:
		if one_shot:
			_running = false
		else:
			ticks_left = wait_ticks
		emit_signal("timeout")

func _map_state() -> Dictionary:
	return {
			running = _running,
			wait_ticks = wait_ticks,
			ticks_left = ticks_left,
			paused = paused,
			int32 = int32,
		}

func _pack_state():
	var b := StreamPeerBuffer.new()
	var header = 0
	if hash_state:	enable_bit(header, 1)
	if paused:		enable_bit(header, 2)
	if _running:	enable_bit(header, 3)
	if int32:		enable_bit(header, 4)
	
	b.put_u8(header)
	if int32:
		var n = (wait_ticks<<32) | ticks_left
		b.put_u64(n)
	else:
		b.put_u64(wait_ticks)
		b.put_u64(ticks_left)

func _unpack_state(state:StreamPeerBuffer):
	var header = state.get_u8()
	hash_state 	= is_bit_enabled(header,1)
	paused 		= is_bit_enabled(header,2)
	_running 	= is_bit_enabled(header,3)
	int32 		= is_bit_enabled(header,4)
	
	
	if int32:
		wait_ticks = (MASK_LEFT & state.get_u64()) >> 32
		ticks_left = MASK_RIGHT & state.get_u64()
	else:
		wait_ticks = state.get_u64()
		ticks_left = state.get_u64()
	

func _save_state() -> Dictionary:
	if hash_state:
		return {
			running = _running,
			wait_ticks = wait_ticks,
			ticks_left = ticks_left,
			paused = paused
		}
	else:
		return {
			_running = _running,
			_wait_ticks = wait_ticks,
			_ticks_left = ticks_left,
			_paused = paused
		}

func _load_state(state:Dictionary) -> void:
	if hash_state:
		_running = state['running']
		wait_ticks = state['wait_ticks']
		ticks_left = state['ticks_left']
		paused = state['paused']
	else:
		_running = state['_running']
		wait_ticks = state['_wait_ticks']
		ticks_left = state['_ticks_left']
		paused = state['paused']

func start(ticks = -1):
	if ticks < 0:
		ticks_left = wait_ticks
	else:
		ticks_left = ticks
	_running = true

func stop():
	_running = false

func is_stopped():
	return paused

func bitmask(initial, amount):
	initial <<=amount
	return initial

func is_bit_enabled(mask, index):
	return mask & (1 << index) != 0

func enable_bit(mask, index):
	return mask | (1 << index)

func disable_bit(mask, index):
	return mask & ~(1 << index)
