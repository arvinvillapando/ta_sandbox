@tool
extends AcceptDialog

class_name MeshPickerDialog

var target_object
var mesh_data: Dictionary = {}
var child_nodes: Array = []
var mesh_pickers: Array = []

func setup(obj):
	target_object = obj
	refresh_data()
	create_dialog()

func refresh_data():
	if target_object:
		mesh_data = target_object.mesh_data
		child_nodes.clear()
		
		for child in target_object.get_children():
			if child is MeshInstance3D:
				child_nodes.append(child)

func create_dialog():
	title = "Mesh Data Editor"
	size = Vector2i(500, 400)
	
	# Clear existing children (keep the dialog's built-in buttons)
	for child in get_children():
		if child.get_class() != "Button":
			child.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)
	
	# Add title label
	var title_label = Label.new()
	title_label.text = "Configure Mesh Resources for Child Nodes"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# Add separator
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Create scroll container for mesh pickers
	var scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size.y = 300
	vbox.add_child(scroll_container)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.add_theme_constant_override("separation", 8)
	scroll_container.add_child(scroll_vbox)
	
	mesh_pickers.clear()
	
	# Create UI for each child MeshInstance3D
	for child_node in child_nodes:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		scroll_vbox.add_child(hbox)
		
		var name_label = Label.new()
		name_label.text = child_node.name + ":"
		name_label.custom_minimum_size.x = 120
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(name_label)
		
		var mesh_picker = EditorResourcePicker.new()
		mesh_picker.base_type = "Mesh"
		mesh_picker.editable = true
		mesh_picker.custom_minimum_size.x = 300
		
		# Set current mesh if it exists
		if child_node.name in mesh_data:
			mesh_picker.edited_resource = mesh_data[child_node.name]
		
		mesh_pickers.append({"node_name": child_node.name, "picker": mesh_picker})
		hbox.add_child(mesh_picker)
	
	# Connect dialog signals
	confirmed.connect(_on_dialog_confirmed)
	close_requested.connect(_on_dialog_cancelled)

func _on_dialog_confirmed():
	# Update the dictionary with current values
	mesh_data.clear()
	
	for picker_data in mesh_pickers:
		var node_name = picker_data["node_name"]
		var picker = picker_data["picker"]
		
		if picker.edited_resource and picker.edited_resource is Mesh:
			mesh_data[node_name] = picker.edited_resource
	
	# Apply changes to the target object
	if target_object:
		target_object.mesh_data = mesh_data
		
		# Update the corresponding MeshInstance3D nodes
		for child in target_object.get_children():
			if child.name in mesh_data and child is MeshInstance3D:
				child.mesh = mesh_data[child.name]
			elif child is MeshInstance3D:
				child.mesh = null

func _on_dialog_cancelled():
	# Reset to original values
	refresh_data()
	popup_centered()
