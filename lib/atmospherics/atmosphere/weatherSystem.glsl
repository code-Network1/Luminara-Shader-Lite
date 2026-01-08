/*
 * ADVANCED WEATHER SYSTEM
 * Copyright (c) 2025 EminGT
 */

#include "/lib/atmospherics/atmosphericVolumetricSystem.glsl"

// Size multiplier
#if CLOUD_UNBOUND_SIZE_MULT != 100
    #define CLOUD_UNBOUND_SIZE_MULT_M CLOUD_UNBOUND_SIZE_MULT * 0.01
#endif

// Quality-based stretch parameters
#if CLOUD_QUALITY == 1 || !defined DEFERRED1
    const float baseAtmosphericStretch = 11.0;
#elif CLOUD_QUALITY == 2
    const float baseAtmosphericStretch = 16.0;
#elif CLOUD_QUALITY == 3
    const float baseAtmosphericStretch = 20.0;
#endif

#if CLOUD_UNBOUND_SIZE_MULT <= 100
    const float weatherStretch = baseAtmosphericStretch;
#else
    const float weatherStretch = baseAtmosphericStretch / float(CLOUD_UNBOUND_SIZE_MULT_M);
#endif

const float weatherHeight = weatherStretch * 2.0;

// 3D weather noise generator
float Generate3DWeatherNoise(vec3 position) 
{
    position.z = fract(position.z) * 128.0;
    float integerZ = floor(position.z);
    float fractionalZ = fract(position.z);
    
    vec2 offsetA = vec2(23.0, 29.0) * (integerZ) / 128.0;
    vec2 offsetB = vec2(23.0, 29.0) * (integerZ + 1.0) / 128.0;
    
    float noiseA = texture2D(noisetex, position.xy + offsetA).r;
    float noiseB = texture2D(noisetex, position.xy + offsetB).r;
    
    return mix(noiseA, noiseB, fractionalZ);
}

// Weather density calculator
float CalculateWeatherDensity(vec3 tracePos, int altitudeLevel, float horizontalDistance, float verticalOffset) 
{
    vec3 modifiedPos = tracePos.xyz * 0.00016;
    float windFactor = 0.0006;
    float accumulatedNoise = 0.0;
    float currentPersistence = 1.0;
    float totalWeight = 0.0;
    
    #if CLOUD_SPEED_MULT == 100
        #define CLOUD_SPEED_MULT_M CLOUD_SPEED_MULT * 0.01
        windFactor *= syncedTime;
    #else
        #define CLOUD_SPEED_MULT_M CLOUD_SPEED_MULT * 0.01
        windFactor *= frameTimeCounter * CLOUD_SPEED_MULT_M;
    #endif
    
    #if CLOUD_UNBOUND_SIZE_MULT != 100
        modifiedPos *= CLOUD_UNBOUND_SIZE_MULT_M;
        windFactor *= CLOUD_UNBOUND_SIZE_MULT_M;
    #endif
    
    // Quality-based configuration
    int noiseSamples;
    float persistence;
    float noiseMultiplier;
    
    #if CLOUD_QUALITY == 1
        noiseSamples = 2;
        persistence = 0.6;
        noiseMultiplier = 0.95;
        modifiedPos *= 0.5; 
        windFactor *= 0.5;
    #elif CLOUD_QUALITY == 2 || !defined DEFERRED1
        noiseSamples = 4;
        persistence = 0.5;
        noiseMultiplier = 1.07;
    #elif CLOUD_QUALITY == 3
        noiseSamples = 4;
        persistence = 0.5;
        noiseMultiplier = 1.0;
    #endif
    
    #ifndef DEFERRED1
        noiseMultiplier *= 1.2;
    #endif
    
    for (int i = 0; i < noiseSamples; i++) {
        #if CLOUD_QUALITY >= 2
            accumulatedNoise += Generate3DWeatherNoise(modifiedPos + vec3(windFactor, 0.0, 0.0)) * currentPersistence;
        #else
            accumulatedNoise += texture2D(noisetex, modifiedPos.xz + vec2(windFactor, 0.0)).b * currentPersistence;
        #endif
        
        totalWeight += currentPersistence;
        modifiedPos *= 3.0;
        windFactor *= 0.5;
        currentPersistence *= persistence;
    }
    
    accumulatedNoise = pow2(accumulatedNoise / totalWeight);
    
    #ifndef DISTANT_HORIZONS
        #define WEATHER_BASE_DENSITY 0.65
        #define WEATHER_DISTANCE_FACTOR 0.01
        #define WEATHER_HEIGHT_FACTOR 0.1
    #else
        #define WEATHER_BASE_DENSITY 0.9
        #define WEATHER_DISTANCE_FACTOR -0.005
        #define WEATHER_HEIGHT_FACTOR 0.03
    #endif
    
    noiseMultiplier *= WEATHER_BASE_DENSITY
                      + WEATHER_DISTANCE_FACTOR * sqrt(horizontalDistance + 10.0)
                      + WEATHER_HEIGHT_FACTOR * clamp01(-verticalOffset / weatherHeight)
                      + CLOUD_UNBOUND_RAIN_ADD * rainFactor;
    
    accumulatedNoise *= noiseMultiplier * CLOUD_UNBOUND_AMOUNT;
    
    float altitudeThreshold = clamp(abs(altitudeLevel - tracePos.y) / weatherStretch, 0.001, 0.999);
    altitudeThreshold = pow2(pow2(pow2(altitudeThreshold)));
    
    return accumulatedNoise - (altitudeThreshold * 0.2 + 0.25);
}

