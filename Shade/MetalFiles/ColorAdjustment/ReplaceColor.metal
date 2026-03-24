//
//  ReplaceColor.metal
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut colorReplaceVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = in.position;
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 colorReplaceFragmentShader(VertexOut in [[stage_in]],
                                           texture2d<float, access::sample> inTexture [[texture(0)]],
                                            sampler textureSampler [[sampler(0)]],
                                            constant float4 &targetColor [[buffer(1)]],
                                            constant float4 &replacementColor [[buffer(2)]]) {
    
    float4 color = inTexture.sample(textureSampler, in.texCoord);
    
    // Check if the color matches the target color
    if (length(color.rgb - targetColor.rgb) < 0.1) { // Allow a tolerance for matching
        return replacementColor;
    }
    return color;
}
