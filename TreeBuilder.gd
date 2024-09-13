extends MeshInstance2D

#todo
#adjust grid position and size to match tree size
#investigate and fix manual branch rotation
#swaying/wind
#----------------ITERATION------------
@export_category("Iteration")
@export var iterations:int = 2:
	set(v):
		iterations = v
@export var branches:int = 2:
	set(v):
		branches = v
#----------------POSITION------------
@export_category("Position")
@export_range(-PI,PI) var angle:float = 0.2:
	set(v):
		angle = v
@export_range(-1,1) var angle_decay:float = 0.1:
	set(v):
		angle_decay = v
@export_range(0,1) var angle_random:float = 0.:
	set(v):
		angle_random = v
#----------------APPEARANCE------------
@export_category("Appearance")
@export var color_gradient:Gradient:
	set(v):
		color_gradient = v
		print("gradient changed")
@export var width_curve:Curve:
	set(v):
		width_curve = v
@export var length_curve:Curve:
	set(v):
		length_curve = v
@export var random_seed = 420:
	set(v):
		random_seed = v
		rng.seed = random_seed
#----------------PHYSICS------------
@export_category("Physics")
@export var physics_enabled:bool = false
@export var wind_dir:float = 0
@export var wind_strength:float = 0
@export var stiffness_curve:Curve
@export var mass_curve:Curve

var debug_dot = preload("res://debug_dot.tscn")

var branch_scene = preload("res://branch.tscn")
var root_node:Branch


var rng = RandomNumberGenerator.new()


var child_branches:Array[Branch]

var tree_mesh:ArrayMesh = ArrayMesh.new()
var vertices:PackedVector2Array
var indices:PackedInt32Array
var colors:PackedColorArray
var v_id_array:PackedInt32Array

var height_incr:float

var node_ready = false

var dots_placed:int = 0
var branches_made:int = 0
var center_of_mass:Vector2
var furthest_node:float = 0

var delta_time:float = 0

func _process(delta: float) -> void:
	delta_time = delta
	if node_ready && physics_enabled:
		root_node.sway()
		update_mesh()
		pass



func place_dot(pos:Vector2):
	var dot = debug_dot.instantiate()
	dot.position = pos
	dots_placed += 1
	add_child(dot)

func place_node(pos:Vector2, height:float, parent_node:Node2D) -> Node2D:
	var node:Branch = branch_scene.instantiate()
	node.world = self
	node.grid = $Grid
	parent_node.add_child(node)
	parent_node.child_branches.append(node)
	node.global_position = pos
	node.stiffness = stiffness_curve.sample(height + height_incr)
	node.mass = mass_curve.sample(height)
	center_of_mass += pos
	furthest_node = max(max(abs(pos.x),abs(pos.y)), furthest_node)
	branches_made += 1
	return node

##creates the first set of vertices from which the rest of the tree can be built
func root_branch() -> Node2D:
	var color:Color = color_gradient.sample(0)
	var length:float = length_curve.sample(0)
	var bottom_width:float = width_curve.sample(0) / 2.
	var top_width:float = width_curve.sample(1. / float(iterations)) / 2.
	vertices.append_array([Vector2(-bottom_width,0),
	Vector2(-top_width,-length),
	Vector2(top_width,-length),
	Vector2(bottom_width,0)])
	v_id_array.append_array([0,1,1,0])
	colors.append_array([color,color,color,color])
	indices.append_array([0,1,2,0,2,3])
	
	var node = place_node(Vector2(0,0), 0., self)
	node.angle_random = 0
	node.indices = [0,1,2,3]
	node.v_id = 0
	node.angle_offset = 0.
	return node

##create top verts of a branch
func new_branch(v1:Vector2,v4:Vector2,width:float,length:float,local_up:float) -> PackedVector2Array:
	var local_right = local_up + (PI/2.)
	var center = ((v4 + v1) / 2.)##mid-point of bottom verts
	var v_off = Vector2(length,0).rotated(local_up)##vertical offset, length of branch
	var h_off = Vector2(width,0).rotated(local_right)##horizontal offset, width at top of branch
	var v2 = center + v_off - h_off##top left point
	var v3 = center + v_off + h_off##top right point
	return PackedVector2Array([v2,v3])

