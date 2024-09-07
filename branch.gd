extends Node2D

var indices:PackedInt32Array##indices of vertices associated with this branch
var child_branches:Array[Node2D]
var v_id:int
var world:MeshInstance2D
var angle_random:float
var branch_id:int
var placement_point:Vector2

func move(pos_change:Vector2, deep:bool = true):
	global_position += pos_change
	for i in indices:
		world.vertices[i] += pos_change
	if deep:
		for b in child_branches:
			b.move(pos_change)

func update_position(new_pos:Vector2):
	var difference:Vector2 = new_pos - global_position
	print("moving branch by: " + str(difference) + ". " + str(child_branches.size()) + " child branches will be moved")
	move(difference, false)
	world.update_mesh()
	pass

func pivot(pivot_point:Vector2,angle:float):
	pass

func vertex(i:int) -> Vector2:
	return world.vertices[indices[i]]

func get_top_center() -> Vector2:
	return (vertex(1) + vertex(2)) / 2.

func get_bottom_center() -> Vector2:
	return (vertex(0) + vertex(3)) / 2.

func get_up_vector() -> Vector2:
	return (get_top_center() - get_bottom_center()).normalized()

func _ready() -> void:
	branch_id = world.branches_made
	world.rng.seed = world.random_seed + branch_id
	angle_random = (world.rng.randf() * 2.) - 1.
	#print("new branch placed at: " + str(global_position))
	
