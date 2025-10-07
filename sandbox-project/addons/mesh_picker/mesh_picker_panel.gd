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
	
	# Set tooltip for the panel
	tooltip_text = "Select a node with mesh_data property to edit mesh resources"

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

func _on_mesh_changed(node_name: String, resource: Resource):
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
	
	# Load the template scene
	var entry_template = preload("res://addons/mesh_picker/mesh_picker_entry.tscn")
	
	# Create UI for each child MeshInstance3D
	for child_node in child_nodes:
		var entry = entry_template.instantiate()
		scroll_vbox.add_child(entry)
		
		# Get the mesh resource for this node
		var mesh_resource = null
		if String(child_node.name) in mesh_data:
			mesh_resource = mesh_data[String(child_node.name)]
		
		# Setup the entry
		entry.setup(child_node.name, mesh_resource)
		
		# Connect signals
		entry.mesh_changed.connect(_on_mesh_changed)
		entry.mesh_selected.connect(_on_mesh_selected)
		
		mesh_pickers.append({"node_name": child_node.name, "entry": entry})