extends Node3D

var player_refs : Dictionary = {}

var kinematic_body = preload("res://player_physical_character.tscn")
var character = preload("res://XRPlayer.tscn")
var puppet = preload("res://XRPuppet.tscn")

func _ready() -> void:
	get_tree().get_multiplayer().peer_connected.connect(on_peer_connected)
	get_tree().get_multiplayer().peer_disconnected.connect(on_peer_disconnected)
	get_tree().get_multiplayer().connected_to_server.connect(on_connected_to_server)

func on_peer_connected(id : int) -> void:
	#only handle peer connections on server
	if !get_tree().get_multiplayer().is_server():
		return
	
	#tell all clients that a new peer has connected
	receive_peer_connected.rpc(id)
	#send newly connected client info about all clients presently on the server
	receive_players_on_server.rpc_id(id, get_tree().get_multiplayer().get_peers())

func on_peer_disconnected(id : int) -> void:
	#notify all connected clients of peer's disconnection
	receiver_peer_disconnected.rpc(id)

func on_connected_to_server() -> void:
	pass

@rpc(call_local, authority, reliable)
func receive_players_on_server(peers : PackedInt32Array) -> void:
	print("Client: Received peer IDs connected to server: ", peers)
	
	#create a puppet for every other player already on the server
	for peer in peers:
		create_puppet(peer)

@rpc(call_local, authority, reliable)
func receive_peer_connected(id : int) -> void:
	print("Client: Peer connected with ID: ", id)
	
	#if self
	if id == get_tree().get_multiplayer().get_unique_id():
		create_character(id)
	else:
		create_puppet(id)

@rpc(call_local, authority, reliable)
func receiver_peer_disconnected(id : int) -> void:
	#delete peer's character
	player_refs[id].queue_free()
	#remove reference to that player
	player_refs.erase(id)

func create_character(id : int) -> void:
	#create CharacterBody3D instance
	var body_instance : CharacterBody3D = kinematic_body.instantiate()
	body_instance.name = str(id)
	
	#create XRPlayer
	var instance : XROrigin3D = character.instantiate()
	instance.name = str(id)
	#save reference to player instance
	player_refs[id] = instance
	body_instance.add_child(instance)
	
	body_instance.Player = instance
	body_instance.set_multiplayer_authority(id)
	add_child(body_instance)

func create_puppet(id : int) -> void:
	#create CharacterBody3D instance
	var body_instance : CharacterBody3D = kinematic_body.instantiate()
	body_instance.name = str(id)
	
	#create XRPlayer
	var instance : Node3D = puppet.instantiate()
	instance.name = str(id)
	#save reference to player instance
	player_refs[id] = instance
	body_instance.add_child(instance)
	
	body_instance.Player = instance
	body_instance.set_multiplayer_authority(id)
	add_child(body_instance)
