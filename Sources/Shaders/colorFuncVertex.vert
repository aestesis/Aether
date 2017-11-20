#version 450
#extension GL_ARB_separate_shader_objects : enable


layout (std140, binding = 0) uniform bufferVals {
    mat4 matrix;
} u;

layout ( location = 0 ) out vec4 outColor;

layout ( location = 0 ) in vec3 position;
layout ( location = 1 ) in vec4 color;


void main() {
    gl_Position = u.matrix * vec4(position, 1.0);
    outColor = color;
}
