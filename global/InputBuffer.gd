extends Node

var _monitor := {}

func _input(event):
	_record_pressed(event)
	_delete_released.call_deferred(event) # let other _input handlers do their job before deletion
	
func _record_pressed(event):
	for action in _monitor:
		if event.is_action_pressed(action):
			_monitor[action] = Time.get_ticks_msec()
	
func _delete_released(event):
	for action in _monitor:
		if event.is_action_released(action):
			_monitor[action] = null

func add_monitored_action(action : String):
	if action not in _monitor:
		_monitor[action] = null # no timestamp yet

func is_action_buffered(action : String, duration_msec : int):
	return action in _monitor and _monitor[action] != null and Time.get_ticks_msec() - _monitor[action] <= duration_msec

func consume_buffered_action(action : String):
	_monitor[action] = null
