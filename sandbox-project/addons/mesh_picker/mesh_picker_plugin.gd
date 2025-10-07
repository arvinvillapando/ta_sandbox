@tool
extends EditorPlugin

var mesh_picker_inspector_plugin
var mesh_picker_panel
var plugin_added = false

func _enter_tree():
	# Create the inspector plugin directly
	mesh_picker_inspector_plugin = MeshPickerInspectorPlugin.new()
	mesh_picker_inspector_plugin.editor_interface = get_editor_interface()
	mesh_picker_inspector_plugin.main_plugin = self
	
	add_inspector_plugin(mesh_picker_inspector_plugin)
	plugin_added = true
	
	# Create the docked panel
	var scene = preload("res://addons/mesh_picker/mesh_picker_panel.tscn")
	mesh_picker_panel = scene.instantiate()
	mesh_picker_panel.name = "Data Editor"
	add_control_to_dock(DOCK_SLOT_LEFT_UL, mesh_picker_panel)
	
	# Wait for the panel to be ready
	await get_tree().process_frame

func _exit_tree():
	if plugin_added and mesh_picker_inspector_plugin != null:
		remove_inspector_plugin(mesh_picker_inspector_plugin)
		plugin_added = false
	
	if mesh_picker_panel != null:
		remove_control_from_docks(mesh_picker_panel)

func _can_handle(object):
	# Check if the object has the mesh_data property and the methods we need
	var has_children = object.has_method("get_children")
	var has_init = object.has_method("initialize_mesh_data")
	print("Mesh Picker Plugin: Checking object ", object.name, " - has_children: ", has_children, " has_init: ", has_init)
	return has_children and has_init

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "mesh_data":
		var button = Button.new()
		button.text = "Edit Mesh Data..."
		button.pressed.connect(_on_edit_mesh_data.bind(object))
		mesh_picker_inspector_plugin.add_custom_control(button)
		return true
	return false

func _on_edit_mesh_data(object):
	var dialog = preload("res://addons/mesh_picker/mesh_picker_dialog.gd").new()
	dialog.setup(object)
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()

class MeshPickerInspectorPlugin extends EditorInspectorPlugin:
	var editor_interface
	var main_plugin
	
	func _can_handle(object):
		# Only handle Node objects, not editor settings or other objects
		if not object is Node:
			return false
			
		# Check if the object has the mesh_data property
		var has_get = object.has_method("get")
		var has_mesh_data = "mesh_data" in object
		print("Mesh Picker Plugin: Checking object ", object.name, " - has_get: ", has_get, " has_mesh_data: ", has_mesh_data)
		return has_get and has_mesh_data

	func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
		print("Mesh Picker Plugin: Parsing property ", name, " for object ", object.name)
		if name == "mesh_data":
			print("Mesh Picker Plugin: Found mesh_data property, creating button")
			var button = Button.new()
			button.text = "Edit Mesh Data..."
			button.pressed.connect(_on_edit_mesh_data.bind(object))
			add_custom_control(button)
			return true
		return false

	func _on_edit_mesh_data(object):
		# Show the docked panel and set the target object
		if main_plugin and main_plugin.mesh_picker_panel:
			main_plugin.mesh_picker_panel.setup(object)
			main_plugin.mesh_picker_panel.visible = true