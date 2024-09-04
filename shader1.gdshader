shader_type canvas_item;

uniform sampler2D color_gradient;
uniform sampler2D width_curve;
varying smooth float height;
uniform float v_id = 0;
uniform float iterations = 1;

void vertex(){
	int id = VERTEX_ID % 4;//mod 4; the vertex buffer contains ALL vertices
	float increment = 1. / iterations;
	height = v_id * increment ;
	if (id < 2){
		height += increment;
	}
	VERTEX.x *= texture(width_curve,vec2(height,0)).x;
}

void fragment() {
	vec3 col = texture(color_gradient, vec2(height,0)).rgb;
	COLOR = vec4(col,1.);
}


