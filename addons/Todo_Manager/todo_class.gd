extends Reference

class Todo:
	enum {TODO, HACK}

	var title : String
	var content : String
	var script_path : String

static func create_todo(todo_string: String, script_path: String) -> Todo:
	print(todo_string)
	var todo := Todo.new()
	var regex = RegEx.new()
	if regex.compile("\\bTODO|HACK\\b") == OK: # Finds Todo token
		var result : RegExMatch = regex.search(todo_string)
		todo.title = result.to_string()
		if regex.compile("#\\s*\\bTODO\\b\\s*:*\\s*"): # Gets the Todo prefix to be removed
			result = regex.search(todo_string)
			todo.content = todo_string.lstrip(result.get_string())
			
	else:
		printerr("Error compiling TODO RegEx")
	return todo
