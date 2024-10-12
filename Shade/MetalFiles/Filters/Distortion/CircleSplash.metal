//
//  CircleSplash.metal
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
vertex VertexOut splashVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 splashEffectFragment(VertexOut in [[stage_in]],
                                     texture2d<float> texture [[texture(0)]],
                                     sampler textureSampler [[sampler(0)]],
                                     constant float2 &splashCenter [[buffer(0)]],
                                     constant float &radius [[buffer(1)]],
                                     constant float &intensity [[buffer(2)]]
                                     ) {

    // Convert fragment position to UV coordinates (0 to 1 range)
    float2 uv = in.texCoords;

    // Calculate the distance from the splash center
    float2 delta = uv - splashCenter;
    float distance = length(delta);

    // If the pixel is outside the splash area, apply the effect
    if (distance > radius) {
        // Calculate splash distortion based on distance
        float splashDistortion = (distance - radius) * intensity;
        // Create a radial effect by displacing UV coordinates
        uv += normalize(delta) * splashDistortion;
    }

    // Sample the texture using modified UV coordinates
    return texture.sample(textureSampler, uv);
}


