extends Node3D

@onready var light: DirectionalLight3D = $DirectionalLight3D

func _ready():
	_update_light_direction()

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_light_direction()

func _update_light_direction():
	# The light's Z axis points *forward*, so negate it to get the direction the light shines
	ShaderGlobals.light_direction = light.global_transform.basis.z.normalized()
