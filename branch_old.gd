extends Line2D

var branch_scene = preload("res://branch.tscn")

#var iterations:int = 2
#var branches:int = 2
#var angle:float = 0.2
#var start_color:Color
#var end_color:Color

var branch_id:int = 0
var branch_ready:bool = false

var color_gradient:Gradient
var world:Node2D
var angle_random:float = 0
var root:bool = false ##is this branch the root/bottom branch
var v_id:int = 0: ##vertical index; how far up the tree this branch is
	set(v):
		v_id = v
		set_uniform("v_id", v_id)
var h_id:int = 0 ##horizontal index; how many branches with the same parent branch are to the left of this one
var height:float##how high up the tree this branch is, from 0 to 1
	

func _ready() -> void:
	height = float(v_id)/ float(world.iterations)
	z_index = v_id
	if v_id < world.iterations:
		branch(true)

func get_branch_count() -> int:#recursively counts child and sub-child branches
	var count = 1
	
	for b in get_children():
		count += b.get_branch_count()
	return count

func update_iterations(deep:bool = true) -> void:
	set_uniform("iterations",world.iterations)
	height = float(v_id)/ float(world.iterations)
	if deep:
		for b in get_children():
			b.update_iterations()
		
	if v_id > world.iterations: #free branch if it exceeds the iteration limit
		queue_free()
	if v_id < world.iterations && get_child_count() == 0: #branch() if end of tree and more iterations needed
		branch(true)
	#update_color()
	if branch_ready:
		update_length()

func update_branches(deep:bool = true) -> void:
	var branches = get_child_count()
	if branches < world.branches && v_id < world.iterations: #add new branches if needed, and not end of tree
		#print("creating new branches")
		while branches < world.branches:#loop over the difference in branch amount
			var branch = new_branch()
			branch.v_id = v_id + 1
			branch.h_id = branches
			branch.position = points[1]
			branches += 1
			branch.update_uniforms()
			add_child(branch)
			
	elif h_id >= world.branches: #free branch if h_id is greater than the max h_id
		queue_free()
		
	if branch_ready:
		update_length()
		update_angle()
	if deep:
		for b in get_children():
			b.update_branches()

func update_angle(deep:bool = true) -> void:
	if deep:
		for b in get_children():
			b.update_angle()
	var angle = world.angle + angle_random * world.angle_random
	angle = lerp(angle, angle * (1. - world.angle_decay), height)
	if !root:
		rotation = lerp(-angle, angle, float(h_id) / float(world.branches - 1))


func update_length(deep:bool = true) -> void:
	points[1].y = -world.length_curve.sample(height)
	if deep:
		for b in get_children():
			b.update_length()
			b.position = points[1]

func update_random(deep:bool = true):
	world.rng.seed = world.random_seed + branch_id
	angle_random = (world.rng.randf() * 2.) - 1.
	if branch_ready:
		update_angle()
	if deep:
		for b in get_children():
			b.update_random()

func update_uniforms():
	set_uniform("v_id",v_id)
	set_uniform("iterations",world.iterations)


func update_all() -> void:
	update_iterations(false)#also updates width and length
	update_branches(false)#also calls update_angle
	update_angle(false)
	update_length(false)
	update_random(false)
	


func new_branch() -> Line2D:#blursed
	var branch = branch_scene.instantiate()
	world.branches_made += 1
	branch.branch_id = world.branches_made
	branch.world = world
	branch.position = points[1]
	return branch

func branch(auto_update = true) -> void:
	for b in world.branches:
		
		var branch = new_branch()
		branch.v_id = v_id + 1
		branch.h_id = b
		#print("h_id = " + str(b) + ", v_id = " + str(branch.v_id))
		#print("-------------------------")
		add_child(branch)
		if auto_update:
			branch.update_all()
		branch.branch_ready = true
		
		

func set_uniform(name, value) -> void:
	material.set_shader_parameter(name,value)
