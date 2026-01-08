/*
 * MAIN ATMOSPHERIC RENDERING SYSTEM
 * Copyright (c) 2025 EminGT Development
 * All rights reserved.
 */

#include "/lib/color_schemes/core_color_system.glsl"

#ifdef MOON_PHASE_INF_ATMOSPHERE
    #include "/lib/color_schemes/color_effects_system.glsl"
#endif

#include "/lib/atmospherics/atmosphericVolumetricSystem.glsl"

// Generates interleaved gradient noise for atmospheric dithering
float GenerateAtmosphericNoise() 
{
    float noiseBase = 52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y);
    
    #ifdef TAA
        return fract(noiseBase + goldenRatio * mod(float(frameCounter), 3600.0));
    #else
        return fract(noiseBase);
    #endif
}

#if SHADOW_QUALITY > -1

// Transforms atmospheric position to shadow map coordinates
vec3 TransformToShadowSpace(vec3 tracePos, vec3 cameraPos) 
{
    vec3 worldPosition = PlayerToShadow(tracePos - cameraPos);
    float horizontalDistance = sqrt(worldPosition.x * worldPosition.x + worldPosition.y * worldPosition.y);
    float distortionFactor = 1.0 - shadowMapBias + horizontalDistance * shadowMapBias;
    
    vec3 shadowPosition = vec3(
        vec2(worldPosition.xy / distortionFactor), 
        worldPosition.z * 0.2
    );
    
    return shadowPosition * 0.5 + 0.5;
}

// Performs shadow testing for atmospheric elements
bool TestAtmosphericShadow(vec3 tracePos, vec3 cameraPos, int altitudeLevel, 
                          float lowerBound, float upperBound) 
{
    const float shadowOffset = 0.5;
    vec3 shadowCoordinates = TransformToShadowSpace(tracePos, cameraPos);
    
    if (length(shadowCoordinates.xy * 2.0 - 1.0) < 1.0) {
        float shadowSample = shadow2D(shadowtex0, shadowCoordinates).z;
        if (shadowSample == 0.0) return true;
    }
    
    return false;
}

#endif

#ifdef CLOUDS_REIMAGINED
    #include "/lib/atmospherics/atmosphericVolumetricSystem.glsl"
#endif

#ifdef CLOUDS_UNBOUND
    #include "/lib/atmospherics/atmosphere/weatherSystem.glsl"
#endif

// Main atmospheric rendering pipeline
vec4 RenderAtmosphericEffects(inout float atmosphericDepth, float skyFade, vec3 cameraPos, 
                             vec3 playerPos, float viewDistance, float sunDotProduct, 
                             float upDotProduct, float ditherNoise, vec3 auroraContribution, 
                             vec3 nebulaContribution) 
{
    vec4 atmosphericResult = vec4(0.0);
    vec3 normalizedPlayerPos = normalize(playerPos);
    
    float effectiveViewDistance = viewDistance < renderDistance * 1.5 ? viewDistance - 1.0 : 1000000000.0;
    float skyFadeMultiplier = pow2(skyFade * 3.333333 - 2.333333);
    
    float thresholdMixFactor = pow2(clamp01(upDotProduct * 5.0));
    float viewThreshold = mix(far, 1000.0, thresholdMixFactor * 0.5 + 0.5);
    
    #ifdef DISTANT_HORIZONS
        viewThreshold = max(viewThreshold, renderDistance);
    #endif
    
    #ifdef CLOUDS_REIMAGINED
        cloudAmbientColor *= 1.0 - 0.25 * rainFactor;
    #endif
    
    vec3 atmosphericColorMultiplier = vec3(1.0);
    #if CLOUD_R != 100 || CLOUD_G != 100 || CLOUD_B != 100
        atmosphericColorMultiplier *= vec3(CLOUD_R, CLOUD_G, CLOUD_B) * 0.01;
    #endif
    
    cloudAmbientColor *= atmosphericColorMultiplier;
    cloudLightColor *= atmosphericColorMultiplier;
    
    #if defined CLOUDS_UNBOUND
        #if !defined DOUBLE_REIM_CLOUDS || defined CLOUDS_UNBOUND
            atmosphericResult = GetVolumetricClouds(
                cloudAlt1i, viewThreshold, atmosphericDepth, skyFade, skyFadeMultiplier,
                cameraPos, normalizedPlayerPos, effectiveViewDistance, sunDotProduct, 
                upDotProduct, ditherNoise
            );
        #else
            int primaryAltitude = max(cloudAlt1i, cloudAlt2i);
            int secondaryAltitude = min(cloudAlt1i, cloudAlt2i);
            
            if (abs(cameraPos.y - secondaryAltitude) < abs(cameraPos.y - primaryAltitude)) {
                atmosphericResult = GetVolumetricClouds(
                    secondaryAltitude, viewThreshold, atmosphericDepth, skyFade, skyFadeMultiplier,
                    cameraPos, normalizedPlayerPos, effectiveViewDistance, sunDotProduct, 
                    upDotProduct, ditherNoise
                );
                
                if (atmosphericResult.a == 0.0) {
                    atmosphericResult = GetVolumetricClouds(
                        primaryAltitude, viewThreshold, atmosphericDepth, skyFade, skyFadeMultiplier,
                        cameraPos, normalizedPlayerPos, effectiveViewDistance, sunDotProduct, 
                        upDotProduct, ditherNoise
                    );
                }
            } else {
                atmosphericResult = GetVolumetricClouds(
                    primaryAltitude, viewThreshold, atmosphericDepth, skyFade, skyFadeMultiplier,
                    cameraPos, normalizedPlayerPos, effectiveViewDistance, sunDotProduct, 
                    upDotProduct, ditherNoise
                );
                
                if (atmosphericResult.a == 0.0) {
                    atmosphericResult = GetVolumetricClouds(
                        secondaryAltitude, viewThreshold, atmosphericDepth, skyFade, skyFadeMultiplier,
                        cameraPos, normalizedPlayerPos, effectiveViewDistance, sunDotProduct, 
                        upDotProduct, ditherNoise
                    );
                }
            }
        #endif
    #else
        atmosphericResult = vec4(0.0, 0.0, 0.0, 0.0);
    #endif
    
    #ifdef ATM_COLOR_MULTS
        atmosphericResult.rgb *= sqrtAtmColorMult;
    #endif
    
    #ifdef MOON_PHASE_INF_ATMOSPHERE
        atmosphericResult.rgb *= moonPhaseInfluence;
    #endif
    
    #if AURORA_STYLE > 0
        atmosphericResult.rgb += auroraContribution * 0.1;
    #endif
    
    #ifdef NIGHT_NEBULA
        atmosphericResult.rgb += nebulaContribution * 0.2;
    #endif
    
    return atmosphericResult;
}

// Legacy compatibility
#define InterleavedGradientNoiseForClouds GenerateAtmosphericNoise
#define GetShadowOnCloudPosition TransformToShadowSpace
#define GetShadowOnCloud TestAtmosphericShadow
#define GetClouds RenderAtmosphericEffects
