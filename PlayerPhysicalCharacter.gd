extends CharacterBody3D

var Player : Node3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var head : XRCamera3D
var left_controller : XRController3D
var right_controller : XRController3D

func _ready() -> void:
	if is_multiplayer_authority():
		head = Player.get_node("Head")
		left_controller = Player.get_node("LeftHand")
		right_controller = Player.get_node("RightHand")

func _physics_process(delta : float) -> void:
	if not is_on_floor():
			velocity.y -= gravity * delta
	
	if is_multiplayer_authority():
		#input
		var input : Vector2 = left_controller.get_axis(&"primary")
		var transformed_input := Vector3(input.x, 0, -input.y).rotated(Vector3(0, 1, 0), head.global_transform.basis.get_euler().y) * SPEED
		
		
		# Add the gravity.
		
		if is_on_floor():
			velocity.x = transformed_input.x
			velocity.z = transformed_input.z
			
			if right_controller.is_button_pressed("ax_button"):
				velocity.y = JUMP_VELOCITY
		
		#send update
		network_update.rpc(position, velocity)
	
	move_and_slide()

@rpc(call_remote, unreliable_ordered, authority, 1)
func network_update(_position : Vector3, _velocity : Vector3) -> void:
	position = _position
	velocity = _velocity
#call_local call_remote
#any_peer authority
#reliable unreliable unreliable_ordered
