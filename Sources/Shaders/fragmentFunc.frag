#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout (binding = 5) uniform Material {
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
} mat;

layout ( location = 0 ) in vec4 inColor;
layout ( location = 1 ) in vec2 inUV;
layout ( location = 2 ) in vec3 inNormal;
layout ( location = 3 ) in vec3 inFragmentPosition;
layout ( location = 4 ) in vec3 inEye;

layout (location = 0) out vec4 outFragColor;


void main() {
    outFragColor = inColor * mat.diffuse;
}
