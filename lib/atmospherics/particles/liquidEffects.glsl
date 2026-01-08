/*
 * LIQUID EFFECTS SYSTEM
 * Copyright (c) 2025 EminGT
 */

#ifndef INCLUDE_LIQUID_EFFECTS
#define INCLUDE_LIQUID_EFFECTS

// Liquid effects calculator
float GetLiquidEffects(float lViewPos) 
{
    #if WATER_FOG_MULT != 100
        #define WATER_FOG_MULT_M WATER_FOG_MULT * 0.01;
        lViewPos *= WATER_FOG_MULT_M;
    #endif
    
    float liquidDensity;
    
    #if LIGHTSHAFT_QUALI > 0 && SHADOW_QUALITY > -1
        liquidDensity = lViewPos / 48.0;
        liquidDensity *= liquidDensity;
    #else
        liquidDensity = lViewPos / 32.0;
    #endif
    
    return 1.0 - exp(-liquidDensity);
}

// Legacy compatibility
#define GetWaterFog GetLiquidEffects

#endif // INCLUDE_LIQUID_EFFECTS
