//
//  VignetteShader.metal
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

#include <metal_stdlib>
using namespace metal;

// Vertex structure
struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

// Output structure for the vertex shader
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Vertex shader: Pass through vertex positions and texture coordinates
vertex VertexOut vertex_passthrough(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = in.position;
    out.texCoord = in.texCoord;
    return out;
}

// Fragment shader: Apply the vignette effect
// Fragment shader: Apply the vignette effect
fragment float4 vignetteShader(VertexOut in [[stage_in]],
                                texture2d<float, access::sample> inTexture [[texture(0)]],
                                constant float &radius [[buffer(0)]],
                                constant float &softness [[buffer(1)]]) {
    
    // Get the color of the current pixel
    float4 color = inTexture.sample(sampler(filter::linear), in.texCoord);
    
    // Calculate the distance from the center of the image
    float dist = distance(in.texCoord, float2(0.5, 0.5));
    
    // Calculate the vignette factor
    float vignette = smoothstep(radius + softness, radius, dist);
    
    // Apply the vignette effect
    color.rgb *= vignette;
    
    return color; // Return the modified color
}
