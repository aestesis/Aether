
#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout (binding = 5) uniform sampler2D source;

layout (location = 0) in vec4 inColor;
layout (location = 1) in vec2 inUV;

layout (location = 0) out vec4 outFragColor;


void main() {
    outFragColor = vec4(0,0,0,texture(source, inUV).a * inColor);
}
