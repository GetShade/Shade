//
//  Brickwork.metal
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
vertex VertexOut brickworkVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 brickworkFragment(
                                  VertexOut in [[stage_in]],
                                  texture2d<float> texture [[texture(0)]],
                                 constant float2 &center [[buffer(0)]],    // Center point for the effect
                                 constant float  &radius [[buffer(1)]],     // Radius of the effect
                                 constant float  &angle [[buffer(2)]],       // Angle for brickwork
                                 constant float  &width [[buffer(3)]],       // Width of the bricks
                                  sampler textureSampler [[sampler(0)]])
{
    // Calculate the distance from the current fragment to the center point
    float2 coords = in.texCoords * float2(texture.get_width(), texture.get_height()); // Convert UV to pixel coordinates
    float dist = distance(coords, center);
    
    // If the distance is greater than the radius, keep the original color
    if (dist > radius) {
        return texture.sample(textureSampler, in.texCoords);
    }
    
    // Brickwork pattern logic
    float pattern = (sin(coords.y * (2.0 * 3.14159 / width) + angle) + 1.0) * 0.5; // Adjust brick height
    pattern = floor(pattern * 2.0); // Make it a binary pattern
    
    // Sample the original texture color
    float4 color = texture.sample(textureSampler, in.texCoords);
    if (pattern < 1.0) {
        color.rgb *= 0.5; // Darken the brick
    }
    
    return color;
}
