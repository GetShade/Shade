//
//  ExposureAdjust.metal
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
vertex VertexOut exposureAdjustVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 exposureAdjustFragment(
                                       VertexOut in [[stage_in]],
                                       texture2d<float, access::sample> inTexture [[ texture(0) ]],
                                       sampler inSampler [[ sampler(0) ]],
                                       constant float &exposureEV [[ buffer(0) ]])
{
    // Sample the original color from the texture
    float4 color = inTexture.sample(inSampler, in.texCoords);
    
    // Convert the EV percentage to a scaling factor
    float scalingFactor = pow(2.0, exposureEV / 100.0); // EV 100% corresponds to doubling the light
    
    // Adjust the color by the scaling factor
    color.rgb *= scalingFactor;
    
    // Clamp the color values to [0, 1] range
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    
    return color; // Return the adjusted color
}
