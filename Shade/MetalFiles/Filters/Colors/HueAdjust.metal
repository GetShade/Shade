//
//  HueAdjust.metal
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
vertex VertexOut hueAdjustVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 hueAdjustFragment(
                                  VertexOut in [[stage_in]],
                                  texture2d<float, access::sample> inTexture [[ texture(0) ]],
                                  sampler inSampler [[ sampler(0) ]],
                                  constant float &angle [[ buffer(0) ]] // Angle in degrees
                                  )
{
    // Sample the original color from the texture
    float4 color = inTexture.sample(inSampler, in.texCoords);
    
    
    // Convert RGB to HSL
    float3 rgb = color.rgb;
    float maxVal = max(max(rgb.r, rgb.g), rgb.b);
    float minVal = min(min(rgb.r, rgb.g), rgb.b);
    float delta = maxVal - minVal;
    
    float hue, saturation, lightness;
    
    // Calculate lightness
    lightness = (maxVal + minVal) / 2.0;
    
    // Calculate saturation
    if (delta == 0.0) {
        hue = 0.0; // achromatic
        saturation = 0.0;
    } else {
        saturation = lightness < 0.5 ? delta / (maxVal + minVal) : delta / (2.0 - maxVal - minVal);
        
        // Calculate hue
        if (maxVal == rgb.r) {
            hue = ((rgb.g - rgb.b) / delta);
        } else if (maxVal == rgb.g) {
            hue = 2.0 + (rgb.b - rgb.r) / delta;
        } else {
            hue = 4.0 + (rgb.r - rgb.g) / delta;
        }
        hue = hue * 60.0; // Convert to degrees
        if (hue < 0.0) {
            hue += 360.0; // Adjust hue to be in [0, 360]
        }
    }
    
    // Adjust the hue
    hue += angle; // Add the angle adjustment
    if (hue >= 360.0) {
        hue -= 360.0; // Wrap around
    } else if (hue < 0.0) {
        hue += 360.0; // Wrap around
    }
    
    // Convert HSL back to RGB
    float c = (1.0 - abs(2.0 * lightness - 1.0)) * saturation;
    float x = c * (1.0 - abs(fmod(hue / 60.0, 2.0) - 1.0));
    float m = lightness - c / 2.0;
    
    float3 rgbAdjusted;
    
    if (hue < 60.0) {
        rgbAdjusted = float3(c, x, 0.0);
    } else if (hue < 120.0) {
        rgbAdjusted = float3(x, c, 0.0);
    } else if (hue < 180.0) {
        rgbAdjusted = float3(0.0, c, x);
    } else if (hue < 240.0) {
        rgbAdjusted = float3(0.0, x, c);
    } else if (hue < 300.0) {
        rgbAdjusted = float3(x, 0.0, c);
    } else {
        rgbAdjusted = float3(c, 0.0, x);
    }
    
    rgbAdjusted += m; // Apply lightness shift
    
    // Clamp the color values to [0, 1] range
    rgbAdjusted = clamp(rgbAdjusted, 0.0, 1.0);
    
    return float4(rgbAdjusted, color.a); // Return the adjusted color
}
