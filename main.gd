extends Node3D


func _ready():
	update_light_direction()

func update_light_direction():
	var dir : Vector3 = -$DirectionalLight3D.global_transform.basis.z.normalized()
	print("light dir = ", dir)
	ShaderGlobals.light_direction = dir
