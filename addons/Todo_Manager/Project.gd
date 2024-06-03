@tool
extends Panel

signal tree_built # used for debugging

const Todo := preload("res://addons/Todo_Manager/todo_class.gd")

var _full_path := false

@onready var tree := $Tree as Tree

func build_tree(todo_items : Array, ignore_paths : Array, patterns : Array, cased_patterns: Array[String], _sort_type: int, full_path : bool) -> void:
	_full_path = full_path
	tree.clear()
	todo_items.sort_custom([sort_alphabetical, sort_backwards, sort_script_lmt][_sort_type])
	var root := tree.create_item()
	root.set_text(0, "Scripts")
	for todo_item in todo_items:
		var ignore := false
		for ignore_path in ignore_paths:
			var script_path : String = todo_item.script_path
			if script_path.begins_with(ignore_path) or script_path.begins_with("res://" + ignore_path) or script_path.begins_with("res:///" + ignore_path):
				ignore = true
				break
		if ignore:
			continue
		var script := tree.create_item(root)
		var text := "%s ------- %s" % [
			todo_item.script_path if full_path else todo_item.get_short_path(),
			"" if _sort_type != 2 else _datetime_of_file_path(todo_item.script_path)
		]
		script.set_text(0, text)
		script.set_metadata(0, todo_item)
		for todo in todo_item.todos:
			var item := tree.create_item(script)
			var content_header : String = todo.content
			if "\n" in todo.content:
				content_header = content_header.split("\n")[0] + "..."
			item.set_text(0, "(%0) - %1".format([todo.line_number, content_header], "%_"))
			item.set_tooltip_text(0, todo.content)
			item.set_metadata(0, todo)
			for i in range(0, len(cased_patterns)):
				if cased_patterns[i] == todo.pattern:
					item.set_custom_color(0, patterns[i][1])
	emit_signal("tree_built")

func _datetime_of_file_path(path: String) -> String:
	var unix_time := FileAccess.get_modified_time(path)
	var timezone_dict := Time.get_time_zone_from_system()
	var time_string := Time.get_datetime_string_from_unix_time(unix_time + timezone_dict.bias * 60.0, true)
	return time_string

func sort_alphabetical(a, b) -> bool:
	if _full_path:
		if a.script_path < b.script_path:
			return true
		else:
			return false
	else:
		if a.get_short_path() < b.get_short_path():
			return true
		else:
			return false

func sort_backwards(a, b) -> bool:
	return sort_alphabetical(b, a)

func sort_script_lmt(a, b) -> bool:
	return FileAccess.get_modified_time(a.script_path) > FileAccess.get_modified_time(b.script_path)
