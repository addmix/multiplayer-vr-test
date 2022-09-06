extends Node3D

var interface : XRInterface

func _ready():
	# Find our interface and check if it was successfully initialised.
	# Note that Godot should initialise this automatically IF you've
	# enabled it in project settings!
	interface = XRServer.find_interface("OpenXR")
	
	if interface and interface.is_initialized():
		print("OpenXR initialised successfully")
		var vp : Viewport = get_viewport()
		vp.use_xr = true
	else:
		print("OpenXR not initialised, please check if your headset is connected")
	
