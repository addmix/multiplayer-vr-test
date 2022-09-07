extends XROrigin3D

### Make XRPlayer and XRPuppet persistent despite adding/removing the physical character body

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


# Idea:
#
# use _exit_tree and a variable to differentiate between handled and unhandled player/puppet reparenting?
# if var handled_move is true then do nothing when the _exit_tree method is called, because we can trust
# that the function that removed will add the player/puppet back to the tree, whereas if handled_move was
# not set to true, we know there was an unauthorized access, or an improper move/removal, and we can add
# the player/puppet back to the tree in a known-safe location, such as a menu or lobby.
