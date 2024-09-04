extends Node2D

#todo
#switch to mesh-based tree
#swaying/wind

@export_category("Branch Count")
@export var iterations:int = 2:
	set(v):
		iterations = v
		update_iterations()
@export var branches:int = 2:
	set(v):
		branches = v
		update_branches()
@export_category("Position")
@export_range(-PI,PI) var angle:float = 0.2:
	set(v):
		angle = v
		update_angle()
@export_range(-1,1) var angle_decay:float = 0.1:
	set(v):
		angle_decay = v
		update_angle()
@export_range(0,1) var angle_random:float = 0.:
	set(v):
		angle_random = v
		update_angle()
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
		update_length()


var tree_mesh:ArrayMesh

var rng = RandomNumberGenerator.new()
@export var random_seed = 420:
	set(v):
		random_seed = v
		rng.seed = random_seed
		update_random()

var branches_made = 0

var root_branch:Line2D
var node_ready = false

var branch_scene = preload("res://branch.tscn")
func _ready() -> void:
	root_branch = branch_scene.instantiate()
	root_branch.root = true
	root_branch.world = self
	add_child(root_branch)
	node_ready = true
	update_all()
	count_branches()
	pass

func max_branches()->int:
	var m = 0
	var e = iterations
	while e >= 0:
		m += pow(branches, e)
		e -= 1
	return m

func count_branches():
	print("There are " + str(root_branch.get_branch_count()) + " branches in the tree")
	print("There should be " + str(max_branches()) + " in the tasdadree")

func update_iterations():
	if node_ready:
		root_branch.update_iterations()
		count_branches()

func update_branches():
	if node_ready:
		root_branch.update_branches()
		count_branches()

func update_angle():
	if node_ready:
		root_branch.update_angle()

#func update_color():
	#if node_ready:
		#root_branch.update_color()

func update_width():
	if node_ready:
		root_branch.update_width()

func update_length():
	if node_ready:
		root_branch.update_length()

func update_random():
	if node_ready:
		root_branch.update_random()

func update_all():
	if node_ready:
		root_branch.update_iterations()
		root_branch.update_branches()
		root_branch.update_angle()
		#root_branch.update_color()
		#root_branch.update_width()
		root_branch.update_length()
		root_branch.update_random()
