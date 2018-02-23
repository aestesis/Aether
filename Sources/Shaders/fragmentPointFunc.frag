#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout (binding = 5) uniform Material {
    vec4  ambient;
    vec4  diffuse;
    vec4  specular;
    float shininess;
} material;

layout (location = 0) in vec4 inColor;

layout (location = 0) out vec4 outFragColor;


void main() {
    float a = max(0.0,2*(0.5-length(gl_PointCoord-vec2(0.5,0.5))));
    outFragColor = inColor * material.diffuse * vec4(1,1,1,a);
}
