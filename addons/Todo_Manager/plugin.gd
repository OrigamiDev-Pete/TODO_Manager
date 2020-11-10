tool
extends EditorPlugin

const DockScene := preload("res://addons/Todo_Manager/Dock.tscn")

var _dockUI : Control
var update_thread : Thread = Thread.new()

func _enter_tree() -> void:
	_dockUI = DockScene.instance() as Control
	add_control_to_bottom_panel(_dockUI, "TODO")
	find_scripts()


func _exit_tree() -> void:
	remove_control_from_bottom_panel(_dockUI)


func find_scripts() -> Array:
	var scripts : Array
	var directories : Array
	var dir : Directory = Directory.new()
	print("### FIRST PHASE ###")
	if dir.open("res://") == OK:
		dir.list_dir_begin(true, true)
		var file_name : String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
				if file_name == "Scripts":
					pass
					# DO THIS FIRST
				else:
					directories.append(file_name)
			else:
				print("Found file: " + file_name)
				if file_name.ends_with(".gd"):
					scripts.append(file_name)
			file_name = dir.get_next()
	else:
		print("There was an error")
	print(directories)
	
	# NEED TO FIX RECURSION
	
	print("### SECOND PHASE ###")
	for path in directories:
		if dir.change_dir(path) == OK:
			dir.list_dir_begin(true, true)
			var file_name : String = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
					if file_name == "Scripts":
						pass
						# DO THIS FIRST
					else:
						directories.append(file_name)
				else:
					print("Found file: " + file_name)
					if file_name.ends_with(".gd"):
						scripts.append(file_name)
				file_name = dir.get_next()
		else:
			print("There was an error at " + path)
		# Return to parent directory before continuing
		dir.change_dir("..")
	
	print(scripts)
	return scripts

class Todo:
	var title : String
	var content : String
	var in_script : Script
