tool
extends Reference
class_name TodoScript

const Todo := preload("res://addons/Todo_Manager/Todo.gd")
const Uid := preload("res://addons/Todo_Manager/Uid.gd")

var _uid_generator : Uid # 'global' reference to uid_generator

var script_path : String
var source_code : String
var patterns: Array
var regex_results : Array
var todos : Array


func initialize(u: Uid, path: String) -> void:
	_uid_generator = u
	script_path = path
	find_todos()


func find_todos():
	var last_line_number := 0
	var lines := source_code.split("\n")
	for r in regex_results:
		var new_todo : Todo = _create_todo(r.get_string())
		new_todo.line_number = _get_line_number(r.get_string(), last_line_number)
#		_create_id(new_todo # Buggy ###
		# GD Multiline comment
		var trailing_line := new_todo.line_number
		var should_break = false
		while trailing_line < lines.size() and lines[trailing_line].dedent().begins_with("#"):
			for other_r in regex_results:
				if lines[trailing_line] in other_r.get_string():
					should_break = true
					break
			if should_break:
				break

			new_todo.content += "\n" + lines[trailing_line]
			trailing_line += 1

		last_line_number = new_todo.line_number
		todos.append(new_todo)


func _create_todo(todo_string: String) -> Todo:
	var todo := Todo.new()
	var regex = RegEx.new()
	for pattern in patterns:
		if regex.compile(pattern[0]) == OK:
			var result : RegExMatch = regex.search(todo_string)
			if result:
				todo.pattern = pattern[0]
				todo.title = result.strings[0]
			else:
				continue
		else:
			printerr("Error compiling " + pattern[0])
	
	todo.content = todo_string
	todo.script_path = script_path
	return todo


func _get_line_number(what: String,  start := 0) -> int:
	what = what.split('\n')[0] # Match first line of multiline C# comments
	var temp_array := source_code.split('\n')
	var lines := Array(temp_array)
	var line_number # = lines.find(what) + 1
	for i in range(start, lines.size()):
		if what in lines[i]:
			line_number = i + 1 # +1 to account of 0-based array vs 1-based line numbers
			break
		else:
			line_number = 0 # This is an error
	return line_number


func _create_id(todo: Todo) -> void:
	todo.id = _uid_generator.get_next_id()
	# Write ID onto script
	var file := File.new()
	file.open(script_path, File.READ_WRITE)
	var text := file.get_as_text()
	var text_array : PoolStringArray = text.split('\n')
	var line := text_array[todo.line_number-1].strip_edges()
	line = line.insert(line.length(), " @" + str(todo.id))
	text_array[todo.line_number-1] = line
	for string in text_array:
		file.store_line(string)
	file.close()


func get_short_path() -> String:
	var temp_array := script_path.rsplit('/', false, 1)
	var short_path : String
	if !temp_array[1]:
		short_path = "(!)" + temp_array[0]
	else:
		short_path = temp_array[1]
	return short_path
