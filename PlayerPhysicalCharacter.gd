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

var network_input := Vector2.ZERO
var network_position := Vector3.ZERO
var network_velocity := Vector3.ZERO
@export var network_interpolation_value : float = 0.7
#how many seconds to interpolate from network values to client side values
@export var network_interpolation_duration : float = 0.1

var jump_requested : bool = false

func _ready() -> void:
	head = Player.get_node("Head")
	left_controller = Player.get_node("LeftHand")
	right_controller = Player.get_node("RightHand")
	
	head.tree_exiting.connect(on_player_deleted)

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
	#tell server what my input is
	if is_multiplayer_authority():
		transmit_input_update.rpc_id(1, input)
		
		if (right_controller.is_button_pressed("ax_button") or right_controller.is_button_pressed("primary_click")):
			transmit_jump_input.rpc_id(1)
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
	
	
	#when headset "rolls", do leaning?
	
	#visible collision debug option shows wrong shape?
	#crouching, changing collision shape
	var height = max(head.position.y, 0.1) + capsule.shape.radius
	capsule.shape.radius = 0.2
	capsule.shape.height = max(height, 2.0 * capsule.shape.radius)
	capsule.position.y = 0.5 * height
	#prevent standing up when under an obstacle
	
	if multiplayer.is_server():
		#this should be the necessary amount of extrapolation
		#distance to go forward by
		var correction : Vector2 = (network_input - input) * SPEED * PingService.get_ping(get_multiplayer_authority())
		#correct for delta
		correction = correction# / delta
		input = network_input
		
		velocity.x = input.x * SPEED + correction.x
		velocity.z = input.y * SPEED + correction.y
	#run physics on both authority and server
	elif is_multiplayer_authority():
		#do clientside interpolation/extrapolation here
		position = lerp(position, network_position, network_interpolation_value)
		velocity = network_velocity
		
		velocity.x = input.x * SPEED
		velocity.z = input.y * SPEED
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()
	
	
	
	#only the server has authority to update player positions
	if multiplayer.is_server():
		#give client updated position and velocity
		receive_network_update.rpc(position + velocity * PingService.get_ping(get_multiplayer_authority()), velocity)
	
	create_time_machine_entry()

#can only be called by authority client
@rpc(call_local, authority, unreliable_ordered, 1)
func transmit_input_update(_input : Vector2) -> void:
	#if not server
	if !multiplayer.is_server():
		push_error("Client Error: Unauthorized network input update from peer %s" % multiplayer.get_remote_sender_id())
		return
	
	#prevent client from sending spoofed/replaced input value
	network_input = _input.limit_length()

#can only be called by server
@rpc(call_local, any_peer, unreliable_ordered, 2)
func receive_network_update(_position : Vector3, _velocity : Vector3) -> void:
	#push error and return if someone other than the server/host attempts to send a network update to this client
	if multiplayer.get_remote_sender_id() != 1:
		push_error("Client Error: Unauthorized network update from peer %s" % multiplayer.get_remote_sender_id())
		return
	
	network_position = _position
	network_velocity = _velocity

#runs on server
@rpc(call_local, authority, reliable)
func transmit_jump_input() -> void:
	if !multiplayer.is_server():
		return
	#if serve saw player was on ground when jump was pressed
	if TimeMachine.get_property(self, "is_on_floor", PingService.ping):
		velocity.y = JUMP_VELOCITY


func create_time_machine_entry() -> void:
	TimeMachine.register_object(self)
	TimeMachine.set_property(self, "position", transform.origin)
	TimeMachine.set_property(self, "velocity", velocity)
	TimeMachine.set_property(self, "is_on_floor", is_on_floor())

func on_player_deleted() -> void:
	#for now, just delete physical player
	queue_free()
