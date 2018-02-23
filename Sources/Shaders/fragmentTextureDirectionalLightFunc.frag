#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

layout (binding = 5) uniform Material {
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
} material;
layout (binding = 6) uniform Directional {
    vec4 color;
    float intensity;
    vec3 direction;
} light;
layout (binding = 7) uniform sampler2D source;

layout ( location = 0 ) in vec4 inColor;
layout ( location = 1 ) in vec2 inUV;
layout ( location = 2 ) in vec3 inNormal;
layout ( location = 3 ) in vec3 inFragmentPosition;
layout ( location = 4 ) in vec3 inEye;

layout (location = 0) out vec4 outFragColor;


void main() {
    vec3 normal = normalize(inNormal);
    vec4 c = vec4(0,0,0,0);
    c += light.color*light.intensity*material.ambient;
    float diffuseFactor = max(0.0,dot(normal,light.direction));
    if(diffuseFactor>0) {
        c += light.color*light.intensity*material.diffuse*diffuseFactor;
        vec3 hv = normalize(inEye-light.direction);
        float specularFactor = pow(max(0.0,dot(normal,hv)),material.shininess);
        c += material.specular*specularFactor*min(1.0,diffuseFactor*3.0);
    }
    outFragColor = c * texture(source,inUV) * inColor;
}
