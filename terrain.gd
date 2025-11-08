@tool
extends Node3D

func _ready():
	if ShaderGlobals.is_connected("light_direction_updated", Callable(self, "_on_light_direction_updated")) == false:
		ShaderGlobals.connect("light_direction_updated", Callable(self, "_on_light_direction_updated"))
	for mesh in find_children("*", "MeshInstance3D"):
		mesh.add_to_group("parallax_meshes")
		

	# Set initial value
	_on_light_direction_updated(ShaderGlobals.light_direction)

func _on_light_direction_updated(direction: Vector3):
	# Find all MeshInstance3D children recursively
	for mesh in get_tree().get_nodes_in_group("parallax_meshes"):
		if not is_ancestor_of(mesh):
			continue

		var material : Material = mesh.get_active_material(0)
		if material is ShaderMaterial:
			material.set_shader_parameter("light_direction", direction)
