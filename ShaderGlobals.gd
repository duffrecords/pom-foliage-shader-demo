# ShaderGlobals.gd
extends Node
# class_name ShaderGlobals

signal light_direction_updated(new_direction: Vector3)

var light_direction := Vector3(0, -1, 0):
	set(value):
		if light_direction != value:
			light_direction = value
			emit_signal("light_direction_updated", value)
