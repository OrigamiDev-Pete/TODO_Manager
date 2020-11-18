tool
extends EditorPlugin

const DockScene := preload("res://addons/Todo_Manager/Dock.tscn")
const Dock := preload("res://addons/Todo_Manager/Dock.gd")
const Todo := preload("res://addons/Todo_Manager/todo_class.gd")

var _dockUI : Dock
#var update_thread : Thread = Thread.new()

var script_cache : Array
var remove_queue : Array
var combined_pattern : String

var process_timer : int

func _enter_tree() -> void:
	_dockUI = DockScene.instance() as Control
	add_control_to_bottom_panel(_dockUI, "TODO")
	connect("resource_saved", self, "check_saved_file")
	get_editor_interface().get_resource_filesystem().connect("filesystem_changed", self, "rescan_files")
	get_editor_interface().get_file_system_dock().connect("file_removed", self, "queue_remove")
	_dockUI.plugin = self
	combined_pattern = combine_patterns(_dockUI.patterns)
	find_tokens_from_path(find_scripts())
	_dockUI.build_tree()


func _exit_tree() -> void:
	remove_control_from_bottom_panel(_dockUI)
	_dockUI.queue_free()


func queue_remove(file: String):
	for i in _dockUI.todo_items.size() - 1:
		if _dockUI.todo_items[i].script_path == file:
			_dockUI.todo_items.remove(i)


func find_tokens_from_path(scripts: Array) -> void:
	for script_path in scripts:
		var file := File.new()
		file.open(script_path, File.READ)
		var contents := file.get_as_text()
		
		find_tokens(contents, script_path)

func find_tokens_from_script(script: Resource) -> void:
	find_tokens(script.source_code, script.resource_path)


func find_tokens(text: String, script_path: String) -> void:
	var regex = RegEx.new()
#	if regex.compile("#\\s*\\bTODO\\b.*|#\\s*\\bHACK\\b.*") == OK:
	if regex.compile(combined_pattern) == OK:
		var result : Array = regex.search_all(text)
		if result.empty():
			for i in _dockUI.todo_items.size():
				if _dockUI.todo_items[i].script_path == script_path:
					_dockUI.todo_items.remove(i)
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
	### FIRST PHASE ###
	if dir.open("res://") == OK:
		get_dir_contents(dir, scripts, directory_queue)
	else:
		printerr("TODO_Manager: There was an error during find_scripts() ### First Phase ###")
	
	### SECOND PHASE ###
	while not directory_queue.empty():
		if dir.change_dir(directory_queue[0]) == OK:
			get_dir_contents(dir, scripts, directory_queue)
		else:
			printerr("TODO_Manager: There was an error at: " + directory_queue[0])
		directory_queue.pop_front()
	
	cache_scripts(scripts)
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
	_dockUI.todo_items.clear()
	script_cache.clear()
	combined_pattern = combine_patterns(_dockUI.patterns)
	find_tokens_from_path(find_scripts())
	_dockUI.build_tree()


func combine_patterns(patterns: Array) -> String:
	if patterns.size() == 1:
		return patterns[0][0]
	else:
		var pattern_string : String
		for i in range(patterns.size()):
			if i == 0:
				pattern_string = "#\\s*" + patterns[i][0] + ".*"
			else:
				pattern_string += "|" + "#\\s*" + patterns[i][0]  + ".*"
		return pattern_string


func create_todo(todo_string: String, script_path: String) -> Todo:
	var todo := Todo.new()
	var regex = RegEx.new()
	for pattern in _dockUI.patterns:
		if regex.compile(pattern[0]) == OK:
			var result : RegExMatch = regex.search(todo_string)
			if result:
				todo.pattern = pattern[0]
				todo.title = result.strings[0]
			else:
				continue
		else:
			printerr("Error compiling " + pattern[0])

#	if regex.compile("\\bTODO|HACK\\b") == OK: # Finds Todo token
#		var result : RegExMatch = regex.search(todo_string)
#		todo.title = result.strings[0]
#	else:
#		printerr("Error compiling TODO RegEx")
	
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
