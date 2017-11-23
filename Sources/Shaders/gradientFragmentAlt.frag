
#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout (binding = 1) uniform sampler2D source;
layout (binding = 2) uniform sampler2D gradient;

layout (location = 0) in vec4 inColor;
layout (location = 1) in vec2 inUV;

layout (location = 0) out vec4 outFragColor;


void main() {
    vec4 cs = texture(source, inUV);
    float ls = cs.r*0.3333+cs.g*0.3333+cs.b*0.3333;
    vec4 cg = texture(gradient, vec2(ls,0));
    outFragColor =  vec4(mix(cs.rgb,cg.rgb,cg.a*inColor.a)*inColor.rgb,inColor.a);
}
