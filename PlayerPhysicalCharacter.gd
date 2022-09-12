extends CharacterBody3D

var Player : Node3D
@onready var capsule : CollisionShape3D = $CollisionShape3d

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var head : Node3D
var left_controller : Node3D
var right_controller : Node3D

func _ready() -> void:
	head = Player.get_node("Head")
	left_controller = Player.get_node("LeftHand")
	right_controller = Player.get_node("RightHand")

var input := Vector2.ZERO
func _process(delta : float) -> void:
	if !is_multiplayer_authority():
		return
	
	var base_input : Vector2 = left_controller.get_axis(&"primary")
	
	#translate the headset's movement into world-aligned movement vector
	#go by inverse player basis to account for XROrigin rotation
	var headset_movement := (head.position * Player.basis.inverse() * Vector3(1.0, 0.0, 1.0) + Player.position)
	#normalize for movement speed
	headset_movement = headset_movement / delta / SPEED * Vector3(1, 0, 1)
	#do final rotation
	var transformed_input := Vector3(base_input.x, 0, -base_input.y).rotated(Vector3(0, 1, 0), head.global_transform.basis.get_euler().y) + headset_movement
	
	#keep headset at player's center
	Player.position = -Vector3(head.position.x, 0.0, head.position.z) * Player.basis.inverse()
	input = Vector2(transformed_input.x, transformed_input.z).limit_length()

func _physics_process(delta : float) -> void:
	if get_tree().is_queued_for_deletion():
		return
	#when headset "rolls", do leaning?
	
	#crouching, changing collision shape
	var height = max(head.position.y, 0.1) + capsule.shape.radius
	capsule.shape.radius = 0.2
	capsule.shape.height = max(height, 2.0 * capsule.shape.radius)
	capsule.position.y = 0.5 * height
	#prevent standing up when under an obstacle
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	#run physics on both authority and server
	if is_multiplayer_authority() or get_tree().get_multiplayer().is_server():
		
		if is_on_floor():
			velocity.x = input.x * SPEED
			velocity.z = input.y * SPEED
	
	move_and_slide()
	
	#tell server what my input is
	if is_multiplayer_authority():
		transmit_input_update.rpc_id(1, input)
		
		if right_controller.is_button_pressed("ax_button") or right_controller.is_button_pressed("primary_click") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	
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
	
	#prevent client from sending spoofed/replaced input value
	input = _input.limit_length()

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
