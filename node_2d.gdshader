shader_type canvas_item;

const float thickness = 0.2;
const float inner_radius = 0.6;

uniform bool rotate_mode;
uniform float starting_angle = 0.;
uniform float target_angle = 1.;

vec2 rotate(vec2 vec, float angle){
	float s = sin(angle);
	float c = cos(angle);
	mat2 rot = mat2(vec2(c, -s),vec2(s,c));
	return vec * rot;
}

bool rectangle(vec2 uv, float angle){
	vec2 vec = rotate(uv,-angle);
	if (abs(vec.y) < thickness / 2. && vec.x > 0.1 && vec.x < 1.){
		return true;
	}
	return false;
}

float atan2(float y, float x){
	float s = float(abs(x) > abs(y));
	return mix((PI/2.0) - atan(x,y), atan(y,x), s);
}
//a and b are angles between (-TAU, TAU), dir is direction of the difference
float angle_difference(float a, float b, float dir){
	float diff;
	if (dir > 0.){
		if (b < a){
			b += TAU;
		}
		diff = b - a; 
	}
	if (dir < 0.){
		if (b > a){
			b += TAU;
		}
		diff = b - a;
	}
	return diff;
}

void fragment() {
	vec2 uv = 2. * (UV - vec2(0.5));
	vec3 col = vec3(0.);
	float a1 = mod(starting_angle + PI, 2. * PI) - PI;
	float a2 = mod(target_angle + PI, 2. * PI) - PI;
	if (!rotate_mode){
		if (length(uv) > inner_radius && length(uv) < inner_radius + thickness){
			col = vec3(1.);
		}
	}
	if (rotate_mode){
		if (rectangle(uv,a1)){
			col = vec3(1.,0,0);
		}
		if (rectangle(uv, a2)){
			col = vec3(1.);
		}
	
		
		float uv_angle = atan(uv.y,uv.x);
		float dir = sign(target_angle - starting_angle);
		float target_angle_diff = angle_difference(starting_angle,target_angle,dir);
		float uv_angle_diff = angle_difference(starting_angle,uv_angle,dir);
		
		//if (abs(uv_angle_diff) > abs(target_angle_diff) && abs(uv_angle_diff) > 0.){
			//discard;
		//}
	}
	if(col == vec3(0.)){
		discard;
	}
	COLOR = vec4(col,1.);
}

