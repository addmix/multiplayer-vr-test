@tool
extends Area3D
class_name XRControllerFunctionInteract

var interactables_in_area : Array = []
var held_object : XRInteractable3D = null
var closest_object : XRInteractable3D = null

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if !get_parent_node_3d() is XRController3D:
		warnings.append("Parent is not of type: XRController3D")
	
	return warnings

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		return
	
	get_parent().connect("button_pressed", _on_button_pressed)
	get_parent().connect("button_released", _on_button_released)

func _process(_delta : float) -> void:
	_update_closest_interactable()

func _on_button_pressed(p_button : String) -> void:
	pass

func _on_button_released(p_button : String) -> void:
	pass

func _on_function_grab_area_entered(area : Area3D) -> void:
	if area is XRInteractable3D:
		interactables_in_area.push_back(area)
		_update_closest_interactable()

func _on_function_grab_area_exited(area : Area3D) -> void:
	if interactables_in_area.find(area) != -1:
		interactables_in_area.erase(area)
		_update_closest_interactable()

func _update_closest_interactable() -> void:
	if held_object != null:
		return
	
	#loop through to find closest object
	var closest_distance : float = 100000.0
	var new_closest_object = null
	for object in interactables_in_area:
		if object.is_held():
			continue
		
		#compare distance
		var distance_squared : float = global_transform.origin.distance_squared_to(object.global_transform.origin)
		if distance_squared < closest_distance:
			closest_distance = distance_squared
			new_closest_object = object
	
	#set new closest object
	if closest_object != new_closest_object:
		#highlights for closest object
		if closest_object and new_closest_object:
			closest_object.closest = false
			new_closest_object.closest = true
		
		closest_object = new_closest_object

func force_disconnect(node : XRInteractable3D) -> void:
	pass
