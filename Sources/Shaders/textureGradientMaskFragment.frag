
#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout (binding = 5) uniform sampler2D source;
layout (binding = 6) uniform sampler2D mask;
layout (binding = 7) uniform sampler2D gradient;

layout (location = 0) in vec4 inColor;
layout (location = 1) in vec2 inUV;
layout (location = 2) in vec2 inUVmask;

layout (location = 0) out vec4 outFragColor;


void main() {
    vec4 cs = texture(source, inUV);
    float ls = cs.r*0.3333+cs.g*0.3333+cs.b*0.3333;
    vec4 cg = texture(gradient, vec2(ls,0));
    vec4 c = mix(cs,cg,inColor.a);
    vec4 m = texture(mask, inUVmask);
    outFragColor =  vec4(c.rgb*inColor.rgb,m.a*m.r*c.a);
}
