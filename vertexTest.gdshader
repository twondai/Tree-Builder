shader_type canvas_item;

const vec3 colors[4] = {vec3(1.),vec3(1.,0.,0.),vec3(0.,1.,0.),vec3(0.,0.,1.)};
uniform sampler2D width_curve;
varying float height;

void vertex() {
	int id = VERTEX_ID;
	vec3 col = colors[VERTEX_ID];
	height = 0.5;
	if (id > 1){
		height = 1.;
	}
	VERTEX.x *= texture(width_curve, vec2(height,0)).x;
	COLOR = vec4(col,1.);
}

void fragment() {
	// Called for every pixel the material is visible on.
}

