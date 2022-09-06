@tool
extends XRInteractableValue3D
class_name TwistSlider3D


@onready var MinPosition : Marker3D
@onready var MaxPosition : Marker3D


@export var value := Vector2.ZERO
@export var default_value := Vector2.ZERO:
	set(x):
		default_value = x
		default_position = (x.x + x.y) / 2.0
		default_rotation = ((x.x - x.y) / 2.0 * max_rotation_angle) / max_rotation_value
@export var min_value := Vector2(0, 0)
@export var max_value := Vector2(1, 1)

@export_group("Position")
var position_value : float = 0.0:
	set(x):
		#assign value with float toggle for clamped or not clamped
		position_value = clamp(x, min_position, max_position) * float(clamp_position) + x * float(!clamp_position)
		var lerp_amount : float = range_lerp(position_value, min_position, max_position, 0.0, 1.0)
		transform = default_transform * min_transform.interpolate_with(max_transform, lerp_amount)
var default_position : float = 0.0
@export var position_reset_on_release : bool = false
@export var clamp_position : bool = true
@export var min_position : float = 0.0
@export var max_position : float = 1.0
@export var min_transform : Transform3D
@export var max_transform : Transform3D
@export var min_position_path : NodePath:
	set(path):
		min_position_path = path
		var set_node = func(path):
			MinPosition = get_node(path)
			min_transform = MinPosition.transform
		set_node.call_deferred(path)
@export var max_position_path : NodePath:
	set(path):
		max_position_path = path
		var set_node = func(path):
			MaxPosition = get_node(path)
			max_transform = MaxPosition.transform
		set_node.call_deferred(path)

@export_group("Rotation")
var twist_value : float = 0.0:
	set(x):
		twist_value = clamp(x, -max_rotation_angle, max_rotation_angle)
var default_rotation : float = 0.0
@export var rotation_reset_on_release : bool = false
@export var max_rotation_angle : float = deg_to_rad(45)
@export var max_rotation_value : float = 1.0

@export_group("")

@onready var default_transform : Transform3D = transform
var grab_offset : Vector3
var grab_basis : Basis

func update_value() -> void:
	var deviation = twist_value / max_rotation_angle * max_rotation_value
	value = Vector2(position_value + deviation, position_value - deviation).clamp(min_value, max_value)

func _process(delta : float) -> void:
	var trans : Transform3D = get_parent().global_transform  * default_transform
	if controller != null:	
		var controller_transform : Basis = controller.transform.basis * grab_basis.inverse()
		
		position_value = closest_point_on_line_normalized((trans * min_transform).origin, (trans * max_transform).origin, controller.global_transform.origin - grab_offset) 
		var twist_value = controller_transform.get_euler().y
		

func grab(function : XRControllerFunctionInteract) -> void:
	super.grab(function)
	grab_offset = controller.global_transform.origin - global_transform.origin
	grab_basis = controller.global_transform.basis

func release(function : XRControllerFunctionInteract) -> void:
	if position_reset_on_release:
		position_value = default_position
	if rotation_reset_on_release:
		twist_value = default_rotation
	super.release(function)

func closest_point_on_line_normalized(a : Vector3, b : Vector3, c : Vector3) -> float:
	b = b - a
	c = c - a
	return c.dot(b.normalized()) / b.length()

func closest_point_on_line_clamped(a : Vector3, b : Vector3, c : Vector3) -> Vector3:
	b = b - a
	c = c - a
	var d = b.normalized()
	return a + d * clamp(c.dot(d), 0.0, b.length())

func closest_point_on_line(a : Vector3, b : Vector3, c : Vector3) -> Vector3:
	b = (b - a).normalized()
	c = c - a
	return a + b * (c.dot(b))
