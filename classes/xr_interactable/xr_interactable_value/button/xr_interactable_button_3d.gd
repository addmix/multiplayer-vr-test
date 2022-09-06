@tool
extends XRInteractableValue3D
class_name XRInteractableButton3D

@export var value : bool = false:
	set(x):
		#assign value with float toggle for clamped or not clamped
		value = x
		value_changed.emit(value)
@export var reset_on_release : bool = false 
@export var default_value : bool = false

func grab(function : XRControllerFunctionInteract) -> void:
	super.grab(function)
	value = !value

func release(function : XRControllerFunctionInteract) -> void:
	if reset_on_release:
		value = default_value
	else:
		value = !value
	super.release(function)
