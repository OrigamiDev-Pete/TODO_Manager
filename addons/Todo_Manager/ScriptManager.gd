tool
extends Reference
### This class keeps track of all the scripts in a project and acts as an
### interface between the filesystem and the rest of the plugin.

const TodoScript := preload("res://addons/Todo_Manager/TodoScript.gd")
const Todo := preload("res://addons/Todo_Manager/Todo.gd")
const Uid := preload("res://addons/Todo_Manager/Uid.gd")

var _uid_generator : Uid # 'global' reference to UID generator
var _progress : float
var _progress_bar : ProgressBar
var _patterns : Array

var scripts : Array # Stores an array of Script objects
var todo_scripts : Array # Stores an array of TodoScript objects


func setup(u: Uid, pb: ProgressBar) -> void:
	_uid_generator = u
	_progress_bar = pb


func find_scripts(patterns: Array) -> Array:
	_patterns = patterns
	var script_paths : Array
	var directory_queue : Array
	var dir : Directory = Directory.new()
	### FIRST PHASE ###
	if dir.open("res://") == OK:
		_get_dir_contents(dir, script_paths, directory_queue)
	else:
		printerr("TODO_Manager: There was an error during find_scripts() ### First Phase ###")
	
	### SECOND PHASE ###
	while not directory_queue.empty():
		if dir.change_dir(directory_queue[0]) == OK:
			_get_dir_contents(dir, script_paths, directory_queue)
		else:
			printerr("TODO_Manager: There was an error at: " + directory_queue[0])
		directory_queue.pop_front()
	
	_load_scripts(script_paths)
	return todo_scripts


func update_scripts() -> Array:
	pass
	return todo_scripts


func _get_dir_contents(dir: Directory, script_paths: Array, directory_queue: Array) -> void:
	dir.list_dir_begin(true, true)
	var file_name : String = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			if file_name == ".import" or file_name == ".mono": # Skip .import and .mono folder which should never have scripts
				pass
			else:
				directory_queue.append(dir.get_current_dir() + "/" + file_name)
		else:
			if file_name.ends_with(".gd") or file_name.ends_with(".cs"):
				script_paths.append(dir.get_current_dir() + "/" + file_name)
		file_name = dir.get_next()


func _load_scripts(script_paths: Array) -> void:
	_progress_bar.show()
	var i := 0
	for path in script_paths:
		
		# Skip already loaded scripts
		if scripts.size() < 0 and scripts[i].resource_path == path:
			i += 1
			continue
		
		_progress_bar.value = (i / script_paths.size()) * 100
		scripts.append(load(path))
		i += 1
		
	_progress_bar.hide()
	for script in scripts:
		_find_tokens(script.source_code, script.resource_path)
	print(todo_scripts)


func _find_tokens(text: String, script_path: String) -> void:
	### If tokens are found in the script then a TodoScript is created
	var regex = RegEx.new()
	if regex.compile(_combine_patterns()) == OK:
		var result : Array = regex.search_all(text)
		if result.empty():
			return
		todo_scripts.append(_create_todo_script(result, text, script_path))


func _create_todo_script(regex_results: Array, text: String, script_path: String) -> TodoScript:
	var todo_script = TodoScript.new()
	todo_script._uid_generator = _uid_generator
	todo_script.source_code = text
	todo_script.script_path = script_path
	todo_script.patterns = _patterns
	todo_script.regex_results = regex_results
	todo_script.find_todos()
	return todo_script


func _combine_patterns() -> String:
	if _patterns.size() == 1:
		return _patterns[0][0]
	else:
		var pattern_string := "((\\/\\*)|(#|\\/\\/))\\s*("
		for i in range(_patterns.size()):
			if i == 0:
				pattern_string += _patterns[i][0]
			else:
				pattern_string += "|" + _patterns[i][0]
		pattern_string += ")(?(2)[\\s\\S]*?\\*\\/|.*)"
		return pattern_string
