extends XROrigin3D

@onready var Head : XRCamera3D = $Head
@onready var LeftHand : XRController3D = $LeftHand
@onready var RightHand : XRController3D = $RightHand

func _physics_process(delta : float) -> void:
	rpc(&"network_update", transform, Head.transform, LeftHand.transform, RightHand.transform)

#this should never get called
@rpc(call_remote, unreliable_ordered, authority, 1)
func network_update(anchor_transform : Transform3D, camera_transform : Transform3D, left_transform : Transform3D, right_transform : Transform3D) -> void:
	pass

func _process(delta : float) -> void:
	pass
