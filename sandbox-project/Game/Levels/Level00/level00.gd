extends Node3D

@onready var character_controller = $CharacterController
@onready var camera = $Camera3D

var camera_offset: Vector3

func _ready():
	# Store the camera's initial offset from the character
	if character_controller and camera:
		camera_offset = camera.position - character_controller.position

func _process(delta):
	# Update camera position to follow character (no rotation)
	if character_controller and camera:
		camera.position = character_controller.position + camera_offset
