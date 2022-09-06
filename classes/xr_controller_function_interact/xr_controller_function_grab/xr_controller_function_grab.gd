extends XRControllerFunctionInteract

@export var pickup_button_action = ""

func _on_button_pressed(p_button : String) -> void:
	if p_button == pickup_button_action:
		grab()

func _on_button_released(p_button : String) -> void:
	if p_button == pickup_button_action:
		release()

func force_disconnect(node : XRInteractable3D) -> void:
	release()

func grab() -> void:
	if is_instance_valid(closest_object):
		closest_object.grab(self)
		held_object = closest_object

func release() -> void:
	if is_instance_valid(held_object):
		held_object.release(self)
		held_object = null
