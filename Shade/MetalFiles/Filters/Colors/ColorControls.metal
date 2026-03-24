//
//  ColorControls.metal
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
vertex VertexOut colorControlsVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}


fragment float4 colorControlsFragment(
                                      VertexOut in [[stage_in]],
                                      texture2d<float> inTexture [[ texture(0) ]],
                                      sampler inSampler [[ sampler(0) ]],
                                      constant float3 &colorAdjustments [[ buffer(0) ]]) // {saturation, contrast, brightness}
{
    // Sample the original color from the texture
    float4 color = inTexture.sample(inSampler, in.texCoords);
    
    // Extract color components
    float3 rgb = color.rgb;
    
    // Adjust Brightness (0 to 3% range)
    rgb += (colorAdjustments.z - 1.0) * 2.0; // Scale brightness (1.0 = 0% adjustment)
    
    // Convert to grayscale to compute saturation adjustment
    float gray = dot(rgb, float3(0.299, 0.587, 0.114));
    
    // Adjust Saturation (0 to 3)
    rgb = mix(float3(gray), rgb, colorAdjustments.x); // Saturation adjustment (0-3)
    
    // Adjust Contrast (0 to 3)
    rgb = ((rgb - 0.5) * (colorAdjustments.y * 2.0)) + 0.5; // Scale contrast (1.0 = 0% adjustment)
    
    // Clamp the color values to [0, 1] range
    rgb = clamp(rgb, 0.0, 1.0);
    
    return float4(rgb, color.a); // Return the adjusted color
}
