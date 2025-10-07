extends CharacterBody3D

class_name CharacterController

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var acceleration: float = 10.0
@export var friction: float = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# References to character components
var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var mesh_instances: Array[MeshInstance3D] = []
var camera: Camera3D

# Character turning
var turn_speed: float = 10.0
var target_rotation: float = 0.0

func _ready():
	# Find and store references to character components
	find_character_components()
	
	# Get camera reference
	camera = get_node("Camera3D")
	
	# Print found components for debugging
	print("Character Controller: Found components:")
	print("  - Animation Player: ", animation_player != null)
	print("  - Skeleton: ", skeleton != null)
	print("  - Mesh Instances: ", mesh_instances.size())
	print("  - Camera: ", camera != null)

func find_character_components():
	# Find AnimationPlayer
	animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	
	# Find Skeleton3D
	skeleton = find_child("Skeleton3D", true, false) as Skeleton3D
	
	# Find all MeshInstance3D nodes
	mesh_instances.clear()
	find_mesh_instances_recursive(self)

func find_mesh_instances_recursive(node: Node):
	for child in node.get_children():
		if child is MeshInstance3D:
			mesh_instances.append(child as MeshInstance3D)
		find_mesh_instances_recursive(child)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1  # Left = negative X
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1  # Right = positive X
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1  # Up = negative Z
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1  # Down = positive Z

	# Handle movement
	if input_dir != Vector2.ZERO:
		# Simple world space movement (top-down view)
		var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
		
		# Calculate target rotation based on movement direction
		target_rotation = atan2(direction.x, direction.z)
		
		# Apply acceleration
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		
		# Play walk animation if available
		if animation_player and animation_player.has_animation("Mini_Walk"):
			if not animation_player.is_playing() or animation_player.current_animation != "Mini_Walk":
				animation_player.play("Mini_Walk")
	else:
		# Apply friction when not moving
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		
		# Play idle animation if available
		if animation_player and animation_player.has_animation("Mini_Idle"):
			if not animation_player.is_playing() or animation_player.current_animation != "Mini_Idle":
				animation_player.play("Mini_Idle")
	
	# Handle character turning
	handle_character_turning(delta)

	# Move the character
	move_and_slide()

func handle_character_turning(delta: float):
	# Smoothly rotate the character towards the target rotation
	var current_rotation = rotation.y
	var rotation_difference = target_rotation - current_rotation
	
	# Normalize rotation difference to shortest path
	while rotation_difference > PI:
		rotation_difference -= 2 * PI
	while rotation_difference < -PI:
		rotation_difference += 2 * PI
	
	# Apply rotation
	rotation.y = current_rotation + rotation_difference * turn_speed * delta


# Function to insert a CHR scene
func insert_character_scene(chr_scene_path: String):
	# Load and instantiate the CHR scene
	var chr_scene = load(chr_scene_path)
	if chr_scene:
		var chr_instance = chr_scene.instantiate()
		add_child(chr_instance)
		
		# Re-find components after adding the character
		find_character_components()
		
		print("Character Controller: Inserted character scene: ", chr_scene_path)
		return true
	else:
		print("Character Controller: Failed to load character scene: ", chr_scene_path)
		return false
