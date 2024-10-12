//
//  Kaleidoscope.metal
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

constant float PI = 3.14159265358979323846;

// Vertex shader: transforms vertices and passes texture coordinates to the fragment shader
vertex VertexOut kaleidoscopeVertexShader(VertexIn in [[stage_in]]) {
    VertexOut out;
    
    // Pass through the position (already in clip space for a full-screen quad)
    out.postion = in.position;
    
    // Pass the texture coordinates to the fragment shader
    out.texCoords = in.texCoords;
    
    return out;
}

float2 rotate(float2 coord, float angle) {
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    return float2(
                  coord.x * cosAngle - coord.y * sinAngle,
                  coord.x * sinAngle + coord.y * cosAngle
                  );
}


fragment float4 kaleidoscopeFragment(VertexIn in [[stage_in]],
                                     texture2d<float> texture [[texture(0)]],
                                     sampler textureSampler [[sampler(0)]],
                                     constant float2 &center [[buffer(0)]],
                                     constant float &angle [[buffer(1)]],
                                     constant int &count [[buffer(2)]],
                                     constant float &radius [[buffer(3)]]) {
    float2 uv = in.texCoords;
    
    
    // Calculate delta and distance from center
    float2 delta = uv - center;
    float distanceFromCenter = length(delta);
    
    // If the distance is greater than the radius, return the original texture color
    if (distanceFromCenter > radius) {
        return texture.sample(textureSampler, uv);
    }
    
    // Calculate angle step per slice
    float sliceAngle = 2.0 * PI / float(count);
    
    // Calculate the angle from the center to the current point
    float theta = atan2(delta.y, delta.x);
    
    // Normalize the angle into one slice
    theta = fmod(theta, sliceAngle);
    
    // If the angle is negative, normalize it to the positive range
    if (theta < 0.0) {
        theta += sliceAngle;
    }
    
    // Apply user-specified rotation angle
    theta += angle;
    
    // Reflect the angle to create the mirroring effect
    if (theta > sliceAngle / 2.0) {
        theta = sliceAngle - theta;
    }
    
    // Rotate the delta based on the calculated angle
    float2 rotatedDelta = rotate(delta, theta);
    
    // Add the rotated delta back to the center
    float2 rotatedUV = rotatedDelta + center;
    
    // Sample the texture at the modified coordinates
    return texture.sample(textureSampler, rotatedUV);
}


fragment float4 triangleKaleidoscopeFragment(VertexOut in [[stage_in]],
                                             texture2d<float> texture [[texture(0)]],
                                             sampler textureSampler [[sampler(0)]],
                                             constant float2 &center [[buffer(0)]],
                                             constant float &angle [[buffer(1)]],
                                             constant float &size [[buffer(2)]],
                                             constant float &decay [[buffer(3)]],
                                             constant float &radius [[buffer(4)]]) {
    float2 uv = in.texCoords;
    
    // Calculate delta and distance from center
    float2 delta = uv - center;
    float distanceFromCenter = length(delta);
    
    // If the distance is greater than the radius, keep the original image
    if (distanceFromCenter < radius) {
        return texture.sample(textureSampler, uv);
    }
    
    // Calculate the effect's decay based on the distance and decay percentage
    float decayFactor = max(1.0 - (distanceFromCenter / decay), 0.0);
    
    // Calculate the angle from the center to the current point
    float theta = atan2(delta.y, delta.x);
    
    // Normalize the angle into the triangle's section
    float sliceAngle = 2.0 * PI / 3.0; // Triangles (360 degrees / 3 slices)
    theta = fmod(theta, sliceAngle);
    
    if (theta < 0.0) {
        theta += sliceAngle;
    }
    
    // Rotate the angle by the user-defined rotation
    theta += angle;
    
    // Reflect the angle to create the mirroring effect
    if (theta > sliceAngle / 2.0) {
        theta = sliceAngle - theta;
    }
    
    // Apply the size parameter to determine how large the triangles are
    float2 rotatedDelta = rotate(delta, theta) / size;
    
    // Add the rotated delta back to the center
    float2 rotatedUV = rotatedDelta + center;
    
    // Sample the texture at the modified coordinates
    float4 color = texture.sample(textureSampler, rotatedUV);
    
    // Apply decay to the color (fade out the effect based on distance)
    return float4(color.rgb * decayFactor, color.a);
}
