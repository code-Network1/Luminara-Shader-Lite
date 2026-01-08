/*
 * COLORED PARTICLES SYSTEM
 * Copyright (c) 2025 EminGT
 */

// Colored particles renderer
vec3 GetColoredParticles(vec3 nPlayerPos, vec3 translucentMult, float lViewPos, float lViewPos1, float dither) 
{
    vec3 particleAccumulation = vec3(0.0);
    const float samplingStepSize = 8.0;
    float maxSamplingDistance = min(effectiveACLdistance * 0.5, far);
    int totalSamples = int(maxSamplingDistance / samplingStepSize + 0.001);
    
    vec3 rayStepVector = nPlayerPos * samplingStepSize;
    vec3 currentRayPosition = rayStepVector * dither;
    
    for (int i = 0; i < totalSamples; i++) {
        float currentDistance = length(currentRayPosition);
        
        if (currentDistance > lViewPos1) break;
        if (any(greaterThan(abs(currentRayPosition * 2.0), vec3(voxelVolumeSize)))) break;
        
        vec3 voxelCoordinates = SceneToVoxel(currentRayPosition);
        voxelCoordinates = clamp01(voxelCoordinates / vec3(voxelVolumeSize));
        
        vec4 volumetricLightData = GetLightVolume(voxelCoordinates);
        vec3 lightContribution = volumetricLightData.rgb;
        
        float attenuationDistance = length(
            vec3(
                currentRayPosition.x,
                #if COLORED_LIGHTING_INTERNAL <= 512
                    currentRayPosition.y * 2.0,
                #elif COLORED_LIGHTING_INTERNAL == 768
                    currentRayPosition.y * 3.0,
                #elif COLORED_LIGHTING_INTERNAL == 1024
                    currentRayPosition.y * 4.0,
                #endif
                currentRayPosition.z
            )
        );
        
        lightContribution *= max0(1.0 - attenuationDistance / maxSamplingDistance);
        
        // Apply distance-based particle intensity scaling
        lightContribution *= pow2(min1(currentDistance * 0.03125));
        
        // Apply transparency effects for occluded particles
        if (currentDistance > lViewPos) {
            lightContribution *= translucentMult;
        }
        
        // Accumulate particle contribution
        particleAccumulation += lightContribution;
        
        // Advance ray position for next sample
        currentRayPosition += rayStepVector;
    }
    
    // Apply environment-specific particle modifications
    #ifdef NETHER
        particleAccumulation *= netherColor * 5.0;
    #endif
    
    // Apply global visibility modifiers
    particleAccumulation *= 1.0 - maxBlindnessDarkness;
    
    // Normalize and apply gamma correction for final output
    return pow(particleAccumulation / totalSamples, vec3(0.25));
}

//═══════════════════════════════════════════════════════════════════════════════════════
//                               LEGACY COMPATIBILITY
//═══════════════════════════════════════════════════════════════════════════════════════

// Maintain backward compatibility with existing shader code
#define GetColoredLightFog GetColoredParticles
