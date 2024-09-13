extends ColorRect

var grid:Array
@export var grid_size:int = 100##grid size in cells
@export var grid_size_px:int = 1000##grid size in pixels
@export var draw_grid:bool = false:
	set(v):
		draw_grid = v
		material.set_shader_parameter("draw_grid", v)

var cell_size:float##cell size in pixels
var center_offset:Vector2##pixels from top left corner to center of grid
var offset:Vector2##pixel offset for the whole grid

var selected_cell:Vector2i:
	set(v):
		selected_cell = v
		material.set_shader_parameter("selected_cell", v)

func empty_grid():
	grid = []
	for x in grid_size:
		grid.append([])
		for y in grid_size:
			grid[x].append([])

##searches grid cells around a central cell, adds contents to arr
func search_cells(start_cell:Vector2i,) -> Array:
	var contents = []
	selected_cell = start_cell
	#print(selected_cell)
	#print(start_cell)
	var cell:Vector2i
	for x in 3:
		for y in 3:
			cell = start_cell + Vector2i(x - 1, y - 1)
			cell.x = clamp(cell.x, 0, grid_size - 1)
			cell.y = clamp(cell.y, 0, grid_size - 1)
			contents.append_array(grid[cell.x][cell.y])
	return contents
	

func get_cell(pos:Vector2) -> Vector2i:
	
	var cell:Vector2i = Vector2i((pos + center_offset) / cell_size)
	cell.x = clamp(cell.x,0, grid_size - 1)
	cell.y = clamp(cell.y,0, grid_size - 1)
	return cell

func place_on_grid(node:Node) -> Vector2i:
	var cell = get_cell(node.global_position)
	grid[cell.x][cell.y].append(node)
	return cell

func update_dimensions():
	custom_minimum_size = Vector2(grid_size_px,grid_size_px)
	cell_size = grid_size_px / float(grid_size)
	center_offset = Vector2(0.5,0.5) * grid_size_px
	position = offset - center_offset
	material.set_shader_parameter("grid_size", grid_size)
	material.set_shader_parameter("grid_size_px", grid_size_px)

func _ready() -> void:
	update_dimensions()
	pass
