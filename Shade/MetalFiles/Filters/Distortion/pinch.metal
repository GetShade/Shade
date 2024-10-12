//
//  pinch.metal
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
vertex VertexOut pinchEffectVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 pinchEffectFragment(VertexOut in [[stage_in]],
                                    texture2d<float> texture [[texture(0)]],
                                    sampler textureSampler [[sampler(0)]],
                                    constant float2 &pinchCenter [[buffer(0)]],
                                    constant float &radius [[buffer(1)]],
                                    constant float &scaleFactor [[buffer(2)]]) {

    // Convert fragment position to UV coordinates (0 to 1 range)
    float2 uv = in.texCoords;

    // Calculate the distance from the pinch center
    float2 delta = uv - pinchCenter;
    float distance = length(delta);

    // If the pixel is within the pinch radius, apply the scale effect
    if (distance > radius) {
        // Calculate the scaling effect
        float scale = mix(1.0, scaleFactor, 1.0 - (distance / radius));
        uv = pinchCenter + delta * scale; // Scale UV coordinates
    }

    // Sample the texture using modified UV coordinates
    return texture.sample(textureSampler, uv);
}

