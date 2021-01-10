tool
extends Object

var _current_id : int

func _init() -> void:
	# get last id, possibly from saved file or lookup largest number in the current project
	
	### TESTING ###
	_current_id = 0


func get_next_id() -> int:
	_current_id += 1
	return _current_id
