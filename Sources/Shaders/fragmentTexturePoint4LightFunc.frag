#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

struct PointLight {
    vec4  color;
    float attenuationConstant;
    float attenuationLinear;
    float attenuationQuadratic;
    vec3  position;
};

layout (binding = 5) uniform Material {
    vec4  ambient;
    vec4  diffuse;
    vec4  specular;
    float shininess;
} material;
layout (binding = 6) uniform Point1 {
    PointLight light1;
};
layout (binding = 7) uniform Point2 {
    PointLight light2;
};
layout (binding = 8) uniform Point3 {
    PointLight light3;
};
layout (binding = 9) uniform Point4 {
    PointLight light4;
};
layout (binding = 10) uniform sampler2D source;

layout ( location = 0 ) in vec4 inColor;
layout ( location = 1 ) in vec2 inUV;
layout ( location = 2 ) in vec3 inNormal;
layout ( location = 3 ) in vec3 inFragmentPosition;
layout ( location = 4 ) in vec3 inEye;

layout (location = 0) out vec4 outFragColor;

vec4 calcLight(PointLight light) {
    vec4 c=vec4(0,0,0,0);
    vec3 normal = normalize(inNormal);
    vec3 lightdir = normalize(light.position - inFragmentPosition);
    float dist = length(light.position - inFragmentPosition);
    float diffuseFactor = max(0.0,dot(normal,lightdir));
    if(diffuseFactor>0) {
        float att = 1.0 / (light.attenuationConstant+light.attenuationLinear*dist+light.attenuationQuadratic*dist*dist);
        c += att * material.diffuse * diffuseFactor;
        vec3 hv = normalize(inEye+lightdir);
        float specularFactor = pow(max(0.0,dot(normal,hv)),material.shininess);
        c += att * material.specular*specularFactor*min(1.0,diffuseFactor*3.0);
    }
    return c * light.color;
}

void main() {
    PointLight l1 = light1;
    PointLight l2 = light2;
    PointLight l3 = light3;
    PointLight l4 = light4;
    vec4 c = material.ambient;
    c += calcLight(l1);
    c += calcLight(l2);
    c += calcLight(l3);
    c += calcLight(l4);
    outFragColor = c * inColor * texture(source,inUV);
}
