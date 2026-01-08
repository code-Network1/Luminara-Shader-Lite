/*
 * LIGHT BLOOM EFFECTS
 * Copyright (c) 2025 EminGT
 */

#ifdef CAVE_FOG
    #include "/lib/atmospherics/particles/depthFactor.glsl"
#endif

// Bloom intensity constants
const float rainBloomIntensity     = 8.0;
const float nightBloomIntensity    = 3.0;
const float caveBloomIntensity     = 14.0;
const float waterBloomIntensity    = 14.0;

// Dimensional bloom configuration
#ifdef BORDER_FOG
    const float netherBloomIntensity = 14.0;
#else
    const float netherBloomIntensity = 3.0;
#endif

// Bloom calculator
float GetLightBloom(float lViewPos) 
{
    float bloomEffect;
    float bloomMultiplier;
    
    #ifdef OVERWORLD
        float underwaterModifier = 0.02 + 0.04 * float(isEyeInWater == 1);
        bloomEffect = pow2(pow2(1.0 - exp(-lViewPos * underwaterModifier)));
        
        if (isEyeInWater != 1) {
            float weatherBloom = rainFactor2 * rainBloomIntensity;
            float timeBloom = nightBloomIntensity * (1.0 - sunFactor);
            bloomMultiplier = (weatherBloom + timeBloom) * eyeBrightnessM;
            
            // Add underground/cave bloom enhancement
            #ifdef CAVE_FOG
                bloomMultiplier += GetCaveFactor() * caveBloomIntensity;
            #endif
            
        } else {
            // === UNDERWATER CONDITIONS ===
            bloomMultiplier = waterBloomIntensity;
        }
        
    #elif defined NETHER
        // === NETHER DIMENSION BLOOM PROCESSING ===
        
        // Calculate Nether-specific viewing distance with limits
        float netherViewLimit = min(renderDistance, NETHER_VIEW_LIMIT);
        
        // Apply cubic falloff for dramatic Nether atmosphere
        bloomEffect = lViewPos / clamp(netherViewLimit, 96.0, 256.0);
        bloomEffect = bloomEffect * bloomEffect * bloomEffect;  // Cubic falloff
        
        // Apply exponential bloom with enhanced intensity
        bloomEffect = 1.0 - exp(-8.0 * bloomEffect);
        
        // Disable bloom when underwater in Nether (rare but handled)
        bloomEffect *= float(isEyeInWater == 0);
        
        // Apply Nether-specific bloom intensity
        bloomMultiplier = netherBloomIntensity;
        
    #endif
    
    // Apply global bloom strength scaling and intensity normalization
    bloomMultiplier *= BLOOM_STRENGTH * 8.33333;
    
    // Return final bloom factor (1.0 + bloom enhancement)
    return 1.0 + bloomEffect * bloomMultiplier;
}

//═══════════════════════════════════════════════════════════════════════════════════════
//                               LEGACY COMPATIBILITY
//═══════════════════════════════════════════════════════════════════════════════════════

// Maintain backward compatibility with existing bloom systems
#define GetBloomFog GetLightBloom
