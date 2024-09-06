extends MeshInstance2D

#todo
#fill gaps
#use nodes to help control branches and keep track of vertices and indices
#swaying/wind

@export_category("Branch Count")
@export var iterations:int = 2:
	set(v):
		iterations = v
@export var branches:int = 2:
	set(v):
		branches = v
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
@export_category("Appearance")
@export var color_gradient:Gradient:
	set(v):
		color_gradient = v
		print("gradient changed")
		#update_color()
@export var width_curve:Curve:
	set(v):
		width_curve = v
		#update_width()
@export var length_curve:Curve:
	set(v):
		length_curve = v

var debug_dot = preload("res://debug_dot.tscn")

var rng = RandomNumberGenerator.new()
@export var random_seed = 420:
	set(v):
		random_seed = v
		rng.seed = random_seed

var branches_made = 0

var tree_mesh:ArrayMesh = ArrayMesh.new()
var vertices:PackedVector2Array
var indices:PackedInt32Array
var colors:PackedColorArray
var v_id_array:PackedInt32Array

var height_incr:float

var node_ready = false

func place_dot(pos:Vector2):
	var dot = debug_dot.instantiate()
	dot.position = pos
	add_child(dot)
	

func root_branch():
	var v:PackedVector2Array
	var color:Color = color_gradient.sample(0)
	var length:float = length_curve.sample(0)
	var bottom_width:float = width_curve.sample(0) / 2.
	var top_width:float = width_curve.sample(1. / float(iterations)) / 2.
	v.append_array([Vector2(-bottom_width,0),
	Vector2(-top_width,-length),
	Vector2(top_width,-length),
	Vector2(bottom_width,0)])
	vertices.append_array(v)
	indices.append_array([0,1,2,0,2,3])
	v_id_array.append_array([0,1,1,0])
	colors.append_array([color,color,color,color])


func new_branch(v1:Vector2,v4:Vector2,height:float,local_angle:float) -> PackedVector2Array:
	var length:float = length_curve.sample(height)
	var width = width_curve.sample(height) / 2.
	
	var local_right = (v4 - v1).angle() + local_angle
	var local_up = local_right - (PI/2.)
	var center = ((v4 + v1) / 2.)
	var v_off = Vector2(length,0).rotated(local_up)
	var h_off = Vector2(width,0).rotated(local_right)
	
	var v2 = center + v_off - h_off
	var v3 = center + v_off + h_off
	
	var verts:PackedVector2Array = [v2,v3]
	return verts

func branch(i1:int,i2:int,v_id:int = 1):
	var start_point:Vector2 = vertices[i1]
	var end_point:Vector2 = vertices[i2]
	var bottom_points:PackedVector2Array = [start_point]
	var bottom_indices:PackedInt32Array = [i1]
	var last_vertex:int = vertices.size() - 1
	var height:float = float(v_id) * height_incr
	var color:Color = color_gradient.sample(height)
	var bottom_width:float = width_curve.sample(height)
	var top_width:float = width_curve.sample(height + height_incr)
	
	#create bottom points
	var center = (start_point + end_point) / 2.
	var radius = (end_point - start_point).length() / 2.
	var angle_incr = PI / float(branches)
	var right = (end_point - start_point).angle()
	var up = right - (PI / 2.)
	
	for i in branches:
		last_vertex = vertices.size() - 1
		#angle of new branch
		var a = right + ((i+1) * angle_incr) - (angle_incr / 2.)
		#angle of x-direction of new branch
		var local_right = a + (PI/2.)
		var local_center:Vector2 = center + Vector2(-radius, 0).rotated(a)
		var local_verts:PackedVector2Array
		var local_indices:PackedInt32Array
		local_indices.resize(6)
		if i == 0:
			local_indices[0] = i1
			var p:Vector2 = Vector2(bottom_width, 0).rotated(local_right)
			p = connect_to_branch(p, right, local_right, a)
			local_verts.append(p)
			last_vertex += 1
			local_indices[5] = last_vertex
		elif i == branches - 1:
			local_indices[5] = i2
			var p:Vector2 = Vector2(-bottom_width, 0).rotated(local_right)
			p = connect_to_branch(p, right, local_right, a)
			local_verts.append(p)
			last_vertex += 1
			local_indices[0] = last_vertex
		else:
			var p1 = local_center + Vector2(-bottom_width,0).rotated(local_right)
			p1 = connect_to_branch(p1, right, local_right, a)
			var p2 = local_center + Vector2(bottom_width,0).rotated(local_right)
			p2 = connect_to_branch(p2, right, local_right, a)
			local_verts.append_array([p1,p2])
			last_vertex += 2
			local_indices[0] = last_vertex - 1
			local_indices[5] = 
		
		place_dot(local_center)
		vertices.append(local_center)
		last_vertex = vertices.size() - 1
		bottom_indices.append(last_vertex)
		colors.append(color)
		v_id_array.append(v_id)
	bottom_indices.push_back(i2)
	for b in branches:
		var local_angle = lerp(-angle,angle, float(b) / float(branches - 1))
		var branch:PackedVector2Array = new_branch(start_point,end_point,height,local_angle)
		vertices.append_array(branch)
		last_vertex = vertices.size() - 1
		indices.append_array([bottom_indices[b],last_vertex - 1, last_vertex])
		indices.append_array([bottom_indices[b],last_vertex, bottom_indices[b+1]])
		v_id_array.append_array([v_id, v_id + 1, v_id + 1])
		v_id_array.append_array([v_id, v_id + 1, v_id])
		colors.append_array([color,color])
		if v_id < iterations:
			branch(last_vertex - 1,last_vertex, v_id + 1)

func connect_to_branch(p:Vector2, right:float, local_right:float, local_up:float) -> Vector2:
	var opp:float = p.rotated(-right).y
	var hyp:float = sin(opp)
	p += Vector2(hyp, 0).rotated(local_up + PI)
	return p

func _ready() -> void:
	
	height_incr = 1. / float(iterations)
	
	root_branch()
	branch(1,2)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_COLOR] =  colors
	var flags = Mesh.ARRAY_FORMAT_VERTEX + Mesh.ARRAY_FORMAT_COLOR + Mesh.ARRAY_FORMAT_INDEX 
	tree_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},flags)
	mesh = tree_mesh

func max_branches()->int:
	var m = 0
	var e = iterations
	while e >= 0:
		m += pow(branches, e)
		e -= 1
	return m
#------------------OLD------------------
#var branch_scene = preload("res://branch.tscn")
#var root_branch:Line2D
#func _ready() -> void:
	#root_branch = branch_scene.instantiate()
	#root_branch.root = true
	#root_branch.world = self
	#add_child(root_branch)
	#node_ready = true
	#update_all()
	#count_branches()
	#pass
#func count_branches():
	#print("There are " + str(root_branch.get_branch_count()) + " branches in the tree")
	#print("There should be " + str(max_branches()) + " in the tree")
#
#func update_iterations():
	#if node_ready:
		#root_branch.update_iterations()
		#count_branches()
#
#func update_branches():
	#if node_ready:
		#root_branch.update_branches()
		#count_branches()
#
#func update_angle():
	#if node_ready:
		#root_branch.update_angle()
#
#
#func update_width():
	#if node_ready:
		#root_branch.update_width()
#
#func update_length():
	#if node_ready:
		#root_branch.update_length()
#
#func update_random():
	#if node_ready:
		#root_branch.update_random()
#
#func update_all():
	#if node_ready:
		#root_branch.update_iterations()
		#root_branch.update_branches()
		#root_branch.update_angle()
		#root_branch.update_length()
		#root_branch.update_random()
