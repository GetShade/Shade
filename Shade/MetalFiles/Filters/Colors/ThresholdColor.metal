//
//  ThresholdColor.metal
//  Shade
//
//  Created by Ahmed Ragab on 13/10/2024.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 postion [[position]];
    float2 texCoords;
};

struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};


// Vertex shader: transforms vertices and passes texture coordinates to the fragment shader
vertex VertexOut thresholdColorVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 thresholdColorFragment(
                VertexOut in [[stage_in]],
                texture2d<float, access::sample> inTexture [[ texture(0) ]],
                sampler inSampler [[ sampler(0) ]],
                constant float &threshold [[ buffer(0) ]])
{
    // Sample the original color from the texture
    float4 color = inTexture.sample(inSampler, in.texCoords);

    // Calculate brightness using the luminance formula
    float brightness = dot(color.rgb, float3(0.299, 0.587, 0.114));

    // Apply the threshold
    if (brightness > threshold) {
        return float4(1.0, 1.0, 1.0, color.a); // White
    } else {
        return float4(0.0, 0.0, 0.0, color.a); // Black
    }
}
