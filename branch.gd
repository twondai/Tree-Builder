extends Node2D
class_name Branch


#----------------META------------
var indices:PackedInt32Array##indices of vertices associated with this branch
var child_branches:Array[Branch]
var v_id:int##vertical id; branch iteration this branch was created on
var world:MeshInstance2D
var branch_id:int

#----------------APPEARANCE------------
var angle_random:float
var top_color:Color
var bottom_color:Color
var top_width:float
var bottom_width:float
var length:float


#----------------GRID------------
var grid:Node
var grid_cell:Vector2i

#----------------PHYSICS------------
var angle_offset:float = 0
var stiffness:float
var mass:float
var angular_velocity:float
var max_angle:float = 0.3

func update_grid(deep:bool = true):
	grid.grid.erase(self)
	grid_cell = grid.place_on_grid(self)
	if deep:
		for b in child_branches:
			b.update_grid()

func move(pos_change:Vector2, deep:bool = true):
	for i in indices:
		world.vertices[i] += pos_change
	if deep:
		for b in child_branches:
			b.move(pos_change)

func update_position(new_pos:Vector2):
	var difference:Vector2 = new_pos - global_position
	global_position += difference
	print("moving branch by: " + str(difference) + ". " + str(child_branches.size()) + " child branches will be moved")
	move(difference)
	world.update_mesh()
	update_grid()

func pivot(pivot_point:Vector2, angle_diff:float, deep:bool = true):
	for i in indices:
		world.vertices[i] = (world.vertices[i] - pivot_point).rotated(angle_diff) + pivot_point
	if deep:
		for b in child_branches:
			b.pivot(pivot_point, angle_diff)
			b.update_grid()

func update_appearance(deep:bool = true):
	var height_incr:float = 1. / float(world.iterations)
	var height = float(v_id) * height_incr
	bottom_width = world.width_curve.sample(height) / 2.
	top_width = world.width_curve.sample(height + height_incr) / 2.
	bottom_color = world.color_gradient.sample(height)
	top_color = world.color_gradient.sample(height + height_incr)
	length = -world.length_curve.sample(height)
	world.colors[indices[0]] = bottom_color
	world.colors[indices[1]] = top_color
	world.colors[indices[2]] = top_color
	world.colors[indices[3]] = bottom_color
	if deep:
		for b in child_branches:
			b.update_appearance()

func update_verts(deep:bool = true):
	var height_incr:float = 1. / float(world.iterations)
	var angle:float = global_rotation + angle_offset + angle_random
	world.vertices[indices[0]] = global_position + Vector2(-bottom_width,0).rotated(angle)
	world.vertices[indices[1]] = global_position + Vector2(-top_width,length).rotated(angle)
	world.vertices[indices[2]] = global_position + Vector2(top_width,length).rotated(angle)
	world.vertices[indices[3]] = global_position + Vector2(bottom_width,0).rotated(angle)
	if deep:
		for b in child_branches:
			b.update_verts()

func sway():
	var delta:float = world.delta_time
	var up:Vector2 = get_up_vector()
	var wind:Vector2 = Vector2(1.,0.).rotated(world.wind_dir)
	var catch:float = up.rotated(PI / 2.).dot(wind)
	var wind_strength:float = ((world.wind_strength * catch)) / mass
	var angle_diff:float = abs(wrap(rotation,-TAU,TAU))
	
	var resistance:float = (abs(rotation) / (max_angle * (1. - stiffness))) / mass
	var resistance_dir:float = sign(rotation)

	angular_velocity += wind_strength * delta
	angular_velocity -= resistance_dir * resistance * delta
	rotation += angular_velocity * delta
	update_verts(false)
	
	for b in child_branches:
		b.sway()

func update_angle(angle:float):
	var diff:float = get_shortest_rotation(rotation, angle)
	global_rotation = angle
	
	pivot(global_position, diff)
	world.update_mesh()

func get_shortest_rotation(a1:float, a2:float) -> float:
	var diff:float = a2 - a1
	if abs(diff) > PI:
		diff = a1 + (TAU - a2)
	return diff

func vertex(i:int) -> Vector2:
	return world.vertices[indices[i]]

func get_top_center() -> Vector2:
	return (vertex(1) + vertex(2)) / 2.

func get_bottom_center() -> Vector2:
	return (vertex(0) + vertex(3)) / 2.

func get_up_vector() -> Vector2:
	return (get_top_center() - get_bottom_center()).normalized()

func get_angle() -> float:
	return get_up_vector().angle()

func _ready() -> void:
	branch_id = world.branches_made
	world.rng.seed = world.random_seed + branch_id
	angle_random = ((world.rng.randf() * 2.) - 1.) * world.angle_random
	#print("new branch placed at: " + str(global_position))
