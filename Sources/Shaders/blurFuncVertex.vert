#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout (binding = 0) uniform UBO {
    mat4 matrix;
} ubo;

layout ( location = 0 ) in vec3 inPosition;
layout ( location = 1 ) in vec2 inUV;

layout ( location = 0 ) out vec2 outUV;

void main() {
    outUV = inUV;
    gl_Position = ubo.matrix * vec4(inPosition,1);
}