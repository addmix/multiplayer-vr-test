@tool
extends XRInteractableValue3D
class_name Slider3D

@export var value : float = 0.0:
	set(x):
		#assign value with float toggle for clamped or not clamped
		value = clamp(x, _min, _max) * float(_clamp) + x * float(!_clamp)
		value_changed.emit(value)
		
		var lerp_amount : float = range_lerp(value, _min, _max, 0.0, 1.0)
		transform = default_transform * min_transform.interpolate_with(max_transform, lerp_amount)
@export var reset_on_release : bool = false
@export var default_value : float = 0.0

@export var _clamp : bool = true
@export var _min : float = 0.0
@export var _max : float = 1.0

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

@onready var MinPosition : Marker3D
@onready var MaxPosition : Marker3D

@onready var default_transform : Transform3D = transform
var grab_offset : Vector3

func _process(delta : float) -> void:
	assert(!is_equal_approx((min_transform.origin - max_transform.origin).length_squared(), 0.0), "min_position and max_position in same spot, will crash game")
	
	var trans : Transform3D = get_parent().global_transform  * default_transform
	if controller != null:	
		value = closest_point_on_line_normalized((trans * min_transform).origin, (trans * max_transform).origin, controller.global_transform.origin - grab_offset) 

func grab(function : XRControllerFunctionInteract) -> void:
	super.grab(function)
	grab_offset = controller.global_transform.origin - global_transform.origin

func release(function : XRControllerFunctionInteract) -> void:
	if reset_on_release:
		value = default_value
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
