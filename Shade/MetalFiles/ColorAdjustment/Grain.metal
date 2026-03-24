//
//  Grain.metal
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn {
    float4 postion [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 postion [[position]];
    float2 texCoord;
};


vertex VertexOut vertexOut(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.postion = in.postion;
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 GrainFragmentShader(VertexOut in [[stage_in]],
                              texture2d<float> grainTexture [[texture(0)]],
                              constant float &grainIntensity [[buffer(1)]]) {
    float4 grainColor = grainTexture.sample(sampler(mag_filter::linear, min_filter::linear), in.texCoord);
    return float4(grainColor.rgb * grainIntensity, 1.0);
}
