#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout (binding = 5) uniform Material {
    vec4  ambient;
    vec4  diffuse;
    vec4  specular;
    float shininess;
} material;
layout (binding = 6) uniform sampler2D source;

layout (location = 0) in vec4 inColor;

layout (location = 0) out vec4 outFragColor;


void main() {
    outFragColor = inColor * material.diffuse * texture(source,gl_PointCoord);
}
