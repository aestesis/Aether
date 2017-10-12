//
//  default.metal
//  Alib
//
//  Created by renan jegouzo on 20/03/2016.
//  Copyright © 2016 aestesis. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct Uniforms
{
    float4x4 matrix;
};
struct Uniforms3d
{
    float4x4 view;
    float4x4 world;
    float3 eye;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
constant half3 zero = half3(0,0,0);
constant half3 one = half3(1,1,1);
constant half3 two = one * 2.0;
constant half e = 1e-10;
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
half mixColorBurn(half a, half b);
half mixColorDodge(half a, half b);
half mixHardLight(half a, half b);
half mixOverlay(half a, half b);
//////////////////////////////////////////////////////////////////////////////////////////////////////////
half mixColorBurn(half a, half b) {
    return 1.0-(1.0-a)/(b+e);
}
half mixColorDodge(half a, half b) {
    return a/(1.0+e-b);
}
half mixHardLight(half a, half b) {
    if(b<0.5)
        return 2.0*a*b;
    else
        return 1.0-2.0*(1.0-a)*(1.0-b);
}
half mixOverlay(half a, half b) {
    if(a<0.5)
        return 2.0*a*b;
    else
        return 1.0-2.0*(1.0-a)*(1.0-b);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct colorVerticeIn
{
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};
struct colorVertice
{
    float4 position [[position]];
    half4 color;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex colorVertice colorFuncVertex(device colorVerticeIn *vin [[buffer(0)]],constant Uniforms &u [[buffer(1)]],uint vid [[vertex_id]])
{
    colorVertice vout;
    vout.position = u.matrix * float4(vin[vid].position, 1);
    vout.color = half4(vin[vid].color);
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 colorFuncFragment(colorVertice v [[stage_in]])
{
    return v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
#if PROGBLENDING
fragment half4 colorBlendMultiply(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = cb.rgb * co.rgb;
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendScreen(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = one-(one-cb.rgb)*(one-co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendOverlay(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend =  half3(mixOverlay(cb.r,co.r),mixOverlay(cb.g,co.g),mixOverlay(cb.b,co.b));
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendSoftLight(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = (one-two*co.rgb)*cb.rgb*cb.rgb+two*co.rgb*cb.rgb;
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendLighten(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = max(cb.rgb,co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendDarken(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = min(cb.rgb,co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendAverage(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = (cb.rgb + co.rgb) * 0.5;
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendSubstract(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    return half4(cb.rgb+(co.rgb-one)*opa,max(opa,cb.a));
}
fragment half4 colorBlendDifference(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    return half4(abs(cb.rgb-co.rgb*opa),max(opa,cb.a));
}
fragment half4 colorBlendNegation(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = one-abs(one-cb.rgb-co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendColorDodge(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend =  min(one,half3(mixColorDodge(cb.r,co.r),mixColorDodge(cb.g,co.g),mixColorDodge(cb.b,co.b)));
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendColorBurn(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend =  max(zero,half3(mixColorBurn(cb.r,co.r),mixColorBurn(cb.g,co.g),mixColorBurn(cb.b,co.b)));
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendHardLight(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend =  half3(mixHardLight(cb.r,co.r),mixHardLight(cb.g,co.g),mixHardLight(cb.b,co.b));
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendReflect(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = cb.rgb*cb.rgb/(half3(1.01,1.01,1.01)-co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendGlow(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = co.rgb*co.rgb/(half3(1.01,1.01,1.01)-cb.rgb);
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendPhoenix(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = min(cb.rgb,co.rgb)+max(cb.rgb,co.rgb)-one;
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
fragment half4 colorBlendExclusion(colorVertice v [[stage_in]], half4 cb [[color(0)]])
{
    half3 co = v.color.rgb;
    half opa = v.color.a;
    half3 blend = cb.rgb+co.rgb-2.0*cb.rgb*co.rgb;
    return half4(mix(cb.rgb,blend,opa),max(opa,cb.a));
}
#endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct textureVerticeIn
{
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
    float2 uv [[attribute(2)]];
};
struct textureVertice
{
    float4 position [[position]];
    half4 color;
    float2 uv;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct textureMaskVerticeIn
{
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
    float2 uv [[attribute(2)]];
    float2 uvmask [[attribute(3)]];
};
struct textureMaskVertice
{
    float4 position [[position]];
    half4 color;
    float2 uv;
    float2 uvmask;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex textureVertice textureFuncVertex(device textureVerticeIn *vin [[buffer(0)]],constant Uniforms &u [[buffer(1)]],uint vid [[vertex_id]])
{
    textureVertice vout;
    vout.position = u.matrix * float4(vin[vid].position, 1);
    vout.uv = vin[vid].uv;
    vout.color = half4(vin[vid].color);
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex textureMaskVertice textureBitmapMaskFuncVertex(device textureMaskVerticeIn *vin [[buffer(0)]],constant Uniforms &u [[buffer(1)]],uint vid [[vertex_id]])
{
    textureMaskVertice vout;
    vout.position = u.matrix * float4(vin[vid].position, 1);
    vout.uv = vin[vid].uv;
    vout.uvmask = vin[vid].uvmask;
    vout.color = half4(vin[vid].color);
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 textureFuncFragment(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]])
{
    half4 c=t.sample(s,v.uv).rgba;
    return c*v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 textureFuncFragmentColor(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]])
{
    half c=t.sample(s,v.uv).r;
    return half4(v.color.rgb,c*v.color.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 textureFuncFragmentSetAlpha(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]])
{
    half c=t.sample(s,v.uv).r;
    return half4(0,0,0,c*v.color.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 textureMaskFragment(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<half> mask [[texture(1)]], sampler s [[sampler(0)]])
{
    half4 c = t.sample(s,v.uv);
    half4 m = mask.sample(s,v.uv);
    return half4(c.rgb*v.color.rgb,m.a*m.r*c.a*v.color.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 textureBitmapMaskFragment(textureMaskVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<half> mask [[texture(1)]], sampler s [[sampler(0)]])
{
    half4 c = t.sample(s,v.uv);
    half4 m = mask.sample(s,v.uvmask);
    return half4(c.rgb*v.color.rgb,m.a*m.r*c.a*v.color.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 textureGradientMaskFragment(textureMaskVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<half> mask [[texture(1)]], texture2d<half> gradient [[texture(2)]], sampler s [[sampler(0)]])
{
    constexpr sampler ss(coord::normalized,s_address::clamp_to_edge,t_address::clamp_to_edge,filter::linear);
    half4 cs = t.sample(s,v.uv).rgba;
    float ls = cs.r*0.3333+cs.g*0.3333+cs.b*0.3333;
    half4 cg = gradient.sample(ss,float2(ls,0)).rgba;
    half4 c = mix(cs,cg,v.color.a);
    half4 m = mask.sample(ss,v.uvmask);
    return half4(c.rgb*v.color.rgb,m.a*m.r*c.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
#if PROGBLENDING
fragment half4 textureFuncFragmentMulAlpha(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 fbc [[color(0)]] )
{
    half c=t.sample(s,v.uv).r;
    return half4(0,0,0,fbc.a*c*v.color.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 textureBlendMultiply(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = cb.rgb * co.rgb;
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendScreen(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = one-(one-cb.rgb)*(one-co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendOverlay(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend =  half3(mixOverlay(cb.r,co.r),mixOverlay(cb.g,co.g),mixOverlay(cb.b,co.b));
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendSoftLight(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = (one-two*co.rgb)*cb.rgb*cb.rgb+two*co.rgb*cb.rgb;
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendLighten(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = max(cb.rgb,co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendDarken(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = min(cb.rgb,co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendAverage(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = (cb.rgb + co.rgb) * 0.5;
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendSubstract(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    return half4(cb.rgb+(co.rgb-one)*opa,max(c.a,cb.a));
}
fragment half4 textureBlendDifference(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    return half4(abs(cb.rgb-co.rgb*opa),max(c.a,cb.a));
}
fragment half4 textureBlendNegation(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = one-abs(one-cb.rgb-co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendColorDodge(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend =  min(one,half3(mixColorDodge(cb.r,co.r),mixColorDodge(cb.g,co.g),mixColorDodge(cb.b,co.b)));
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendColorBurn(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend =  max(zero,half3(mixColorBurn(cb.r,co.r),mixColorBurn(cb.g,co.g),mixColorBurn(cb.b,co.b)));
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendHardLight(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend =  half3(mixHardLight(cb.r,co.r),mixHardLight(cb.g,co.g),mixHardLight(cb.b,co.b));
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendReflect(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = cb.rgb*cb.rgb/(half3(1.01,1.01,1.01)-co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendGlow(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = co.rgb*co.rgb/(half3(1.01,1.01,1.01)-cb.rgb);
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendPhoenix(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = min(cb.rgb,co.rgb)+max(cb.rgb,co.rgb)-one;
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
fragment half4 textureBlendExclusion(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], half4 cb [[color(0)]])
{
    half4 c = t.sample(s,v.uv);
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = cb.rgb+co.rgb-2.0*cb.rgb*co.rgb;
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
#endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct blurParams
{
    float2 sigma;
};
struct blurVerticeIn
{
    float3 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
};
struct blurVertice
{
    float4 position [[position]];
    float2 uv;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex blurVertice blurFuncVertex(device blurVerticeIn *vin [[buffer(0)]],constant Uniforms &u [[buffer(1)]],uint vid [[vertex_id]])
{
    blurVertice vout;
    vout.position = u.matrix * float4(vin[vid].position, 1);
    vout.uv = vin[vid].uv;
    return vout;
}
fragment half4 blurH(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], constant blurParams &p[[buffer(0)]])
{
    const float o[] = { 0.0, 1.3846153846, 3.2307692308 };
    const float w[] = { 0.2270270270, 0.3162162162, 0.0702702703  };
    half4 c=t.sample(s,v.uv)*w[0];
    for(int i=1; i<3; i++) {
        c += t.sample(s,v.uv+float2(o[i]*p.sigma.x,0))*w[i];
        c += t.sample(s,v.uv-float2(o[i]*p.sigma.x,0))*w[i];
    }
    return c;
}
fragment half4 blurV(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], constant blurParams &p[[buffer(0)]])
{
    const float o[] = { 0.0, 1.3846153846, 3.2307692308 };
    const float w[] = { 0.2270270270, 0.3162162162, 0.0702702703  };
    half4 c=t.sample(s,v.uv)*w[0];
    for(int i=1; i<3; i++) {
        c += t.sample(s,v.uv+float2(0,o[i]*p.sigma.y))*w[i];
        c += t.sample(s,v.uv-float2(0,o[i]*p.sigma.y))*w[i];
    }
    return c;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct blendParams
{
    float opacity;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct blendVerticeIn
{
    float3 position [[attribute(0)]];
    float2 uv [[attribute(2)]];
};
struct blendVertice
{
    float4 position [[position]];
    half4 color;
    float2 uv;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex blendVertice blendFuncVertex(device blendVerticeIn *vin [[buffer(0)]],constant Uniforms &u [[buffer(1)]],uint vid [[vertex_id]])
{
    blendVertice vout;
    vout.position = u.matrix * float4(vin[vid].position, 1);
    vout.uv = vin[vid].uv;
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendMultiply(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = cb.rgb * co.rgb;
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendScreen(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = one-(one-cb.rgb)*(one-co.rgb);
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendOverlay(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend =  half3(mixOverlay(cb.r,co.r),mixOverlay(cb.g,co.g),mixOverlay(cb.b,co.b));
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendSoftLight(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = (one-two*co.rgb)*cb.rgb*cb.rgb+two*co.rgb*cb.rgb;
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendAdd(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    return half4(cb.rgb + co.rgb * opa,co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendLighten(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = max(cb.rgb,co.rgb);
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendDarken(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = min(cb.rgb,co.rgb);
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendAverage(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = (cb.rgb + co.rgb) * 0.5;
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendSubstract(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    return half4(cb.rgb+(co.rgb-one)*opa,co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendDifference(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    return half4(abs(cb.rgb-co.rgb*opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendNegation(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = one-abs(one-cb.rgb-co.rgb);
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendColorDodge(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend =  min(one,half3(mixColorDodge(cb.r,co.r),mixColorDodge(cb.g,co.g),mixColorDodge(cb.b,co.b)));
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendColorBurn(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend =  max(zero,half3(mixColorBurn(cb.r,co.r),mixColorBurn(cb.g,co.g),mixColorBurn(cb.b,co.b)));
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendHardLight(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend =  half3(mixHardLight(cb.r,co.r),mixHardLight(cb.g,co.g),mixHardLight(cb.b,co.b));
    return half4(mix(cb.rgb,blend,opa),co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendReflect(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = cb.rgb*cb.rgb/(half3(1.01,1.01,1.01)-co.rgb);
    return half4(mix(cb.rgb,blend,opa),co.a);}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendGlow(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = co.rgb*co.rgb/(half3(1.01,1.01,1.01)-cb.rgb);
    return half4(mix(cb.rgb,blend,opa),co.a);}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendPhoenix(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = min(cb.rgb,co.rgb)+max(cb.rgb,co.rgb)-one;
    return half4(mix(cb.rgb,blend,opa),co.a);}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendSub(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    return half4(cb.rgb-co.rgb*opa,co.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 blendExclusion(blendVertice v [[stage_in]], texture2d<half> base [[texture(0)]], texture2d<half> over [[texture(1)]], sampler s [[sampler(0)]], constant blendParams &p[[buffer(0)]])
{
    half4 cb=base.sample(s,v.uv);
    half4 co=over.sample(s,v.uv);
    half opa = co.a * p.opacity;
    half3 blend = cb.rgb+co.rgb-2.0*cb.rgb*co.rgb;
    return half4(mix(cb.rgb,blend,opa),co.a);}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 gradientFragment(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<half> pal [[texture(1)]], sampler s [[sampler(0)]])
{
    constexpr sampler ss(coord::normalized,s_address::clamp_to_edge,t_address::clamp_to_edge,filter::linear);
    half4 cs = t.sample(s,v.uv).rgba;
    float ls = cs.r*0.3333+cs.g*0.3333+cs.b*0.3333;
    half4 cg = pal.sample(ss,float2(ls,0)).rgba;
    return mix(cs,cg,v.color.a)*half4(v.color.rgb,1);
}
fragment half4 altGradientFragment(textureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<half> pal [[texture(1)]], sampler s [[sampler(0)]])
{   // output.color = lerp( original , gradient.color , coef: gradient.alpha) , output.alpha = v.color.a
    constexpr sampler ss(coord::normalized,s_address::clamp_to_edge,t_address::clamp_to_edge,filter::linear);
    half4 cs = t.sample(s,v.uv).rgba;
    float ls = cs.r*0.3333+cs.g*0.3333+cs.b*0.3333;
    half4 cg = pal.sample(ss,float2(ls,0)).rgba;
    return half4(mix(cs.rgb,cg.rgb,cg.a*v.color.a)*v.color.rgb,v.color.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct Point3dIn{
    float3  position [[attribute(0)]];
    float   size [[attribute(1)]];
    float4  color [[attribute(2)]];
};
struct Point3dOut {
    float4  position [[position]];
    float   size [[point_size]];
    half4   color;
};
struct Vertex3dIn{
    float3  position [[attribute(0)]];
    float4  color [[attribute(1)]];
    float2  uv [[attribute(2)]];
    float3  normal [[attribute(3)]];
};
struct Vertex3dOut{
    float4  position [[position]];
    half4   color;
    float2  uv;
    float3  normal;
    float3  fragmentPosition;
    float3  eye;
};
struct DirectionalLight {
    float4  color;
    float   intensity;
    float3  direction;
};
struct PointLight {
    float4  color;
    float   attenuationConstant;
    float   attenuationLinear;
    float   attenuationQuadratic;
    float3  position;
};
struct Material {
    float4   ambient;
    float4   diffuse;
    float4   specular;
    float    shininess;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex Point3dOut point3DFunc(device Point3dIn *pin [[buffer(0)]],
                                constant Uniforms3d &u [[buffer(1)]],
                                uint id [[vertex_id]]) {
    Point3dOut pout;
    pout.position = u.view * float4(pin[id].position,1);
    float rz = 1/(1+pout.position.z*100);
    pout.size = 10*rz;
    pout.color = half4(pin[id].color);
    pout.color.a *= rz;
    return pout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex Vertex3dOut vertex3DFunc(device Vertex3dIn *vin [[buffer(0)]],
                                constant Uniforms3d &u [[buffer(1)]],
                                uint vid [[vertex_id]]) {
    Vertex3dOut vout;
    vout.position = u.view * float4(vin[vid].position,1);
    vout.normal = normalize((u.world*float4(vin[vid].normal,0)).xyz);
    vout.fragmentPosition = (u.world*float4(vin[vid].position,1)).xyz;
    vout.color = half4(vin[vid].color);
    vout.uv = vin[vid].uv;
    vout.eye = normalize(u.eye - vout.fragmentPosition);
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct UniformsHeight {
    float width;
    float height;
    float scale;
    float adjustNormals;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex Vertex3dOut vertex3DHeightFunc(  device Vertex3dIn *vin [[buffer(0)]],
                                        constant Uniforms3d &u [[buffer(1)]],
                                        constant UniformsHeight &uh [[buffer(2)]],
                                        texture2d<half> tc [[texture(0)]],
                                        texture2d<half> th [[texture(1)]],
                                        uint vid [[vertex_id]]) {
    constexpr sampler ss(coord::normalized,s_address::repeat,t_address::clamp_to_edge,filter::linear);
    Vertex3dOut vout;
    float dy = 1.0/uh.height;
    float dx = 1.0/uh.width;
    half4 c = tc.sample(ss,vin[vid].uv);
    half4 h = th.sample(ss,vin[vid].uv);
    half4 htop = th.sample(ss,vin[vid].uv+float2(0,-dy));
    half4 hbottom = th.sample(ss,vin[vid].uv+float2(0,dy));
    half4 hleft = th.sample(ss,vin[vid].uv+float2(-dx,0));
    half4 hright = th.sample(ss,vin[vid].uv+float2(+dx,0));
    float3 n = normalize(vin[vid].normal);
    float t = atan2(n.y,n.x);
    float p = acos(n.z);
    float2 dt = float2(float(hbottom.r - htop.r)*uh.adjustNormals,dx*2);
    t -= atan2(dt.y,dt.x);
    float2 dp = float2(float(hright.r - hleft.r)*uh.adjustNormals,dy*2);
    p += atan2(dp.x,dp.y); // maybe += or -= , not tested yet...
    n.x = sin(p) * cos(t);
    n.y = sin(p) * sin(t);
    n.z = cos(p);
    float3 pos = vin[vid].position + vin[vid].normal * float(h.r) * uh.scale;
    vout.position = u.view * float4(pos,1);
    vout.normal = normalize((u.world*float4(n,0)).xyz);
    vout.fragmentPosition = (u.world*float4(pos,1)).xyz;
    vout.color = half4(vin[vid].color) * c;
    vout.uv = vin[vid].uv;
    vout.eye = normalize(u.eye - vout.fragmentPosition);
    //vout.color = half4(0.5+(hright.r-hleft.r)*5,0/*0.5+(hbottom.r-htop.r)*5*/,0,1);   // 4debug
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex Vertex3dOut vertex3DBonesFunc(               device Vertex3dIn *vin [[buffer(0)]],   // TODO: finish it
                                                    constant Uniforms3d &u [[buffer(1)]],
//                                        constant Bones &bones [[buffer(2)]],
                                                    uint vid [[vertex_id]]) {
    Vertex3dOut vout;
    vout.position = u.view * float4(vin[vid].position,1);
    vout.normal = normalize((u.world*float4(vin[vid].normal,0)).xyz);
    vout.fragmentPosition = (u.world*float4(vin[vid].position,1)).xyz;
    vout.color = half4(vin[vid].color);
    vout.uv = vin[vid].uv;
    vout.eye = normalize(u.eye - vout.fragmentPosition);
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentPointFunc(                   Point3dOut p [[stage_in]],
                                                    float2 uv  [[point_coord]],
                                                    constant Material &material [[buffer(0)]]) {
    float a = max(0.0,2*(0.5-length(uv-float2(0.5,0.5))));
    return p.color*half4(material.diffuse)*half4(1,1,1,a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentPointTextureFunc(            Point3dOut p [[stage_in]],
                                                    float2 uv  [[point_coord]],
                                                    texture2d<half> t [[texture(0)]],
                                                    constant Material &material [[buffer(0)]],
                                                    sampler s [[sampler(0)]]) {
    return t.sample(s,uv)*p.color*half4(material.diffuse);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentFunc(                        Vertex3dOut v [[stage_in]],
                                                    constant Material &material [[buffer(0)]]) {
    //return half4(half3(v.normal),1);
    return v.color*half4(material.diffuse);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentTextureFunc(                 Vertex3dOut v [[stage_in]],
                                                    texture2d<half> t [[texture(0)]],
                                                    constant Material &material [[buffer(0)]],
                                                    sampler s [[sampler(0)]]) {
    return t.sample(s,v.uv).rgba * v.color * half4(material.diffuse);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentDirectionalLightFunc(        Vertex3dOut v [[stage_in]],
                                                    constant Material &material [[buffer(0)]],
                                                    constant DirectionalLight &light [[buffer(2)]]) {
    //return half4(half3(v.normal)*0.5+0.5,1);
    float3 normal = normalize(v.normal);
    half4 c = half4();
    c += half4(light.color*light.intensity*material.ambient);
    float diffuseFactor = max(0.0,dot(normal,light.direction));
    if(diffuseFactor>0) {
        c += half4(light.color*light.intensity*material.diffuse*diffuseFactor);
        float3 hv = normalize(v.eye-light.direction);
        float specularFactor = pow(max(0.0,dot(normal,hv)),material.shininess);
        c += half4(material.specular*specularFactor*min(1.0,diffuseFactor*3.0));
    }
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentTextureDirectionalLightFunc( Vertex3dOut v [[stage_in]],
                                                    texture2d<half> t [[texture(0)]],
                                                    constant Material &material [[buffer(0)]],
                                                    constant DirectionalLight &light [[buffer(2)]],
                                                    sampler s [[sampler(0)]]) {
    float3 normal = normalize(v.normal);
    half4 c = half4();
    c += half4(light.color*light.intensity*material.ambient);
    float diffuseFactor = max(0.0,dot(normal,light.direction));
    if(diffuseFactor>0) {
        c += half4(light.color*light.intensity*material.diffuse*diffuseFactor);
        float3 hv = normalize(v.eye-light.direction);
        float specularFactor = pow(max(0.0,dot(normal,hv)),material.shininess);
        c += half4(material.specular*specularFactor*min(1.0,diffuseFactor*3.0));
    }
    return c * t.sample(s,v.uv).rgba * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// https://www.tomdalling.com/blog/modern-opengl/07-more-lighting-ambient-specular-attenuation-gamma/
// http://www.lighthouse3d.com/tutorials/glsl-12-tutorial/point-light-per-pixel/
half4 calcLight(Vertex3dOut v, Material material, PointLight light);
half4 calcLight(Vertex3dOut v, Material material, PointLight light) {
    half4 c=half4();
    float3 normal = normalize(v.normal);
    float3 lightdir = normalize(light.position - v.fragmentPosition);
    float dist = length(light.position - v.fragmentPosition);
    float diffuseFactor = max(0.0,dot(normal,lightdir));
    if(diffuseFactor>0) {
        float att = 1.0 / (light.attenuationConstant+light.attenuationLinear*dist+light.attenuationQuadratic*dist*dist);
        c += att * half4(material.diffuse) * diffuseFactor;
        float3 hv = normalize(v.eye+lightdir);
        float specularFactor = pow(max(0.0,dot(normal,hv)),material.shininess);
        c += att * half4(material.specular*specularFactor*min(1.0,diffuseFactor*3.0)); // normaly no mul by diffuseFactor*2 here
    }
    return c * half4(light.color);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentPointLightFunc(          Vertex3dOut v [[stage_in]],
                                                constant Material &material [[buffer(0)]],
                                                constant PointLight &light [[buffer(2)]]) {
    //return half4(half3(v.normal)*0.5+0.5,1);
    half4 c = half4(material.ambient)+calcLight(v,material,light);
    return c * half4(light.color) * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentTexturePointLightFunc(   Vertex3dOut v [[stage_in]],
                                                texture2d<half> t [[texture(0)]],
                                                constant Material &material [[buffer(0)]],
                                                constant PointLight &light [[buffer(2)]],
                                                sampler s [[sampler(0)]]) {
    half4 c = half4(material.ambient)+calcLight(v,material,light);
    return c * half4(light.color) * v.color * t.sample(s,v.uv).rgba;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentPoint2LightFunc(         Vertex3dOut v [[stage_in]],
                                                constant Material &material [[buffer(0)]],
                                                constant PointLight &light1 [[buffer(2)]],
                                                constant PointLight &light2 [[buffer(3)]]) {
    half4 c = half4(material.ambient);
    c += calcLight(v,material,light1);
    c += calcLight(v,material,light2);
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentTexturePoint2LightFunc(  Vertex3dOut v [[stage_in]],
                                                texture2d<half> t [[texture(0)]],
                                                constant Material &material [[buffer(0)]],
                                                constant PointLight &light1 [[buffer(2)]],
                                                constant PointLight &light2 [[buffer(3)]],
                                                sampler s [[sampler(0)]]) {
    half4 c = half4(material.ambient);
    c += calcLight(v,material,light1);
    c += calcLight(v,material,light2);
    return c * v.color * t.sample(s,v.uv).rgba;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentPoint3LightFunc(         Vertex3dOut v [[stage_in]],
                                                constant Material &material [[buffer(0)]],
                                                constant PointLight &light1 [[buffer(2)]],
                                                constant PointLight &light2 [[buffer(3)]],
                                                constant PointLight &light3 [[buffer(4)]]) {
    half4 c = half4(material.ambient);
    c += calcLight(v,material,light1);
    c += calcLight(v,material,light2);
    c += calcLight(v,material,light3);
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentTexturePoint3LightFunc(  Vertex3dOut v [[stage_in]],
                                                texture2d<half> t [[texture(0)]],
                                                constant Material &material [[buffer(0)]],
                                                constant PointLight &light1 [[buffer(2)]],
                                                constant PointLight &light2 [[buffer(3)]],
                                                constant PointLight &light3 [[buffer(4)]],
                                                sampler s [[sampler(0)]]) {
    half4 c = half4(material.ambient);
    c += calcLight(v,material,light1);
    c += calcLight(v,material,light2);
    c += calcLight(v,material,light3);
    return c * v.color * t.sample(s,v.uv).rgba;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentPoint4LightFunc(         Vertex3dOut v [[stage_in]],
                                                constant Material &material [[buffer(0)]],
                                                constant PointLight &light1 [[buffer(2)]],
                                                constant PointLight &light2 [[buffer(3)]],
                                                constant PointLight &light3 [[buffer(4)]],
                                                constant PointLight &light4 [[buffer(5)]]) {
    //return half4(half3(v.normal)*0.5+0.5,1);
    half4 c = half4(material.ambient);
    c += calcLight(v,material,light1);
    c += calcLight(v,material,light2);
    c += calcLight(v,material,light3);
    c += calcLight(v,material,light4);
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fragmentTexturePoint4LightFunc(  Vertex3dOut v [[stage_in]],
                                                texture2d<half> t [[texture(0)]],
                                                constant Material &material [[buffer(0)]],
                                                constant PointLight &light1 [[buffer(2)]],
                                                constant PointLight &light2 [[buffer(3)]],
                                                constant PointLight &light3 [[buffer(4)]],
                                                constant PointLight &light4 [[buffer(5)]],
                                                sampler s [[sampler(0)]]) {
    half4 c = half4(material.ambient);
    c += calcLight(v,material,light1);
    c += calcLight(v,material,light2);
    c += calcLight(v,material,light3);
    c += calcLight(v,material,light4);
    return c * v.color * t.sample(s,v.uv).rgba;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

