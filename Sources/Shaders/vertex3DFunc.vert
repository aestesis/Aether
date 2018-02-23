#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout (binding = 0) uniform UBO {
    mat4 view;
    mat4 world;
    vec3 eye;
} ubo;

layout ( location = 0 ) in vec3 inPosition;
layout ( location = 1 ) in vec4 inColor;
layout ( location = 2 ) in vec2 inUV;
layout ( location = 3 ) in vec3 inNormal;

layout ( location = 0 ) out vec4 outColor;
layout ( location = 1 ) out vec2 outUV;
layout ( location = 2 ) out vec3 outNormal;
layout ( location = 3 ) out vec3 outFragmentPosition;
layout ( location = 4 ) out vec3 outEye;

void main() {
    gl_Position = ubo.view * vec4(inPosition,1);
    outNormal = normalize((ubo.world*vec4(inNormal,0)).xyz);
    outFragmentPosition = (ubo.world*vec4(inPosition,1)).xyz;
    outColor = inColor;
    outUV = inUV;
    outEye = normalize(ubo.eye-outFragmentPosition);
}
