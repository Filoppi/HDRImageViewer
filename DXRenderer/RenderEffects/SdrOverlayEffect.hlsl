//********************************************************* 
// 
// Copyright (c) Microsoft. All rights reserved. 
// This code is licensed under the MIT License (MIT). 
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF 
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY 
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR 
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT. 
// 
//*********************************************************

// Custom effects using pixel shaders should use HLSL helper functions defined in
// d2d1effecthelpers.hlsli to make use of effect shader linking.
#define D2D_INPUT_COUNT 1           // The pixel shader takes exactly 1 input.

// Note that the custom build step must provide the correct path to find d2d1effecthelpers.hlsli when calling fxc.exe.
#include "d2d1effecthelpers.hlsli"

cbuffer constants : register(b0)
{
    float dpi : packoffset(c0.x); // Ignored - there is no position-dependent behavior in the shader.
};

static const float PQ_constant_M1 = 0.1593017578125f;
static const float PQ_constant_M2 = 78.84375f;
static const float PQ_constant_C1 = 0.8359375f;
static const float PQ_constant_C2 = 18.8515625f;
static const float PQ_constant_C3 = 18.6875f;

// sRGB SDR white is meant to be mapped to 80 nits (not 100, even if some game engine (UE) and consoles (PS5) interpret it as such).
static const float WhiteNits_sRGB = 80.f;
static const float ReferenceWhiteNits_BT2408 = 203.f;
// SMPTE ST 2084 (Perceptual Quantization) is only defined until this amount of nits.
// This is also the max each color channel can have in HDR10.
static const float PQMaxNits = 10000.0f;
// SMPTE ST 2084 is defined as using BT.2020 white point.
static const float PQMaxWhitePoint = PQMaxNits / WhiteNits_sRGB;

// PQ (Perceptual Quantizer - ST.2084) encode/decode used for HDR10 BT.2100
float Linear_to_PQ(float LinearColor)
{
	LinearColor = max(LinearColor, 0.f);
    float colorPow = pow(LinearColor, PQ_constant_M1);
    float numerator = PQ_constant_C1 + PQ_constant_C2 * colorPow;
    float denominator = 1.f + PQ_constant_C3 * colorPow;
    float pq = pow(numerator / denominator, PQ_constant_M2);
	return pq;
}

float Linear_to_PQ(float LinearColor, const float PQMaxValue)
{
	LinearColor /= PQMaxValue;
	return Linear_to_PQ(LinearColor);
}

float PQ_to_Linear(float ST2084Color)
{
	ST2084Color = max(ST2084Color, 0.f);
	float colorPow = pow(ST2084Color, 1.f / PQ_constant_M2);
	float numerator = max(colorPow - PQ_constant_C1, 0.f);
	float denominator = PQ_constant_C2 - (PQ_constant_C3 * colorPow);
	float linearColor = pow(numerator / denominator, 1.f / PQ_constant_M1);
	return linearColor;
}

float PQ_to_Linear(float ST2084Color, const float PQMaxValue)
{
	float linearColor = PQ_to_Linear(ST2084Color);
	linearColor *= PQMaxValue;
	return linearColor;
}

float gamma_linear_to_sRGB(float channel)
{
    if (channel <= 0.0031308f)
    {
        channel = channel * 12.92f;
    }
    else
    {
        channel = 1.055f * pow(channel, 1.f / 2.4f) - 0.055f;
    }
    return channel;
}

float gamma_sRGB_to_linear(float channel)
{
    if (channel <= 0.04045f)
    {
        channel = channel / 12.92f;
    }
    else
    {
        channel = pow((channel + 0.055f) / 1.055f, 2.4f);
    }
    return channel;
}

static const float3x3 BT2020_2_BT709 =
{
    1.66049098968505859375f, -0.58764111995697021484375f, -0.072849862277507781982421875f,
	-0.12455047667026519775390625f, 1.13289988040924072265625f, -0.0083494223654270172119140625f,
	-0.01815076358616352081298828125f, -0.100578896701335906982421875f, 1.11872971057891845703125f
};
static const float3x3 BT709_2_BT2020 =
{
    0.627403914928436279296875f, 0.3292830288410186767578125f, 0.0433130674064159393310546875f,
	0.069097287952899932861328125f, 0.9195404052734375f, 0.011362315155565738677978515625f,
	0.01639143936336040496826171875f, 0.08801330626010894775390625f, 0.895595252513885498046875f
};

float3 BT2020_To_BT709(float3 color)
{
    return mul(BT2020_2_BT709, color);
}
float3 BT709_To_BT2020(float3 color)
{
    return mul(BT709_2_BT2020, color);
}

//TODO: for quicker iteration, you can copy all the custom code to other shaders like MaxLuminanceEffect.hlsl
//and compile it with different settings (to find out which combination of settings is right)
#define INPUT_SRGB_GAMMA 0
#define INPUT_BT_2020 0
#define INPUT_BT_709 1
#define INPUT_PQ 0
#define OUTPUT_SRGB_GAMMA 0

D2D_PS_ENTRY(main)
{
    float4 color = D2DGetInput(0);

#if 0
    color.rgb /= 203.f / 80.f;
    //color.rgb = 300.f / 100.f;
#endif

#if INPUT_PQ
#if !INPUT_SRGB_GAMMA
    color.r = gamma_linear_to_sRGB(color.r);
    color.g = gamma_linear_to_sRGB(color.g);
    color.b = gamma_linear_to_sRGB(color.b);
#endif
    float MaxPQ = true ? PQMaxWhitePoint : 1.f;
    color.r = PQ_to_Linear(color.r, MaxPQ);
    color.g = PQ_to_Linear(color.g, MaxPQ);
    color.b = PQ_to_Linear(color.b, MaxPQ);
#elif INPUT_SRGB_GAMMA
    color.r = gamma_sRGB_to_linear(color.r);
    color.g = gamma_sRGB_to_linear(color.g);
    color.b = gamma_sRGB_to_linear(color.b);
#endif

#if 0
    color.rgb /= 203.f / 80.f; // Some programs might have used ~300nits instead of 203
#endif

#if 0 // Check for HDR pixels
    if (color.r > 1.f || color.g > 1.f || color.b > 1.f)
    {
        color.rgb = 0.f;
        color.g = 12.5f;
    }
#endif

#if INPUT_BT_2020
    color.rgb = BT2020_To_BT709(color.rgb);
#elif INPUT_BT_709
    color.rgb = BT709_To_BT2020(color.rgb);
#endif

#if OUTPUT_SRGB_GAMMA
    color.r = gamma_linear_to_sRGB(color.r);
    color.g = gamma_linear_to_sRGB(color.g);
    color.b = gamma_linear_to_sRGB(color.b);
#endif

#if 0
    color.rgb = saturate(color.rgb);
#endif

    return color;
}