//
//  ColorMonochrome.metal
//  Shade
//
//  Created by Ahmed Ragab on 06/10/2024.
//

#include <metal_stdlib>
using namespace metal;
struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut monochromeVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = in.position;
    out.texCoord = in.texCoord;
    return out;
}

// Define a sampler with linear filtering
// The sampler is defined as a global variable
sampler textureSampler(mag_filter::linear, min_filter::linear);

fragment float4 monochromeFragmentShader(
    VertexOut in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    constant float4 &color [[ buffer(0) ]],
    constant float &intensity [[ buffer(1) ]]) {
    // Sample the pixel color from the input texture using the defined sampler
    float4 pixelColor = texture.sample(textureSampler, in.texCoord);
    
    // Convert to grayscale using luminance
    float grayValue = dot(pixelColor.rgb, float3(0.299, 0.587, 0.114));
    
    // Create a monochrome color by blending grayscale with the specified color
    float4 monochromeColor = mix(float4(grayValue, grayValue, grayValue, pixelColor.a), color, intensity);
    
    // Return the final color
    return monochromeColor;
}
