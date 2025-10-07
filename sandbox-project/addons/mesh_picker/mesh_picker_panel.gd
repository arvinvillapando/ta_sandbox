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

func _on_mesh_selected(node_name: String, resource: Resource):
	print("Panel: Resource selected for ", node_name, " - ", resource)
	print("Panel: Before update - Dictionary has ", mesh_data.size(), " entries: ", mesh_data.keys())
	# Update the dictionary directly since we have the node name
	if resource and resource is Mesh:
		mesh_data[node_name] = resource
		print("Panel: Added mesh for ", node_name)
	else:
		mesh_data.erase(node_name)
		print("Panel: Removed mesh for ", node_name)
	
	print("Panel: After update - Dictionary has ", mesh_data.size(), " entries: ", mesh_data.keys())
	# Apply changes to the target object using the setter
	target_object.mesh_data = mesh_data
	print("Panel: Called setter on target object")
	print("Panel: Target object dictionary now has ", target_object.mesh_data.size(), " entries")

func _on_mesh_changed(resource: Resource):
	# Find which picker triggered this by comparing the resource
	for picker_data in mesh_pickers:
		if picker_data["picker"].edited_resource == resource:
			var node_name = picker_data["node_name"]
			print("Panel: Mesh changed for ", node_name, " to ", resource)
			# Update the dictionary
			if resource and resource is Mesh:
				mesh_data[node_name] = resource
			else:
				mesh_data.erase(node_name)
			
			print("Panel: Dictionary now has ", mesh_data.size(), " entries: ", mesh_data.keys())
			# Apply changes to the target object using the setter
			target_object.mesh_data = mesh_data
			print("Panel: Called setter on target object")
			print("Panel: Target object dictionary now has ", target_object.mesh_data.size(), " entries")
			break

func setup(obj):
	target_object = obj
	refresh_data()
	update_ui()

func refresh_data():
	if target_object:
		mesh_data.clear()
		child_nodes.clear()
		
		print("Panel: Found child nodes:")
		for child in target_object.get_children():
			if child is MeshInstance3D:
				print("  - ", child.name, " (MeshInstance3D)")
				child_nodes.append(child)
				# Populate dictionary directly from the MeshInstance3D
				if child.mesh != null:
					mesh_data[String(child.name)] = child.mesh
		
		print("Panel: Dictionary keys: ", mesh_data.keys())

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
		
		# Connect signals to update the dictionary
		mesh_picker.resource_changed.connect(_on_mesh_changed)
		mesh_picker.resource_selected.connect(_on_mesh_selected.bind(child_node.name))
		hbox.add_child(mesh_picker)
		
		mesh_pickers.append({"node_name": child_node.name, "picker": mesh_picker})