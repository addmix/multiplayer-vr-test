extends Node3D

var peer := ENetMultiplayerPeer.new()

func _ready() -> void:
	#connect signals
	get_tree().get_multiplayer().connected_to_server.connect(on_connected_to_server)
	get_tree().get_multiplayer().connection_failed.connect(on_connection_failed)
	get_tree().get_multiplayer().peer_connected.connect(on_peer_connected)
	get_tree().get_multiplayer().peer_disconnected.connect(on_peer_disconnected)
	get_tree().get_multiplayer().server_disconnected.connect(on_server_disconnected)
	
	#allows all nodes to connect to multiplayer signals, if necessary
	deferred.call_deferred()

func deferred() -> void:
	if !has_config():
		create_config()
	var config = load_config()
	
	if config["host"]:
		create_server(config["port"])
	else:
		create_client(config["ip"], config["port"])


#initializing server/client


func create_server(port : int, max_clients: int = 32, max_channels: int = 0, in_bandwidth: int = 0, out_bandwidth: int = 0) -> void:
	print("Creating server on port: %s" % port)
	peer = ENetMultiplayerPeer.new()
	var error : int = peer.create_server(port, max_clients, max_channels, in_bandwidth, out_bandwidth)
	get_tree().get_multiplayer().multiplayer_peer = peer
	
	#stuff to ensure local player exists
	get_multiplayer().connected_to_server.emit()
	get_tree().get_multiplayer().peer_connected.emit(get_tree().get_multiplayer().get_unique_id())

func create_client(address: String, port: int, channel_count: int = 0, in_bandwidth: int = 0, out_bandwidth: int = 0, local_port: int = 0) -> void:
	print("Creating client on ip: %s and port: %s" % [address, port])
	peer = ENetMultiplayerPeer.new()
	var error : int = peer.create_client(address, port, channel_count, in_bandwidth, out_bandwidth, local_port)
	get_tree().get_multiplayer().multiplayer_peer = peer

func on_connected_to_server() -> void:
	print("Successfully connected to server with id: %s" % get_tree().get_multiplayer().get_unique_id())

func on_connection_failed() -> void:
	print("Connection to server failed.")

func on_peer_connected(id : int) -> void:
	print("Peer %s connected." % id)

func on_peer_disconnected(id : int) -> void:
	print("Peer %s disconnected." % id)

func on_server_disconnected() -> void:
	print("Server disconected.")


#config


func has_config() -> bool:
	var dir := Directory.new()
	dir.open(OS.get_executable_path().get_base_dir())
	return dir.file_exists("config.ini")

func create_config() -> void:
	var config := ConfigFile.new()
	
	config.set_value("multiplayer", "host", false)
	config.set_value("multiplayer", "ip", "localhost")
	config.set_value("multiplayer", "port", 1738)
	
	print("Error %s when saving file: config.ini" % config.save(OS.get_executable_path().get_base_dir() + "/config.ini"))

func load_config() -> Dictionary:
	var config := ConfigFile.new()
	config.load(OS.get_executable_path().get_base_dir() + "/config.ini")
	
	return {
		"host": config.get_value("multiplayer", "host"),
		"ip": config.get_value("multiplayer", "ip"),
		"port": config.get_value("multiplayer", "port"),
	}
