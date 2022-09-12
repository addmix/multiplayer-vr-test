extends Node3D

@onready var Head : Node3D = $Head
@onready var LeftHand : Node3D = $LeftHand
@onready var RightHand : Node3D = $RightHand

@rpc(call_remote, unreliable_ordered, authority, 1)
func network_update(anchor_transform : Transform3D, camera_transform : Transform3D, left_transform : Transform3D, right_transform : Transform3D) -> void:
	transform = anchor_transform
	Head.transform = camera_transform
	LeftHand.transform = left_transform
	RightHand.transform = right_transform

func _exit_tree() -> void:
	#delete physical character
	pass
