tool
extends EditorPlugin

const DockScene := preload("res://addons/Todo_Manager/Dock.tscn")
const Dock := preload("res://addons/Todo_Manager/Dock.gd")
const Todo := preload("res://addons/Todo_Manager/todo_class.gd")

var _dockUI : Dock
var update_thread : Thread = Thread.new()

func _enter_tree() -> void:
	_dockUI = DockScene.instance() as Control
	add_control_to_bottom_panel(_dockUI, "TODO")
	connect("resource_saved", self, "test2")
	var scripts := find_scripts()
	for script in scripts:
		find_tokens(script)
	_dockUI.build_tree()


func _exit_tree() -> void:
	remove_control_from_bottom_panel(_dockUI)
	_dockUI.queue_free()

func test2(resource: Resource):
	print("resource saved")
	print(resource)


func find_tokens(script_path: String) -> void:
	var file := File.new()
	file.open(script_path, File.READ)
	var contents := file.get_as_text()
	
	var regex = RegEx.new()
	if regex.compile("#\\s*\\bTODO|HACK\\b.*") == OK:
		var result : Array = regex.search_all(contents)
		var todo_item = TodoItem.new()
		todo_item.script_path = script_path
		for r in result:
			var new_todo : Todo.Todo = Todo.create_todo(r.get_string(), script_path)
			todo_item.todos.append(new_todo)
		_dockUI.todo_items.append(todo_item)
			
	# TODO: This is a test
	# This is only a test
	#TODO Hello.

func check_saved_file(script: Resource) -> void:
	pass


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


func get_dir_contents(dir: Directory, scripts: Array, directory_queue: Array) -> void:
	dir.list_dir_begin(true, true)
	var file_name : String = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			print("Found directory: " + file_name)
			directory_queue.append(dir.get_current_dir() + "/" + file_name)
		else:
			print("Found file: " + file_name)
			if file_name.ends_with(".gd"):
				scripts.append(dir.get_current_dir() + "/" + file_name)
		file_name = dir.get_next()


class TodoItem:
	var script_path : String
	var todos : Array
