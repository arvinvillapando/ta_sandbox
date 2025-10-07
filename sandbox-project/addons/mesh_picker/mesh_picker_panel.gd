@tool
extends Control

class_name MeshPickerPanel

var target_object
var mesh_data: Dictionary = {}
var child_nodes: Array = []
var mesh_pickers: Array = []
var scroll_vbox: VBoxContainer

func _ready():
	# Get reference to the scroll container from the scene
	scroll_vbox = get_node("VBoxContainer/ScrollContainer/ScrollVBox")

func setup(obj):
	target_object = obj
	refresh_data()
	update_ui()

func refresh_data():
	if target_object:
		mesh_data = target_object.mesh_data
		child_nodes.clear()
		
		for child in target_object.get_children():
			if child is MeshInstance3D:
				child_nodes.append(child)

func update_ui():
	# Check if scroll_vbox exists
	if not scroll_vbox:
		print("Error: scroll_vbox not found")
		return
	
	# Clear existing mesh pickers
	for child in scroll_vbox.get_children():
		child.queue_free()
	
	mesh_pickers.clear()
	
	# Create UI for each child MeshInstance3D
	for child_node in child_nodes:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_vbox.add_child(hbox)
		
		var name_label = Label.new()
		name_label.text = child_node.name + ":"
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		hbox.add_child(name_label)
		
		var mesh_picker = EditorResourcePicker.new()
		mesh_picker.base_type = "Mesh"
		mesh_picker.editable = true
		mesh_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Set current mesh if it exists
		if child_node.name in mesh_data:
			mesh_picker.edited_resource = mesh_data[child_node.name]
		
		# Connect signal to update the dictionary
		mesh_picker.resource_changed.connect(_on_mesh_changed.bind(child_node.name))
		hbox.add_child(mesh_picker)
		
		mesh_pickers.append({"node_name": child_node.name, "picker": mesh_picker})

func _on_mesh_changed(node_name: String, resource: Resource):
	if target_object:
		# Update the dictionary
		if resource and resource is Mesh:
			mesh_data[node_name] = resource
		else:
			mesh_data.erase(node_name)
		
		# Apply changes to the target object
		target_object.mesh_data = mesh_data
		
		# Update the corresponding MeshInstance3D
		for child in target_object.get_children():
			if child.name == node_name and child is MeshInstance3D:
				child.mesh = resource if resource is Mesh else null
				break