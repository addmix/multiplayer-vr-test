extends Area3D
class_name XRInteractable3D

signal grabbed(by)
signal released(from)

var interact_function : XRControllerFunctionInteract = null
var controller : XRController3D = null

@export var interact_haptics : bool = true
@export var haptic_frequency : float = 1000.0
@export var haptic_intensity : float = 0.5
@export var haptic_duration : float = 0.05
@export var haptic_delay : float = 0.0

var closest : bool = false:
	set(x):
		closest = x
var held : bool = false
func is_held() -> bool:
	return held

func _ready() -> void:
	monitoring = false

func grab(function : XRControllerFunctionInteract) -> void:
	interact_function = function
	controller = function.get_parent()
	held = true
	
	XRInterfaceSingleton.interface.trigger_haptic_pulse("haptic", controller.tracker_name, haptic_frequency, haptic_intensity, haptic_duration, haptic_delay)
	
	emit_signal("grabbed", function)

func release(function : XRControllerFunctionInteract) -> void:
	interact_function = null
	controller = null
	held = false
	
	emit_signal("released", function)

func force_disconnect() -> void:
	interact_function.force_disconnect(self)