// Main weather renderer
vec4 GetVolumetricClouds(int altitudeLevel, float distanceThreshold, inout float depthOutput, 
                        float skyFade, float skyMultiplier, vec3 cameraPos, vec3 normalizedPlayerPos, 
                        float viewDistance, float sunDotProduct, float upDotProduct, float ditherNoise) 
{
    vec4 weatherResult = vec4(0.0);
    
    float upperBoundary = altitudeLevel + weatherStretch;
    float lowerBoundary = altitudeLevel - weatherStretch;
    
    float lowerPlaneDistance = (lowerBoundary - cameraPos.y) / normalizedPlayerPos.y;
    float upperPlaneDistance = (upperBoundary - cameraPos.y) / normalizedPlayerPos.y;
    
    float minDistance = max(min(lowerPlaneDistance, upperPlaneDistance), 0.0);
    float maxDistance = max(lowerPlaneDistance, upperPlaneDistance);
    
    if (maxDistance < 0.0) return vec4(0.0);
    
    float traversalDistance = maxDistance - minDistance;
    
    // Quality-based step size
    float stepSize;
    #ifndef DEFERRED1
        stepSize = 32.0;
    #elif CLOUD_QUALITY == 1
        stepSize = 16.0;
    #elif CLOUD_QUALITY == 2
        stepSize = 24.0;
    #elif CLOUD_QUALITY == 3
        stepSize = 16.0;
    #endif
    
    #if CLOUD_UNBOUND_SIZE_MULT > 100
        stepSize = stepSize / sqrt(float(CLOUD_UNBOUND_SIZE_MULT_M));
    #endif
    
    int sampleCount = int(traversalDistance / stepSize + ditherNoise + 1);
    vec3 rayStep = normalizedPlayerPos * stepSize;
    vec3 currentPos = cameraPos + minDistance * normalizedPlayerPos;
    
    currentPos += rayStep * ditherNoise;
    currentPos.y -= rayStep.y;
    
    float firstHitDistance = 0.0;
    float sunAlignment = max0(sunVisibility > 0.5 ? sunDotProduct : -sunDotProduct);
    float rainAdjustedSunAlignment = sunAlignment * invRainFactor;
    float sunScattering = pow2(sunAlignment) * abs(sunVisibility - 0.5) * 2.0;
    float weatherLightingFactor = sunScattering * (2.5 + rainFactor) + 1.5 * rainFactor;
    
    #ifdef FIX_AMD_REFLECTION_CRASH
        sampleCount = min(sampleCount, 30);
    #endif
    
    for (int i = 0; i < sampleCount; i++) {
        currentPos += rayStep;
        
        if (abs(currentPos.y - altitudeLevel) > weatherStretch) break;
        
        vec3 cameraToSample = currentPos - cameraPos;
        float sampleDistance = length(cameraToSample);
        float horizontalDistance = length(cameraToSample.xz);
        
        if (horizontalDistance > distanceThreshold) break;
        
        float distanceMultiplier = 1.0;
        if (sampleDistance > viewDistance) {
            if (skyFade < 0.7) continue;
            else distanceMultiplier = skyMultiplier;
        }
        
        float weatherDensity = CalculateWeatherDensity(currentPos, altitudeLevel, horizontalDistance, cameraToSample.y);
        
        if (weatherDensity > 0.00001) {
            #if defined CLOUD_CLOSED_AREA_CHECK && SHADOW_QUALITY > -1
                float shadowRange = min(shadowDistance, far) * 0.9166667;
                if (shadowRange < sampleDistance) {
                    if (TestAtmosphericShadow(currentPos, cameraPos, altitudeLevel, lowerBoundary, upperBoundary)) {
                        if (eyeBrightness.y != 240) continue;
                    }
                }
            #endif
            
            if (firstHitDistance < 1.0) {
                firstHitDistance = sampleDistance;
                #if CLOUD_QUALITY == 1 && defined DEFERRED1
                    currentPos.y += 4.0 * (texture2D(noisetex, currentPos.xz * 0.001).r - 0.5);
                #endif
            }
            
            float opacityFactor = min1(weatherDensity * 8.0);
            float heightShading = 1.0 - (upperBoundary - currentPos.y) / weatherHeight;
            heightShading *= 1.0 + 0.75 * weatherLightingFactor * (1.0 - opacityFactor);
            
            vec3 weatherColor = cloudAmbientColor * (0.7 + 0.3 * heightShading) + cloudLightColor * heightShading;
            
            vec3 skyColor = GetSky(upDotProduct, sunDotProduct, ditherNoise, true, false);
            #ifdef ATM_COLOR_MULTS
                skyColor *= sqrtAtmColorMult;
            #endif
            
            float distanceRatio = (distanceThreshold - horizontalDistance) / distanceThreshold;
            float weatherDistanceFactor = clamp(distanceRatio, 0.0, 0.8) * 1.25;
            
            #ifndef DISTANT_HORIZONS
                float fogBlendFactor = weatherDistanceFactor;
            #else
                float fogBlendFactor = clamp(distanceRatio, 0.0, 1.0);
            #endif
            
            float skyMultiplier1 = 1.0 - 0.2 * (1.0 - skyFade) * max(sunVisibility2, nightFactor);
            float skyMultiplier2 = 1.0 - 0.33333 * skyFade;
            
            weatherColor = mix(skyColor, weatherColor * skyMultiplier1, fogBlendFactor * skyMultiplier2 * 0.72);
            weatherColor *= pow2(1.0 - maxBlindnessDarkness);
            
            weatherResult.rgb = mix(weatherResult.rgb, weatherColor, 1.0 - min1(weatherResult.a));
            weatherResult.a += opacityFactor * pow(weatherDistanceFactor, 0.5 + 10.0 * pow(abs(rainAdjustedSunAlignment), 90.0)) * distanceMultiplier;
            
            if (weatherResult.a > 0.9) {
                weatherResult.a = 1.0;
                break;
            }
        }
    }
    
    if (weatherResult.a > 0.5) {
        depthOutput = sqrt(firstHitDistance / renderDistance);
    }
    
    return weatherResult;
}
