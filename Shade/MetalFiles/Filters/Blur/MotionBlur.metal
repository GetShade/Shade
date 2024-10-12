//
//  MotionBlur.metal
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
vertex VertexOut motionBlurVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 motionBlurFragment(VertexOut in [[stage_in]],
                                   texture2d<float> inTexture [[texture(0)]],
                                   sampler s [[sampler(0)]],
                                   constant float &blurRadius [[buffer(0)]],
                                   constant float &blurAngle [[buffer(1)]]) {
    float4 color = float4(0.0);
    float2 texCoords = in.texCoords;
    
    // Convert the blur angle to radians
    float radians = blurAngle * (M_PI_F / 180.0);
    
    // Calculate the direction of the blur (x and y offset)
    float2 direction = float2(cos(radians), sin(radians));
    
    // Determine how many samples to take based on the blur radius
    int radius = int(blurRadius);
    float sampleCount = float(2 * radius + 1);
    
    // Accumulate samples along the motion blur direction
    for (int i = -radius; i <= radius; i++) {
        float2 offset = float2(i) * direction / float2(inTexture.get_width(), inTexture.get_height());
        color += inTexture.sample(s, texCoords + offset);
    }
    
    // Average the color values to create the blur effect
    color /= sampleCount;
    
    return color;
}


