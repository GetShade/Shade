//
//  BoxBlur.metal
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
vertex VertexOut boxBlurVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}



fragment float4 boxBlurFragment(VertexOut in [[stage_in]],
                                texture2d<float> inTexture [[texture(0)]],
                                sampler s [[sampler(0)]],
                                constant float &blurRadius [[buffer(0)]]) {
    
    float4 color = float4(0.0);
    float2 texCoords = in.texCoords;
    
    int radius = int(blurRadius);
    float sampleCount = float((2 * radius + 1) * (2 * radius + 1));
    
    // Iterate through neighboring pixels in the box defined by blur radius
    for (int x = -radius; x <= radius; x++) {
        for (int y = -radius; y <= radius; y++) {
            float2 offset = float2(x, y) / float2(inTexture.get_width(), inTexture.get_height());
            color += inTexture.sample(s, texCoords + offset);
        }
    }
    
    // Average the color values
    color /= sampleCount;
    
    return color;
}


