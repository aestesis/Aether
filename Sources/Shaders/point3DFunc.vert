#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout (binding = 0) uniform UBO {
    mat4 view;
    mat4 world;
    vec3 eye;
} ubo;

layout ( location = 0 ) in vec3 inPosition;
layout ( location = 1 ) in float inSize;
layout ( location = 2 ) in vec4 inColor;

layout ( location = 0 ) out vec4 outColor;

void main() {
    vec4 pos = ubo.view * vec4(inPosition,1);
    float rz = 1/(1+pos.z*100);
    gl_PointSize = inSize * rz;
    gl_Position = pos;
    outColor = vec4(inColor.rgb,inColor.a*rz);
}
