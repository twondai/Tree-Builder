extends Area2D

signal drag_changed

@export var selector_enabled:bool = true

@export var selection_indicator:Sprite2D
@export var camera:Camera2D

@export var grid:Node
var grid_cell:Vector2i

var nearby_nodes:Array
var selected_node:Node2D

var drag:bool = false
var rotate_mode:bool = false:
	set(v):
		rotate_mode = v
		drag_changed.emit()
var starting_angle:float 
var target_angle:float

func update_cursor(relative:Vector2):
	if !drag:
		position = get_global_mouse_position()
		var mouse_cell = grid.get_cell(global_position)
		if (mouse_cell != grid_cell):
			nearby_nodes = grid.search_cells(mouse_cell)
		#snap to the nearest node within range
		if nearby_nodes.size() > 0 && selector_enabled:
			var smallest_distance:float = 100000000
			var closest_node:Node2D
			for n in nearby_nodes:#select closest node
				var distance = (n.global_position - global_position).length()
				if distance < smallest_distance:
					smallest_distance = distance
					closest_node = n
			selection_indicator.global_position = closest_node.global_position#move indicator to node
			selected_node = closest_node
		else:
			selection_indicator.global_position = global_position
			if selected_node:
				selected_node = null
	else:
		if !rotate_mode:
			position += relative
			selection_indicator.global_position = global_position
		else:
			target_angle = (get_global_mouse_position() - selection_indicator.global_position).angle()
			selector_uniform("target_angle", target_angle)



##counts how many times each node appears in nearby nodes, ideally should be once per node
func count_nodes():
	for b in nearby_nodes:
		if nearby_nodes.count(b) > 1:
			print("found more than one instance of node: " + str(b))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update_cursor(event.screen_relative / camera.zoom.x)
	if event is InputEventMouseButton:
		match event.button_index:
			1:
				if event.pressed && selected_node != null:
					print("mouse drag enabled")
					if rotate_mode:
						selector_uniform("rotate_mode", true)
						starting_angle = selected_node.get_angle()
						selector_uniform("starting_angle", starting_angle)
						target_angle = (get_global_mouse_position() - selection_indicator.global_position).angle()
						selector_uniform("target_angle", target_angle)
					drag = true
				else:
					if selected_node != null:
						if rotate_mode:
							selected_node.update_angle(target_angle)
							selector_uniform("rotate_mode", false)
						else:
							selected_node.update_position(selection_indicator.global_position)
					print("mouse drag disabled")
					drag = false
	if event is InputEventKey:
		match event.keycode:
			4194326:#ctrl key
				if !event.echo:
					if drag:
						await drag_changed
					rotate_mode = event.pressed
					print("rotate mode: " + str(rotate_mode))

func get_shortest_rotation(a1:float, a2:float) -> float:
	var diff:float = a2 - a1
	if abs(diff) > PI:
		diff = a1 + (TAU - a2)
	return diff

func selector_uniform(id:String, value):
	selection_indicator.material.set_shader_parameter(id, value)
