extends Camera2D


@export var zoom_incr:float = 0.1

var drag:bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			3:#middle mouse
				if event.pressed == true:
					print("drag enabled")
					drag = true
				else:
					print("drag disabled")
					drag = false
			4:#mwheel up
				zoom += Vector2(zoom_incr,zoom_incr)
			5:#mwheel down
				zoom -= Vector2(zoom_incr,zoom_incr)
	if event is InputEventMouseMotion:
		if drag:
			position -= event.screen_relative / zoom.x
			
