//
//  BokehBlur.metal
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
vertex VertexOut bokehBlurVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 bokehBlurFragment(VertexOut in [[ stage_in ]],
                                   texture2d<float> inTexture [[ texture(0) ]],
                                   constant float &radius [[ buffer(0) ]],
                                   constant float &ringSize [[ buffer(1) ]],
                                   constant float &ringAmount [[ buffer(2) ]]) {
    constexpr int sampleCount = 20; // Number of samples for bokeh effect
    float2 texCoord = in.texCoords;
    const float PI = 3.14159265358979323846;
    
    // Initialize the color accumulation
    float4 color = float4(0.0);
    float totalWeight = 0.0;

    // Sample in a circular pattern around the original pixel
    for (int i = 0; i < sampleCount; i++) {
        // Random angle for sample point
        float angle = (float(i) / float(sampleCount)) * 2.0 * PI;
        float r = radius * (1.0 + (sin(angle * ringAmount) * ringSize));
        float2 offset = float2(cos(angle), sin(angle)) * r;
        float2 sampleCoord = texCoord + offset;

        // Ensure the sample is within bounds
        sampleCoord = clamp(sampleCoord, float2(0.0), float2(1.0));
        
        // Accumulate color
        color += inTexture.sample(sampler(mag_filter::linear, min_filter::linear), sampleCoord);
        totalWeight += 1.0;
    }

    // Average the accumulated color
    return color / totalWeight;
}
