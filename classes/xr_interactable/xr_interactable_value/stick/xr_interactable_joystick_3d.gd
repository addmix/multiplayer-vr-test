extends XRInteractableValue3D
class_name XRInteractableJoystick3D

@export var value : Vector3 = Vector3.ZERO:
	set(x):
		value = (x / final_limit).clamp(Vector3(-1, -1, -1), Vector3(1, 1, 1))
		
		#rotate to match
		var yaw_basis : Basis = Basis.from_euler(Vector3(0.0, -value.y * final_limit, 0.0))
		var pitch_basis : Basis = Basis.from_euler(Vector3(value.x * final_limit, 0.0, 0.0))
		var roll_basis : Basis = Basis.from_euler(Vector3(0.0, 0.0, -value.z * final_limit))
		
		transform.basis = pitch_basis * roll_basis * yaw_basis
		
		value_changed.emit(value)
@export var reset_on_release : bool = false
@export var default_value : Vector3 = Vector3.ZERO

@export var max_rotation : float = deg_to_rad(35.0):
	set(x):
		max_rotation = x
		final_limit = max_rotation * sensitivity
@export var sensitivity : float = 1.0:
	set(x):
		sensitivity = x
		final_limit = max_rotation * sensitivity
var final_limit : float = max_rotation * sensitivity

@onready var default_transform : Transform3D = global_transform
var grab_basis : Basis
var stick_grab_basis : Basis

func _process(delta : float) -> void:
	
	
	
	if controller != null:
		#set stick transform
		var stick_transform : Basis = (controller.transform.basis * grab_basis.inverse() * stick_grab_basis)
		
		#up vector
		var right_vector : Vector3 = stick_transform.transposed().x
		var up_vector : Vector3 = stick_transform.transposed().y
		var forward_vector : Vector3 = stick_transform.transposed().z
		
		#yaw right is positive
		var yaw_angle : float = atan2(-right_vector.z, right_vector.x)
		#roll right is positive
		var roll_angle : float = atan2(-up_vector.x, up_vector.y)
		#pitch up is positive
		var pitch_angle : float = -atan2(-forward_vector.y, forward_vector.z)
		
		value = Vector3(pitch_angle, yaw_angle, roll_angle)

func grab(function : XRControllerFunctionInteract) -> void:
	super.grab(function)
	grab_basis = controller.global_transform.basis
	stick_grab_basis = global_transform.basis

func release(function : XRControllerFunctionInteract) -> void:
	if reset_on_release:
		value = default_value
	super.release(function)
