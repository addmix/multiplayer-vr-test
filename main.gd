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
	#add character
	
	if id == get_tree().get_multiplayer().get_unique_id():
		create_character(id)
	else:
		create_puppet(id)

func on_peer_disconnected(id : int) -> void:
	#remove character
	player_refs[id].queue_free()
	#remove reference
	player_refs.erase(id)

func on_connected_to_server() -> void:
	if !get_tree().get_multiplayer().is_server():
		create_character(get_tree().get_multiplayer().get_unique_id())

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
