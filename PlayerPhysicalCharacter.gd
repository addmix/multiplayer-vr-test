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

var input := Vector2.ZERO
func _process(delta : float) -> void:
	var base_input := left_controller.get_axis(&"primary")
	var transformed_input := Vector3(base_input.x, 0, -base_input.y).rotated(Vector3(0, 1, 0), head.global_transform.basis.get_euler().y)
	input = Vector2(transformed_input.x, transformed_input.z)

func _physics_process(delta : float) -> void:
	if not is_on_floor():
			velocity.y -= gravity * delta
	
	#run physics on both authority and server
	if is_multiplayer_authority() or get_tree().get_multiplayer().is_server():
		
		if is_on_floor():
			velocity.x = input.x * SPEED
			velocity.z = input.y * SPEED
			
			if right_controller.is_button_pressed("ax_button"):
				velocity.y = JUMP_VELOCITY
	
	move_and_slide()
	
	#tell server what my input is
	if is_multiplayer_authority():
		transmit_input_update.rpc_id(1, input)
		
		#if jump
		if right_controller.is_button_pressed("ax_button"):
			pass
	
	#only the server has authority to update player positions
	if get_tree().get_multiplayer().is_server():
		receive_network_update.rpc(position, velocity)

#can only be called by authority client
@rpc(call_local, authority, unreliable_ordered, 1)
func transmit_input_update(_input : Vector2) -> void:
	#if not server
	if !get_tree().get_multiplayer().is_server():
		push_error("Client Error: Unauthorized network input update from peer %s" % get_tree().get_multiplayer().get_remote_sender_id())
		return
	
	input = _input

#can only be called by server
@rpc(call_remote, any_peer, unreliable_ordered, 2)
func receive_network_update(_position : Vector3, _velocity : Vector3) -> void:
	#push error and return if someone other than the server/host attempts to send a network update to this client
	if get_tree().get_multiplayer().get_remote_sender_id() != 1:
		push_error("Client Error: Unauthorized network update from peer %s" % get_tree().get_multiplayer().get_remote_sender_id())
		return
	
	position = _position
	velocity = _velocity
#call_local call_remote
#any_peer authority
#reliable unreliable unreliable_ordered
