/*
 * DEPTH FACTOR CALCULATION
 * Copyright (c) 2025 EminGT
 */

#ifndef INCLUDE_DEPTH_FACTOR
#define INCLUDE_DEPTH_FACTOR

// Depth calculator
float GetDepthFactor() 
{
    float normalizedDepth = 1.0 - cameraPosition.y / oceanAltitude;
    float brightnessModulation = 1.0 - eyeBrightnessM;
    return clamp(normalizedDepth, 0.0, brightnessModulation);
}

// Legacy compatibility
#define GetCaveFactor GetDepthFactor

#endif // INCLUDE_DEPTH_FACTOR
