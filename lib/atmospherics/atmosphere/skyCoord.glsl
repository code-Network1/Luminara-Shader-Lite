/*
 * SKY COORDINATE SYSTEM MODULE
 * Copyright (c) 2025 EminGT Development
 * All rights reserved.
 */

#ifndef INCLUDE_SKY_COORDINATE_SYSTEM
#define INCLUDE_SKY_COORDINATE_SYSTEM

// Controls the horizontal compression factor for atmospheric layers
const float atmosphericNarrowness = 0.04;

// Calculates rounded atmospheric coordinates with smoothing
// @credit: Original algorithm by SixthSurge
vec2 GetRoundedAtmosphericCoord(vec2 pos, float smoothness) 
{
    vec2 coord = pos.xy + 0.5;
    vec2 signCoord = sign(coord);
    coord = abs(coord) + 1.0;
    
    vec2 integerPart, fractionalPart = modf(coord, integerPart);
    fractionalPart = smoothstep(0.5 - smoothness, 0.5 + smoothness, fractionalPart);
    coord = integerPart + fractionalPart;
    
    return (coord - 0.5) * signCoord / 256.0;
}

// Modifies trace position for atmospheric layer sampling
vec3 ModifyAtmosphericTracePosition(vec3 tracePos, int altitudeLevel) 
{
    float windOffset;
    
    #if CLOUD_SPEED_MULT == 100
        windOffset = syncedTime;
    #else
        #define CLOUD_SPEED_MULT_M CLOUD_SPEED_MULT * 0.01
        windOffset = frameTimeCounter * CLOUD_SPEED_MULT_M;
    #endif
    
    tracePos.x += windOffset;
    tracePos.z += altitudeLevel * 64.0;
    tracePos.xz *= atmosphericNarrowness;
    
    return tracePos.xyz;
}

// Legacy compatibility
#define GetRoundedCloudCoord GetRoundedAtmosphericCoord
#define ModifyTracePos ModifyAtmosphericTracePosition

#endif
