shader_type canvas_item;

varying flat vec4 debug_color;

uniform bool debug_draw = false;

void vertex() {
	float id = float(VERTEX_ID) / 3.;
	vec3 incr = vec3(0.31524,0.4244,0.5152362) * id;
	vec3 col = vec3(1.,0.,0.);
	col = mod(col + incr,vec3(1.));
	debug_color = vec4(col,1);
}

void fragment() {
	if (debug_draw)
		COLOR = debug_color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
