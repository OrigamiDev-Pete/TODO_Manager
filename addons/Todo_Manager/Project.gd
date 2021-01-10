tool
extends Panel

signal tree_built # used for debugging

const Todo := preload("res://addons/Todo_Manager/Todo.gd")

var sort_alphabetical := true

onready var tree := $Tree as Tree

func build_tree(todo_scripts : Array, ignore_paths : Array, patterns : Array, sort_alphabetical : bool, full_path : bool) -> void:
	tree.clear()
	if sort_alphabetical:
		todo_scripts.sort_custom(self, "sort_alphabetical")
	else:
		todo_scripts.sort_custom(self, "sort_backwards")
	var root := tree.create_item()
	root.set_text(0, "Scripts")
	for todo_script in todo_scripts:
		var ignore := false
		for ignore_path in ignore_paths:
			var script_path : String = todo_script.script_path
			if script_path.begins_with(ignore_path) or script_path.begins_with("res://" + ignore_path) or script_path.begins_with("res:///" + ignore_path):
				ignore = true
				break
		if ignore: 
			continue
		var script := tree.create_item(root)
		if full_path:
			script.set_text(0, todo_script.script_path + " -------")
		else:
			script.set_text(0, todo_script.get_short_path() + " -------")
		script.set_metadata(0, todo_script)
		for todo in todo_script.todos:
			var item := tree.create_item(script)
			var content_header : String = todo.content
			if "\n" in todo.content:
				content_header = content_header.split("\n")[0] + "..."
			item.set_text(0, "(%0) - %1".format([todo.line_number, content_header], "%_"))
			item.set_tooltip(0, todo.content)
			item.set_metadata(0, todo)
			for pattern in patterns:
				if pattern[0] == todo.pattern:
					item.set_custom_color(0, pattern[1])
	emit_signal("tree_built")


func sort_alphabetical(a, b) -> bool:
	if a.script_path > b.script_path:
		return true
	else:
		return false

func sort_backwards(a, b) -> bool:
	if a.script_path < b.script_path:
		return true
	else:
		return false
