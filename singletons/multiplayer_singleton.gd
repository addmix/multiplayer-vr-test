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
		#if you can't create a server, assume it is because one is already running and create client to connect to it
		if !create_server(config["port"]):
			create_client(config["ip"], config["port"])
	else:
		create_client(config["ip"], config["port"])


#initializing server/client


func create_server(port : int, max_clients: int = 32, max_channels: int = 0, in_bandwidth: int = 0, out_bandwidth: int = 0) -> bool:
	print("Server: Creating server on port: %s" % port)
	peer = ENetMultiplayerPeer.new()
	var error : int = peer.create_server(port, max_clients, max_channels, in_bandwidth, out_bandwidth)
	
	if error != OK:
		return false
	
	get_tree().get_multiplayer().multiplayer_peer = peer
	
	#stuff to ensure local player exists
	get_multiplayer().connected_to_server.emit()
	get_tree().get_multiplayer().peer_connected.emit(get_tree().get_multiplayer().get_unique_id())
	return true

func create_client(address: String, port: int, channel_count: int = 0, in_bandwidth: int = 0, out_bandwidth: int = 0, local_port: int = 0) -> void:
	print("Client: Creating client on ip: %s and port: %s" % [address, port])
	peer = ENetMultiplayerPeer.new()
	var error : int = peer.create_client(address, port, channel_count, in_bandwidth, out_bandwidth, local_port)
	get_tree().get_multiplayer().multiplayer_peer = peer

func on_connected_to_server() -> void:
	print("Client: Successfully connected to server with ID: %s" % get_tree().get_multiplayer().get_unique_id())

func on_connection_failed() -> void:
	print("Client: Connection to server failed.")

func on_peer_connected(id : int) -> void:
	print("Server: Peer %s connected." % id)

func on_peer_disconnected(id : int) -> void:
	print("Server: Peer %s disconnected." % id)

func on_server_disconnected() -> void:
	print("Client: Server disconected.")


#config


func has_config() -> bool:
	var dir := Directory.new()
	dir.open(OS.get_executable_path().get_base_dir())
	return dir.file_exists("config.ini")

func create_config() -> void:
	var config := ConfigFile.new()
	
	config.set_value("multiplayer", "host", true)
	config.set_value("multiplayer", "ip", "localhost")
	config.set_value("multiplayer", "port", 1738)
	
	print("Error %s when saving file: config.ini" % config.save(OS.get_executable_path().get_base_dir() + "/config.ini"))

func load_config() -> Dictionary:
	var config := ConfigFile.new()
	config.load(OS.get_executable_path().get_base_dir() + "/config.ini")
	
	return {
		"host": config.get_value("multiplayer", "host", true),
		"ip": config.get_value("multiplayer", "ip", "localhost"),
		"port": config.get_value("multiplayer", "port", 1738),
	}
	
	config.save(OS.get_executable_path().get_base_dir() + "/config.ini")
