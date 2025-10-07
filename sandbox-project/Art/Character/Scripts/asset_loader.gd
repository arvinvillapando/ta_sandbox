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
				_mesh_data[key] = resource
		update_mesh_instances()

func _ready():
	initialize_mesh_data()

func initialize_mesh_data():
	_mesh_data.clear()
	
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			if mesh_instance.mesh != null:
				_mesh_data[child.name] = mesh_instance.mesh

func update_mesh_instances():
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_instance = child as MeshInstance3D
			if child.name in _mesh_data:
				mesh_instance.mesh = _mesh_data[child.name]
