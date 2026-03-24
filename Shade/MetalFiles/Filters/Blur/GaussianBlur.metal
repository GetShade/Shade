//
//  GaussianBlur.metal
//  Shade
//
//  Created by Ahmed Ragab on 11/10/2024.
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
vertex VertexOut gaussianBlurVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}



fragment float4 gaussianBlurFragment(VertexOut in [[stage_in]],
                                     texture2d<float> inTexture [[texture(0)]],
                                     sampler s [[sampler(0)]],
                                     constant float &blurRadius [[buffer(0)]]) {
    
    float4 color = float4(0.0);
    
    float2 texCoords = in.texCoords;
    float blurWeights[5] = {0.227027, 0.194594, 0.121621, 0.054054, 0.016216};
    
    // Initial color from the center
    color += inTexture.sample(s, texCoords) * blurWeights[0];
    
    // Apply Gaussian blur horizontally and vertically
    for (int i = 1; i < 5; i++) {
        color += inTexture.sample(s, texCoords + float2(blurRadius * i, 0)) * blurWeights[i];
        color += inTexture.sample(s, texCoords - float2(blurRadius * i, 0)) * blurWeights[i];
        color += inTexture.sample(s, texCoords + float2(0, blurRadius * i)) * blurWeights[i];
        color += inTexture.sample(s, texCoords - float2(0, blurRadius * i)) * blurWeights[i];
    }
    
    return color;
}