func branch(parent_node:Branch = root_node,v_id:int = 1):
	var i1:int = parent_node.indices[1]
	var i2:int = parent_node.indices[2]
	var height:float = float(v_id) * height_incr##position in tree, 0. - 1.
	var bottom_color:Color = color_gradient.sample(height)##color at bottom of branch
	var top_color:Color = color_gradient.sample(height + height_incr)##color at top of branch
	var start_angle:float = parent_node.angle_offset##horizontal angle of the previous branch
	var start_up_angle:float = start_angle - (PI/2.)##vertical angle of previous branch
	var start_point:Vector2 = parent_node.get_top_center()##top point of previous branch
	
	var lv:int##last index of the vertices array
	var radius:float = width_curve.sample(height) / 2.
	for b in branches:
		lv = vertices.size() - 1
		
		var a:float = start_up_angle + lerp(-angle,angle, float(b) / float(branches - 1)) 
		var local_right:float = a + (PI/2.)
		var local_center:Vector2 = start_point + Vector2(radius, 0).rotated(a)
		var local_verts:PackedVector2Array
		var local_indices:PackedInt32Array
		var unique_indices:PackedInt32Array##local indices without repetition, clock-wise winding
		var local_colors:PackedColorArray
		var v0:Vector2 = Vector2(0,0)
		var node:Branch = place_node(local_center, height, parent_node)
		a += node.angle_random
		local_verts.resize(4)
		local_verts.fill(v0)
		local_colors = [bottom_color,top_color,top_color,bottom_color]
		lv += 4
		local_indices.append_array([i1, lv-3, lv])#connector left tri
		local_indices.append_array([i1, lv, i2])#connector right tri
		local_indices.append_array([lv-3, lv-2,lv-1])#branch left tri
		local_indices.append_array([lv-3, lv-1,lv])#branch right tri
		unique_indices.append_array([lv-3, lv-2, lv-1, lv])
		node.angle_offset = local_right
		node.indices = unique_indices.duplicate()
		node.v_id = v_id
		vertices.append_array(local_verts)
		indices.append_array(local_indices)
		colors.append_array(local_colors)
		node.update_appearance(false)
		node.update_verts(false)
		if v_id < iterations:
			branch(node, v_id+1)
	pass


func branch_old(i1:int,i2:int, parent_node:Node2D = root_node,v_id:int = 1):
	var start_point:Vector2 = vertices[i1]##top left corner of parent branch
	var end_point:Vector2 = vertices[i2]##top right corner of parent branch
	var lv:int = vertices.size() - 1##tracks size of vertex array before adding new points
	var height:float = float(v_id) * height_incr##position in tree, 0. - 1.
	var bottom_color:Color = color_gradient.sample(height)##color at bottom of branch
	var top_color:Color = color_gradient.sample(height + height_incr)##color at top of branch
	var bottom_width:float = width_curve.sample(height)##width at bottom of branch
	var top_width:float = width_curve.sample(height + height_incr)##width at top of branch
	var length: float = length_curve.sample(height)##length of branch
	#create bottom points
	var center = (start_point + end_point) / 2.
	var radius = (end_point - start_point).length() / 2.
	var right = (end_point - start_point).angle()
	var up = right - (PI / 2.)

	for i in branches:
		lv = vertices.size() - 1
		#angle of new branch
		var a = up + lerp(-angle,angle, float(i) / float(branches - 1)) 
		#angle of x-direction of new branch
		var local_right = a + (PI/2.)
		var local_center:Vector2 = center + Vector2(radius, 0).rotated(a)
		#place_dot(local_center)
		var local_verts:PackedVector2Array
		var local_indices:PackedInt32Array
		var unique_indices:PackedInt32Array##local indices without repetition, clock-wise winding
		var local_colors:PackedColorArray
		var top_verts:PackedVector2Array##top left and top right verts of branch
		var top_vert_index:int##index of the top-left vertex of branch
		var node:Node2D = place_node(local_center, height, parent_node)
		
		var p1 = local_center + Vector2(-bottom_width / 2., 0).rotated(local_right)
		var p2 = local_center + Vector2(bottom_width / 2., 0).rotated(local_right)
		a += node.angle_random
		top_verts = new_branch(p1, p2, top_width, length, a)
		local_verts.append_array([p1,top_verts[0],top_verts[1],p2])
		local_colors.append_array([bottom_color,top_color,top_color,bottom_color])
		lv += 4
		top_vert_index = lv - 2
		local_indices.append_array([i1, lv-3, lv])#connector left tri
		local_indices.append_array([i1, lv, i2])#connector right tri
		local_indices.append_array([lv-3, lv-2,lv-1])#branch left tri
		local_indices.append_array([lv-3, lv-1,lv])#branch right tri
		unique_indices.append_array([lv-3, lv-2, lv-1, lv])
		
		node.angle_offset = local_right
		node.indices = unique_indices.duplicate()
		node.v_id = v_id
		vertices.append_array(local_verts)
		indices.append_array(local_indices)
		colors.append_array(local_colors)
		if (v_id < iterations):
			branch_old(top_vert_index, top_vert_index + 1, node, v_id + 1)

func _ready() -> void:
	height_incr = 1. / float(iterations)
	$Grid.empty_grid()
	
	root_node = root_branch()
	branch(root_node)
	root_node.update_grid()
	#root_node.update_verts()
	center_of_mass /= branches_made
	#root_node.update_position(-center_of_mass)
	#$Grid.offset = center_of_mass
	#$Grid.grid_size_px = max($Grid.grid_size_px, 2. * furthest_node)
	$Grid.update_dimensions()
	print("Expected Branches: " + str(max_branches()))
	print("Branches Made: " + str(branches_made))
	print("Dots placed: " + str(dots_placed))
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] =  colors
	var flags = Mesh.ARRAY_FORMAT_VERTEX + Mesh.ARRAY_FORMAT_COLOR + Mesh.ARRAY_FORMAT_INDEX 
	tree_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},flags)
	mesh = tree_mesh
	node_ready = true

func update_mesh():
	tree_mesh.clear_surfaces()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] =  colors
	var flags = Mesh.ARRAY_FORMAT_VERTEX + Mesh.ARRAY_FORMAT_COLOR + Mesh.ARRAY_FORMAT_INDEX 
	tree_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},flags)

func max_branches():## math yo
	return ((pow(branches, iterations + 1) - 1 )/ (branches - 1))
