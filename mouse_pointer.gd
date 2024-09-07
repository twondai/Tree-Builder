extends Area2D


@export var selection_indicator:Sprite2D
@export var camera:Camera2D

var nearby_nodes:Array
var selected_node:Node2D

var drag:bool = false

func move_indicator(relative:Vector2):
	
	
	if !drag:
		position = get_global_mouse_position()
		if nearby_nodes.size() > 0:
			var smallest_distance:float = 100000000
			var closest_node:Node2D
			for n in nearby_nodes:
				var distance = (n.global_position - position).length()
				if distance < smallest_distance:
					smallest_distance = distance
					closest_node = n.get_parent()
			selection_indicator.global_position = closest_node.global_position
			selected_node = closest_node
		else:
			selection_indicator.global_position = global_position
	else:
		position += relative
		selection_indicator.global_position = global_position


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		move_indicator(event.screen_relative / camera.zoom.x)
	if event is InputEventMouseButton:
		match event.button_index:
			1:
				if event.pressed && selected_node != null:
					print("mouse drag enabled")
					drag = true
				else:
					if selected_node != null:
						selected_node.update_position(selection_indicator.global_position)
					print("mouse drag disabled")
					drag = false
	pass


func _on_area_entered(area: Area2D) -> void:
	if selected_node != area:
		nearby_nodes.append(area)
func _on_area_exited(area: Area2D) -> void:
	if selected_node == area:
		if !drag:
			nearby_nodes.erase(area)
			selected_node = null
	else:
		nearby_nodes.erase(area)
