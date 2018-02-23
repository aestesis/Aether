#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable


layout (binding = 0) uniform UBO {
    mat4 view;
    mat4 world;
    vec3 eye;
} ubo;
layout (binding = 1) uniform Height {
    float width;
    float height;
    float scale;
    float adjustNormals;
} uh;
layout (binding = 2) uniform sampler2D colors;
layout (binding = 3) uniform sampler2D heights;

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
    float dy = 1.0/uh.height;
    float dx = 1.0/uh.width;
    vec4 c = texture(colors,inUV);
    vec4 h = texture(heights,inUV);
    vec4 htop = texture(heights,inUV+vec2(0,-dy));
    vec4 hbottom = texture(heights,inUV+vec2(0,dy));
    vec4 hleft = texture(heights,inUV+vec2(-dx,0));
    vec4 hright = texture(heights,inUV+vec2(dx,0));
    vec3 n = normalize(inNormal);
    float t = atan(n.y,n.x);
    float p = acos(n.z);
    if(isnan(t)) {
        t = 0;
    }
    vec2 dt = vec2((hbottom.r - htop.r)*uh.adjustNormals,dx*2);
    t -= atan(dt.y,dt.x);
    vec2 dp = vec2((hright.r - hleft.r)*uh.adjustNormals,dy*2);
    p += atan(dp.x,dp.y);
    n.x = sin(p) * cos(t);
    n.y = sin(p) * sin(t);
    n.z = cos(p);
    vec3 pos = inPosition + inNormal * h.r * uh.scale;
    gl_Position = ubo.view * vec4(pos,1);
    outNormal = normalize((ubo.world*vec4(n,0)).xyz);
    outFragmentPosition = (ubo.world*vec4(pos,1)).xyz;
    outColor = inColor*c;
    outUV = inUV;
    outEye = normalize(ubo.eye-outFragmentPosition);
}
