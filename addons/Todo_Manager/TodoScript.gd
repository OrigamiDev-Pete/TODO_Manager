tool
extends Reference

const Todo := preload("res://addons/Todo_Manager/Todo.gd")
const Uid := preload("res://addons/Todo_Manager/Uid.gd")

var _uid_generator : Uid # 'global' reference to uid_generator

var script_path : String
var source_code : String
var todos : Array


func initialize(u: Uid, path: String) -> void:
	_uid_generator = u
	script_path = path
	find_todos()



func find_todos():
	pass



func get_short_path() -> String:
	var temp_array := script_path.rsplit('/', false, 1)
	var short_path : String
	if !temp_array[1]:
		short_path = "(!)" + temp_array[0]
	else:
		short_path = temp_array[1]
	return short_path
