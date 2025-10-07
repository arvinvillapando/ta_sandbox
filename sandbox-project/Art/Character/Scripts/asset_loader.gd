@tool
extends Node

var _mesh_data: Dictionary = {}

@export var mesh_data: Dictionary = {}:
	get:
		return _mesh_data
	set(value):
		# Filter to only accept Mesh resources
		_mesh_data.clear()
		for key in value.keys():
			var resource = value[key]
			if resource is Mesh:
				_mesh_data[String(key)] = resource
		print("Asset Loader: Setter received dictionary with keys: ", value.keys())
		print("Asset Loader: Filtered dictionary now has keys: ", _mesh_data.keys())
		update_mesh_instances()

func _ready():
	initialize_mesh_data()

func initialize_mesh_data():
	_mesh_data.clear()
	
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			if mesh_instance.mesh != null:
				_mesh_data[String(child.name)] = mesh_instance.mesh

func update_mesh_instances():
	print("Asset Loader: update_mesh_instances called")
	print("Asset Loader: Dictionary has keys: ", _mesh_data.keys())
	for child in get_children():
		if child is MeshInstance3D:
			print("Asset Loader: Found MeshInstance3D child: ", child.name)
			var mesh_instance = child as MeshInstance3D
			var child_name_str = String(child.name)
			print("Asset Loader: Looking for key '", child_name_str, "' in dictionary")
			print("Asset Loader: Dictionary keys are: ", _mesh_data.keys())
			if child_name_str in _mesh_data:
				var mesh_resource = _mesh_data[child_name_str]
				print("Asset Loader: Found mesh resource: ", mesh_resource, " (type: ", typeof(mesh_resource), ")")
				mesh_instance.mesh = mesh_resource
			else:
				print("Asset Loader: No mesh data for ", child.name, " - clearing")
				mesh_instance.mesh = null
