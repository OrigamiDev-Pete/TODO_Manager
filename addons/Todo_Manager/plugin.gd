tool
extends EditorPlugin

const DockScene := preload("res://addons/Todo_Manager/Dock.tscn")
const Dock := preload("res://addons/Todo_Manager/Dock.gd")
const Todo := preload("res://addons/Todo_Manager/todo_class.gd")

var _dockUI : Dock
var update_thread : Thread = Thread.new()

var script_cache : Array

func _enter_tree() -> void:
	_dockUI = DockScene.instance() as Control
	add_control_to_bottom_panel(_dockUI, "TODO")
	connect("resource_saved", self, "check_saved_file")
	var scripts := find_scripts()
	for script in scripts:
		find_tokens(script)
	_dockUI.build_tree()


func _exit_tree() -> void:
	remove_control_from_bottom_panel(_dockUI)
	_dockUI.queue_free()


func find_tokens(script_path: String) -> void:
	var file := File.new()
	file.open(script_path, File.READ)
	var contents := file.get_as_text()
	
	var regex = RegEx.new()
	if regex.compile("#\\s*\\bTODO\\b.*|#\\s*\\bHACK\\b.*") == OK:
		var result : Array = regex.search_all(contents)
		var todo_item = TodoItem.new()
		todo_item.script_path = script_path
		for r in result:
			var new_todo : Todo = create_todo(r.get_string(), script_path)
			todo_item.todos.append(new_todo)
		_dockUI.todo_items.append(todo_item)
			
	# TODO: This is a test
	# This is only a test
	#TODO Hello.
	# HACK : THIS IS A HACK

func check_saved_file(script: Resource) -> void:
	print("This resource was just saved:")
	print(script)


func find_scripts() -> Array:
	var scripts : Array
	var directory_queue : Array
	var dir : Directory = Directory.new()
	print("### FIRST PHASE ###")
	if dir.open("res://") == OK:
		get_dir_contents(dir, scripts, directory_queue)
	else:
		print("There was an error")
	print(directory_queue)
	
	print("### SECOND PHASE ###")
	while not directory_queue.empty():
		if dir.change_dir(directory_queue[0]) == OK:
			get_dir_contents(dir, scripts, directory_queue)
		else:
			print("There was an error at: " + directory_queue[0])
		directory_queue.pop_front()
	
	print(scripts)
	return scripts


func cache_scripts(scripts: Array) -> void:
	for script in scripts:
		if not script_cache.has(script):
			script_cache.append(script)


func get_dir_contents(dir: Directory, scripts: Array, directory_queue: Array) -> void:
	dir.list_dir_begin(true, true)
	var file_name : String = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			if file_name == ".import": # Skip .import folder which should never have scripts
				pass
			else:
				directory_queue.append(dir.get_current_dir() + "/" + file_name)
		else:
			if file_name.ends_with(".gd") or file_name.ends_with(".cs"):
				scripts.append(dir.get_current_dir() + "/" + file_name)
		file_name = dir.get_next()


func create_todo(todo_string: String, script_path: String) -> Todo:
	var todo := Todo.new()
	var regex = RegEx.new()
	if regex.compile("\\bTODO|HACK\\b") == OK: # Finds Todo token
		var result : RegExMatch = regex.search(todo_string)
		todo.title = result.strings[0]
	else:
		printerr("Error compiling TODO RegEx")
	
	todo.content = todo_string
	
#	if regex.compile("#\\s*\\bTODO|HACK\\b\\s*:*\\s*") == OK: # Gets the Todo prefix to be removed
#		var result = regex.search(todo_string)
#		todo.content = todo_string.lstrip(result.get_string())
#		print(todo_string)
#	else:
#		printerr("Error compiling content RegEx")
	return todo

class TodoItem:
	var script_path : String
	var todos : Array
