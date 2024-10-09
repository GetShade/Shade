//
//  ChannelMixer.metal
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

#include <metal_stdlib>
using namespace metal;
struct VertexOut {
    float4 postion [[position]];
    float2 textureCoordinate;
};

struct VertexIn {
    float4 position [[attribute(0)]];
    float2 textureCoordinate [[attribute(1)]];
};

// Vertex shader: transforms vertices and passes texture coordinates to the fragment shader
vertex VertexOut channelMixerVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.textureCoordinate = in.textureCoordinate;
    
    return out;
}


fragment float4 channelMixerFragment(VertexOut out [[stage_in]],
                                     texture2d<float> inTexture [[texture(0)]],
                                     constant float3 &redMix [[buffer(0)]],
                                     constant float3 &greenMix [[buffer(1)]],
                                     constant float3 &blueMix [[buffer(2)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = inTexture.sample(textureSampler,out.textureCoordinate);
    //Mix coloer channels
    float newRed = dot(float3(color.r,color.g,color.b), redMix);
    float newGreen = dot(float3(color.r,color.g,color.b), greenMix);
    float newBlue = dot(float3(color.r,color.g,color.b), blueMix);
    return float4(newRed,newGreen,newBlue,color.a);
}
