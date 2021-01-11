tool
extends EditorPlugin

const DockScene := preload("res://addons/Todo_Manager/UI/Dock.tscn")
const Dock := preload("res://addons/Todo_Manager/Dock.gd")
const Todo := preload("res://addons/Todo_Manager/Todo.gd")
const TodoScript := preload("res://addons/Todo_Manager/TodoScript.gd")
const ScriptManager := preload("res://addons/Todo_Manager/ScriptManager.gd")
const Uid := preload("res://addons/Todo_Manager/Uid.gd")

var _dockUI : Dock
var script_manager : ScriptManager
var uid_generator : Uid

var script_cache : Array # Stores scripts
var remove_queue : Array
var combined_pattern : String

var refresh_lock := false # makes sure _on_filesystem_changed only triggers once

func _enter_tree() -> void:
	_dockUI = DockScene.instance() as Dock
	add_control_to_bottom_panel(_dockUI, "TODO")
	connect("resource_saved", self, "check_saved_file")
	get_editor_interface().get_resource_filesystem().connect("filesystem_changed", self, "_on_filesystem_changed")
	get_editor_interface().get_file_system_dock().connect("file_removed", self, "queue_remove")
	get_editor_interface().get_script_editor().connect("editor_script_changed", self, "_on_active_script_changed")
	_dockUI.plugin = self
	
	uid_generator = Uid.new()
	script_manager = ScriptManager.new()
	script_manager.setup(uid_generator, _dockUI.progress_bar)
	_dockUI.todo_scripts = script_manager.find_scripts(_dockUI.patterns)
	
	_dockUI.build_tree()


func _exit_tree() -> void:
	remove_control_from_bottom_panel(_dockUI)
	_dockUI.queue_free()


func queue_remove(file: String):
	for i in _dockUI.todo_scripts.size() - 1:
		if _dockUI.todo_scripts[i].script_path == file:
			_dockUI.todo_scripts.remove(i)


func _on_filesystem_changed() -> void:
	if !refresh_lock:
		if _dockUI.auto_refresh:
			refresh_lock = true
			_dockUI.get_node("Timer").start()
			rescan_files()


func rescan_files() -> void:
	_dockUI.todo_scripts.clear()
	script_cache.clear()
	script_manager.find_scripts(_dockUI.patterns)
	_dockUI.build_tree()


func _on_active_script_changed(script) -> void:
	if _dockUI.tabs.current_tab == 1:
		_dockUI.build_tree()
