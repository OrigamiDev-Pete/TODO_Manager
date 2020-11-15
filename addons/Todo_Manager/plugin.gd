tool
extends EditorPlugin

const DockScene := preload("res://addons/Todo_Manager/Dock.tscn")
const Dock := preload("res://addons/Todo_Manager/Dock.gd")
const Todo := preload("res://addons/Todo_Manager/todo_class.gd")

var _dockUI : Dock
#var update_thread : Thread = Thread.new()

var script_cache : Array

var process_timer : int

func _enter_tree() -> void:
	_dockUI = DockScene.instance() as Control
	add_control_to_bottom_panel(_dockUI, "TODO")
	connect("resource_saved", self, "check_saved_file")
	_dockUI.plugin = self
	var scripts : Array = find_scripts()
	for script_path in scripts:
		find_tokens_from_path(script_path)
	_dockUI.build_tree()
	print("here")


func _exit_tree() -> void:
	remove_control_from_bottom_panel(_dockUI)
	_dockUI.queue_free()


func find_tokens_from_path(script_path: String) -> void:
	var file := File.new()
	file.open(script_path, File.READ)
	var contents := file.get_as_text()
	
	find_tokens(contents, script_path)
	
	# TODO: This is a test
	# This is only a test
	#TODO Hello.
	# HACK : THIS IS A HACK
	# TODO:
	#HACK
	# FIXME:


func find_tokens_from_script(script: Resource) -> void:
	find_tokens(script.source_code, script.resource_path)


func find_tokens(text: String, script_path: String) -> void:
	var regex = RegEx.new()
	if regex.compile("#\\s*\\bTODO\\b.*|#\\s*\\bHACK\\b.*") == OK:
		var result : Array = regex.search_all(text)
		if result.empty():
			return # No tokens found
		var match_found : bool
		var i := 0
		for todo_item in _dockUI.todo_items:
			if todo_item.script_path == script_path:
				match_found = true
				var updated_todo_item := update_todo_item(todo_item, result, text, script_path)
				_dockUI.todo_items.remove(i)
				_dockUI.todo_items.insert(i, updated_todo_item)
				break
			i += 1
		if !match_found:
			_dockUI.todo_items.append(create_todo_item(result, text, script_path))
#		var todo_item = TodoItem.new()
#		todo_item.script_path = script_path
#		for r in result:
#			var new_todo : Todo = create_todo(r.get_string(), script_path)
#			new_todo.line_number = get_line_number(r.get_string(), text)
#			todo_item.todos.append(new_todo)
#		_dockUI.todo_items.append(todo_item)


func create_todo_item(regex_results: Array, text: String, script_path: String) -> TodoItem:
	var todo_item = TodoItem.new()
	todo_item.script_path = script_path
	for r in regex_results:
		var new_todo : Todo = create_todo(r.get_string(), script_path)
		new_todo.line_number = get_line_number(r.get_string(), text)
		todo_item.todos.append(new_todo)
	return todo_item


func update_todo_item(todo_item: TodoItem, regex_results: Array, text: String, script_path: String) -> TodoItem:
	todo_item.todos.clear()
	for r in regex_results:
		var new_todo : Todo = create_todo(r.get_string(), script_path)
		new_todo.line_number = get_line_number(r.get_string(), text)
		todo_item.todos.append(new_todo)
	return todo_item


func get_line_number(what: String, from: String) -> int:
	var temp_array := from.split('\n')
	var lines := Array(temp_array)
	var line_number = lines.find(what) + 1
	var i := 1
	for line in lines:
		if what in line:
			line_number = i
			break
		i += 1
	return line_number


func check_saved_file(script: Resource) -> void:
	if script is Script:
		find_tokens_from_script(script)
	_dockUI.build_tree()


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


func rescan_files() -> void:
	var scripts : Array = find_scripts()
	for script_path in scripts:
		find_tokens_from_path(script_path)
	_dockUI.build_tree()


func create_todo(todo_string: String, script_path: String) -> Todo:
	var todo := Todo.new()
	var regex = RegEx.new()
#	for pattern in _dockUI.patterns:
#		if regex.compile("\\bTODO\\b") == OK:
#			var result : RegExMatch = regex.search(todo_string)
#			if result:
#				todo.pattern = pattern[0]
#				todo.title = result.strings[0]
#				print(todo.pattern.c_escape())
#			else:
#				continue
#		else:
#			printerr("Error compiling " + pattern[0])

	if regex.compile("\\bTODO|HACK\\b") == OK: # Finds Todo token
		var result : RegExMatch = regex.search(todo_string)
		todo.title = result.strings[0]
	else:
		printerr("Error compiling TODO RegEx")
	
	todo.content = todo_string
	todo.script_path = script_path
	
	return todo

class TodoItem:
	var script_path : String
	var todos : Array
	
	func get_short_path() -> String:
		var temp_array := script_path.rsplit('/', false, 1)
		var short_path := temp_array[1]
		return short_path
