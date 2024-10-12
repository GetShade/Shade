//
//  warpingLoupe.metal
//  Shade
//
//  Created by Ahmed Ragab on 12/10/2024.
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
vertex VertexOut warpingLoupeVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}



fragment float4 warpingLoupe(VertexOut in [[stage_in]],
                             texture2d<float> inputTexture [[texture(0)]],
                             constant float2 &size [[buffer(0)]],
                             constant float2 &touch [[buffer(1)]],
                             constant float &maxDistance [[buffer(2)]],
                             constant float &zoomFactor [[buffer(3)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    
    // UV space coordinates (0 to 1 range)
    float2 uv = in.texCoords;
    
    // Convert the touch point to UV space (normalized coordinates)
    float2 center = touch / size;
    
    // Calculate the distance of this pixel from the touch point
    float2 delta = uv - center;
    
    // Adjust for aspect ratio to keep the zoom effect circular
    float aspectRatio = size.x / size.y;
    delta.y *= aspectRatio;
    
    // Compute squared distance from the touch point
    float distance = dot(delta, delta);
    
    // Initialize total zoom to 1.0 (no zoom)
    float totalZoom = 1.0;
    
    // Apply zoom if within the defined radius
    if (distance < maxDistance * maxDistance) {
        // Apply zoom factor inside the loupe area
        totalZoom = mix(1.0, 1.0 / zoomFactor, smoothstep(0.0, maxDistance, sqrt(distance)));
    }
    
    // Calculate the new texture coordinate, applying the zoom
    float2 newUV = delta * totalZoom + center;
    
    // Sample the texture using the modified coordinates
    return inputTexture.sample(textureSampler, distance < maxDistance * maxDistance ? newUV : uv);
}

