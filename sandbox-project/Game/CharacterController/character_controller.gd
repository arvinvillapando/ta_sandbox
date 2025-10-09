extends CharacterBody3D

class_name CharacterController

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var acceleration: float = 10.0
@export var friction: float = 10.0

# Camera controls
@export var camera_pitch_min: float = 30.0
@export var camera_pitch_max: float = 90.0
@export var camera_yaw_min: float = -180.0
@export var camera_yaw_max: float = 180.0
@export var mouse_sensitivity: float = 500.0  # Higher values = less sensitive

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

# Camera pitch control
var camera_pitch: float = 0.0
var camera_yaw: float = 0.0

# Character swapping
@export var character_list_resource: CharacterList
var current_character_index: int = 0
var current_character_node: Node3D

func _ready():
	# Find and store references to character components
	find_character_components()
	
	# Initialize current character node to the existing character in the scene
	current_character_node = find_child("CHR_Minis_Baseball", true, false) as Node3D
	if not current_character_node:
		# Try to find any character node that starts with "CHR_"
		for child in get_children():
			if child.name.begins_with("CHR_"):
				current_character_node = child
				break
	
	# Get camera reference - try to find it as a child or parent
	camera = find_child("Camera3D", true, false) as Camera3D
	if not camera:
		# If not found as child, try to find in parent scene
		var parent_scene = get_parent()
		if parent_scene:
			camera = parent_scene.find_child("Camera3D", true, false) as Camera3D
	
	# Print found components for debugging
	print("Character Controller: Found components:")
	print("  - Animation Player: ", animation_player != null)
	print("  - Skeleton: ", skeleton != null)
	print("  - Mesh Instances: ", mesh_instances.size())
	print("  - Camera: ", camera != null)
	print("  - Current Character Node: ", current_character_node != null)

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
	# Handle mouse input for camera pitch
	handle_mouse_input()
	
	# Handle character swapping
	if Input.is_action_just_pressed("swap_character"):  # Only custom action
		swap_character()
	
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
		var direction = Vector3.ZERO
		
		# Screen space movement - convert input to camera-relative direction
		if camera:
			var camera_basis = camera.global_transform.basis
			
			# Forward/backward relative to camera
			direction += camera_basis.z * input_dir.y  # Up/down input affects Z axis
			# Left/right relative to camera  
			direction += camera_basis.x * input_dir.x   # Left/right input affects X axis
			
			# Remove Y component to keep movement on horizontal plane
			direction.y = 0
			direction = direction.normalized()
		else:
			# Fallback to world space movement if no camera found
			direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
		
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

func handle_mouse_input():
	# Get mouse movement
	var mouse_delta = Input.get_last_mouse_velocity()
	
	# Update camera pitch and yaw based on mouse movement
	if camera:
		# Update pitch based on mouse Y movement
		camera_pitch -= mouse_delta.y / mouse_sensitivity
		
		# Update yaw based on mouse X movement
		camera_yaw -= mouse_delta.x / mouse_sensitivity
		
		# Clamp pitch to min/max values (convert degrees to radians)
		var pitch_min_rad = deg_to_rad(-camera_pitch_max)
		var pitch_max_rad = deg_to_rad(-camera_pitch_min)
		camera_pitch = clamp(camera_pitch, pitch_min_rad, pitch_max_rad)
		
		# Clamp yaw to min/max values (convert degrees to radians)
		var yaw_min_rad = deg_to_rad(camera_yaw_min)
		var yaw_max_rad = deg_to_rad(camera_yaw_max)
		camera_yaw = clamp(camera_yaw, yaw_min_rad, yaw_max_rad)
		
		# Apply pitch and yaw to camera rotation
		camera.rotation.x = camera_pitch
		camera.rotation.y = camera_yaw

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

func swap_character():
	print("Tab pressed - attempting to swap character")
	
	if not character_list_resource:
		print("No character list resource assigned!")
		return
	
	print("Current character index: ", current_character_index)
	print("Available characters: ", character_list_resource.get_character_count())
	
	# Cycle to next character
	current_character_index = (current_character_index + 1) % character_list_resource.get_character_count()
	print("New character index: ", current_character_index)
	
	# Remove current character immediately if it exists
	if current_character_node:
		print("Removing current character")
		remove_child(current_character_node)
		current_character_node.free()
	
	# Load and instantiate new character from resource
	var character_scene = character_list_resource.get_character_at_index(current_character_index)
	if character_scene:
		print("Loading character: ", character_scene.resource_path)
		print("Character name: ", character_scene.resource_path.get_file().get_basename())
		current_character_node = character_scene.instantiate()
		add_child(current_character_node)
		
		# Re-find components after adding the character
		find_character_components()
		
		print("Successfully swapped to character: ", character_scene.resource_path)
	else:
		print("Failed to load character scene at index: ", current_character_index)

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
