@tool
extends Control

class_name MeshPickerEntry

signal mesh_changed(node_name: String, resource: Resource)
signal mesh_selected(node_name: String, resource: Resource)

var node_name: String = ""
var name_label: Label
var mesh_picker: EditorResourcePicker
var open_button: Button

func _ready():
	name_label = get_node("HBoxContainer/NameLabel")
	mesh_picker = get_node("HBoxContainer/MeshPicker")
	open_button = get_node("HBoxContainer/OpenButton")
	
	# Connect signals
	mesh_picker.resource_changed.connect(_on_mesh_changed)
	mesh_picker.resource_selected.connect(_on_mesh_selected)
	open_button.pressed.connect(_on_open_button_pressed)

func setup(node_name: String, mesh_resource: Resource = null):
	self.node_name = node_name
	name_label.text = node_name + ":"
	
	if mesh_resource:
		mesh_picker.edited_resource = mesh_resource
	else:
		mesh_picker.edited_resource = null

func _on_mesh_changed(resource: Resource):
	mesh_changed.emit(node_name, resource)

func _on_mesh_selected(resource: Resource):
	mesh_selected.emit(node_name, resource)

func _on_open_button_pressed():
	if mesh_picker.edited_resource:
		var resource = mesh_picker.edited_resource
		# Get the editor interface
		var editor_interface = EditorInterface
		
		# Select the resource in the file system
		if resource.resource_path != "":
			editor_interface.get_file_system_dock().navigate_to_path(resource.resource_path)
		
		# Load the resource in the inspector
		editor_interface.inspect_object(resource)
