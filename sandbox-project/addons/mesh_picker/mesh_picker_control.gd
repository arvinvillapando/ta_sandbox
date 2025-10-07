@tool
extends Control

class_name MeshPickerControl

var target_object
var mesh_data: Dictionary = {}
var child_nodes: Array = []

func setup(obj):
	target_object = obj
	refresh_data()
	create_ui()

func refresh_data():
	if target_object:
		mesh_data = target_object.mesh_data
		child_nodes.clear()
		
		for child in target_object.get_children():
			if child is MeshInstance3D:
				child_nodes.append(child)

func create_ui():
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)
	
	# Add some spacing at the top
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 8
	vbox.add_child(spacer)
	
	var title_label = Label.new()
	title_label.text = "Mesh Data"
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(title_label)
	
	# Add separator
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Create UI for each child MeshInstance3D
	for child_node in child_nodes:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		vbox.add_child(hbox)
		
		var name_label = Label.new()
		name_label.text = child_node.name + ":"
		name_label.custom_minimum_size.x = 100
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(name_label)
		
		var mesh_picker = EditorResourcePicker.new()
		mesh_picker.base_type = "Mesh"
		mesh_picker.editable = true
		mesh_picker.custom_minimum_size.x = 200
		
		# Set current mesh if it exists
		if child_node.name in mesh_data:
			mesh_picker.edited_resource = mesh_data[child_node.name]
		
		# Connect signal to update the dictionary
		mesh_picker.resource_changed.connect(_on_mesh_changed.bind(child_node.name))
		hbox.add_child(mesh_picker)
	
	# Add some spacing at the bottom
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size.y = 8
	vbox.add_child(bottom_spacer)
	
	# Set minimum size for the control
	custom_minimum_size.y = vbox.get_child_count() * 30 + 20

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
