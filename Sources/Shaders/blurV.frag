
#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout (binding = 5) uniform sampler2D source;
layout (binding = 6) uniform Args {
    vec2 sigma;
} args;

layout (location = 0) in vec2 inUV;

layout (location = 0) out vec4 outFragColor;


void main() {
    const float o[] = { 0.0, 1.3846153846, 3.2307692308 };
    const float w[] = { 0.2270270270, 0.3162162162, 0.0702702703  };
    vec4 c = texture(source, inUV);
    c += texture(source,inUV+vec2(0,o[1]*args.sigma.y))*w[1];
    c += texture(source,inUV-vec2(0,o[1]*args.sigma.y))*w[1];
    c += texture(source,inUV+vec2(0,o[2]*args.sigma.y))*w[2];
    c += texture(source,inUV-vec2(0,o[2]*args.sigma.y))*w[2];
    outFragColor = c;
}
