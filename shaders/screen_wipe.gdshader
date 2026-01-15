shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int direction = 0; // 0=right, 1=left, 2=down, 3=up
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    float edge;

    if (direction == 0) {
        edge = UV.x;
    } else if (direction == 1) {
        edge = 1.0 - UV.x;
    } else if (direction == 2) {
        edge = UV.y;
    } else {
        edge = 1.0 - UV.y;
    }

    COLOR = edge < progress ? color : vec4(0.0);
}