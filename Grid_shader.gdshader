shader_type canvas_item;

uniform bool draw_grid = false;
uniform float grid_size = 100.;
uniform float grid_size_px = 1000.;
uniform ivec2 selected_cell;

uniform float line_thickness = 0.1;

void fragment() {
	if (!draw_grid){
		discard;
	}
	vec2 uv = UV * grid_size;
	ivec2 id = ivec2(uv);
	bool is_selected = (id == selected_cell);
	uv = mod(uv,1.);
	vec3 col = vec3(0.);
	if (min(uv.x, uv.y) > line_thickness){
		COLOR.w = 0.;
	}
	if (is_selected){
		COLOR.w = 0.1;
		col = vec3(1.,0,0);
	}
	COLOR.rgb = col;
}

