tool
extends Reference
### This class keeps track of all the scripts in a project and acts as an
### interface between the filesystem and the rest of the plugin.

const TodoScript := preload("res://addons/Todo_Manager/TodoScript.gd")
const Uid := preload("res://addons/Todo_Manager/Uid.gd")

var _uid_generator : Uid # 'global' reference to UID generator
var _progress : float
var _progress_bar : ProgressBar

var scripts : Array # Stores an array of TodoScript objects


func setup(u: Uid, pb: ProgressBar) -> void:
	_uid_generator = u
	_progress_bar = pb
	find_scripts()


func find_scripts() -> void:
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
	
	_load_todo_scripts(script_paths)


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


func _load_todo_scripts(script_paths: Array) -> void:
	_progress_bar.show()
	_progress = 0
	for path in script_paths:
		_progress_bar.value = (_progress / script_paths.size()) * 100
		var todo_script := TodoScript.new()
		todo_script.initialize(_uid_generator, path)
		
		var file := File.new()
		file.open(path, File.READ)
		todo_script.source_code = file.get_as_text()
		file.close()
		
		scripts.append(todo_script)
		_progress += 1
		
		
	_progress_bar.hide()
