extends XRController3D

@export var tracker_name : StringName = ""


func _ready():
	button_pressed.connect(on_button_pressed)
	button_released.connect(on_button_released)
	input_axis_changed.connect(on_input_axis_changed)
	input_value_changed.connect(on_input_value_changed)

func on_button_pressed(_name : String) -> void:
	if _name == "by_button":
		get_parent().rotation += Vector3(0, -deg_to_rad(45.0), 0)

func on_button_released(_name : String) -> void:
	pass

func on_input_axis_changed(_name : String, value : Vector2) -> void:
	pass

func on_input_value_changed(_name : String, value : float) -> void:
	pass
