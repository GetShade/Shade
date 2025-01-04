#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 textureCoordinate [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex VertexOut vertexShader(const device VertexIn* vertex_array [[ buffer(0) ]],
                             unsigned int vid [[ vertex_id ]]) {
    VertexOut out;
    out.position = float4(vertex_array[vid].position, 0.0, 1.0);
    out.textureCoordinate = vertex_array[vid].textureCoordinate;
    return out;
}

fragment float4 blendFragmentShader(VertexOut in [[stage_in]],
                                  texture2d<float> baseTexture [[texture(0)]],
                                  texture2d<float> blendTexture [[texture(1)]],
                                  sampler textureSampler [[sampler(0)]],
                                  constant int& blendMode [[buffer(0)]]) {
    float4 baseColor = baseTexture.sample(textureSampler, in.textureCoordinate);
    float4 blendColor = blendTexture.sample(textureSampler, in.textureCoordinate);

    // Implement blend mode calculations here based on blendMode parameter
    // This is a simplified example
    switch(blendMode) {
        case 0: // Normal
            return mix(baseColor, blendColor, blendColor.a);
        case 1: // Multiply
            return baseColor * blendColor;
        // Add more blend mode implementations as needed
        default:
            return baseColor;
    }
}
