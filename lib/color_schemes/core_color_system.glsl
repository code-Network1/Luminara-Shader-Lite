/*
 * CORE COLOR SYSTEM
 * Copyright (c) 2025 EminGT
 */

#ifndef INCLUDE_SKY_COLORS
    #define INCLUDE_SKY_COLORS

    #if defined OVERWORLD
        // Sky Color Processing
        vec3 skyColorSqrt = sqrt(skyColor);
        
        // Thunderstorm protection
        float invRainStrength2 = (1.0 - rainStrength) * (1.0 - rainStrength);
        vec3 skyColorM = mix(max(skyColorSqrt, vec3(0.63, 0.67, 0.73)), skyColorSqrt, invRainStrength2);
        vec3 skyColorM2 = mix(max(skyColor, sunFactor * vec3(0.265, 0.295, 0.35)), skyColor, invRainStrength2);

        /**
         * Biome-Specific Weather Modifiers
         * Adjusts sky colors based on local environmental conditions
         */
        #ifdef SPECIAL_BIOME_WEATHER
            vec3 nmscSnowM = inSnowy * vec3(-0.3, 0.05, 0.2);    // Snow biome: Cool blue shift
            vec3 nmscDryM = inDry * vec3(-0.3);                  // Desert biome: Warm desaturation
            vec3 ndscSnowM = inSnowy * vec3(-0.25, -0.01, 0.25); // Snow biome lower sky
            vec3 ndscDryM = inDry * vec3(-0.05, -0.09, -0.1);    // Desert biome lower sky
        #else
            vec3 nmscSnowM = vec3(0.0), nmscDryM = vec3(0.0), ndscSnowM = vec3(0.0), ndscDryM = vec3(0.0);
        #endif
        
        /**
         * Advanced Rain Style Color Modifications
         * Style 2: Enhanced precipitation color effects
         */
        #if RAIN_STYLE == 2
            vec3 nmscRainMP = vec3(-0.15, 0.025, 0.1);
            vec3 ndscRainMP = vec3(-0.125, -0.005, 0.125);
            #ifdef SPECIAL_BIOME_WEATHER
                vec3 nmscRainM = inRainy * nmscRainMP;
                vec3 ndscRainM = inRainy * ndscRainMP;
            #else
                vec3 nmscRainM = nmscRainMP;
                vec3 ndscRainM = ndscRainMP;
            #endif
        #else
            vec3 nmscRainM = vec3(0.0), ndscRainM = vec3(0.0);
        #endif
        
        // Weather color modifiers
        vec3 nmscWeatherM = vec3(-0.1, -0.4, -0.6) + vec3(0.0, 0.06, 0.12) * noonFactor;
        vec3 ndscWeatherM = vec3(-0.15, -0.3, -0.42) + vec3(0.0, 0.02, 0.08) * noonFactor;

        // Noon sky colors
        vec3 noonUpSkyColor = pow(skyColorM, vec3(2.9));
        vec3 noonMiddleSkyColor = skyColorM * (vec3(1.15) + rainFactor * (nmscWeatherM + nmscRainM + nmscSnowM + nmscDryM))
                                + noonUpSkyColor * 0.6;
        vec3 noonDownSkyColor = skyColorM * (vec3(0.9) + rainFactor * (ndscWeatherM + ndscRainM + ndscSnowM + ndscDryM))
                              + noonUpSkyColor * 0.25;

        // Sunset/sunrise colors
        vec3 sunsetUpSkyColor = skyColorM2 * (vec3(0.8, 0.58, 0.58) + vec3(0.1, 0.2, 0.35) * rainFactor2);
        vec3 sunsetMiddleSkyColor = skyColorM2 * (vec3(1.8, 1.3, 1.2) + vec3(0.15, 0.25, -0.05) * rainFactor2);
        vec3 sunsetDownSkyColorP = vec3(1.45, 0.86, 0.5) - vec3(0.8, 0.3, 0.0) * rainFactor;
        vec3 sunsetDownSkyColor = sunsetDownSkyColorP * 0.5 + 0.25 * sunsetMiddleSkyColor;

        // Day sky interpolation
        vec3 dayUpSkyColor = mix(noonUpSkyColor, sunsetUpSkyColor, invNoonFactor2);
        vec3 dayMiddleSkyColor = mix(noonMiddleSkyColor, sunsetMiddleSkyColor, invNoonFactor2);
        vec3 dayDownSkyColor = mix(noonDownSkyColor, sunsetDownSkyColor, invNoonFactor2);

        // Night sky colors
        vec3 nightColFactor = vec3(0.07, 0.14, 0.24) * (1.0 - 0.5 * rainFactor) + skyColor;
        vec3 nightUpSkyColor = pow(nightColFactor, vec3(0.90)) * 0.4;
        vec3 nightMiddleSkyColor = sqrt(nightUpSkyColor) * 0.68;
        vec3 nightDownSkyColor = nightMiddleSkyColor * vec3(0.82, 0.82, 0.88);
    #endif

#endif //INCLUDE_SKY_COLORS

// Lighting & Ambient Color System
#ifndef INCLUDE_LIGHT_AND_AMBIENT_COLORS
    #define INCLUDE_LIGHT_AND_AMBIENT_COLORS

    #if defined OVERWORLD
        
        // Noon clear weather lighting
        #ifndef COMPOSITE
            vec3 noonClearLightColor = vec3(0.7, 0.55, 0.4) * 1.9;
        #else
            vec3 noonClearLightColor = vec3(0.4, 0.7, 1.4);
        #endif
        vec3 noonClearAmbientColor = pow(skyColor, vec3(0.65)) * 0.85;
        
        // Sunset clear weather lighting
        #ifndef COMPOSITE
            vec3 sunsetClearLightColor = pow(vec3(0.64, 0.45, 0.3), vec3(1.5 + invNoonFactor)) * 5.0;
        #else
            vec3 sunsetClearLightColor = pow(vec3(0.62, 0.39, 0.24), vec3(1.5 + invNoonFactor)) * 6.8;
        #endif
        vec3 sunsetClearAmbientColor = noonClearAmbientColor * vec3(1.21, 0.92, 0.76) * 0.95;

        // Night clear weather lighting
        #if !defined COMPOSITE && !defined DEFERRED1
            vec3 nightClearLightColor = vec3(0.15, 0.14, 0.20) * (0.4 + vsBrightness * 0.4);
        #elif defined DEFERRED1
            vec3 nightClearLightColor = vec3(0.11, 0.14, 0.20);
        #else
            vec3 nightClearLightColor = vec3(0.07, 0.12, 0.27);
        #endif
        vec3 nightClearAmbientColor = vec3(0.09, 0.12, 0.17) * (1.55 + vsBrightness * 0.77);

        // Biome-specific lighting modifiers
        #ifdef SPECIAL_BIOME_WEATHER
            vec3 drlcSnowM = inSnowy * vec3(-0.06, 0.0, 0.04);
            vec3 drlcDryM = inDry * vec3(0.0, -0.03, -0.05);
        #else
            vec3 drlcSnowM = vec3(0.0), drlcDryM = vec3(0.0);
        #endif
        
        // Rain lighting
        #if RAIN_STYLE == 2
            vec3 drlcRainMP = vec3(-0.03, 0.0, 0.02);
            #ifdef SPECIAL_BIOME_WEATHER
                vec3 drlcRainM = inRainy * drlcRainMP;
            #else
                vec3 drlcRainM = drlcRainMP;
            #endif
        #else
            vec3 drlcRainM = vec3(0.0);
        #endif

        // Rainy weather lighting
        vec3 dayRainLightColor = vec3(0.21, 0.16, 0.13) * 0.85 + noonFactor * vec3(0.0, 0.02, 0.06)
                               + rainFactor * (drlcRainM + drlcSnowM + drlcDryM);
        vec3 dayRainAmbientColor = vec3(0.2, 0.2, 0.25) * (1.8 + 0.5 * vsBrightness);

        vec3 nightRainLightColor = vec3(0.03, 0.035, 0.05) * (0.5 + 0.5 * vsBrightness);
        vec3 nightRainAmbientColor = vec3(0.16, 0.20, 0.3) * (0.75 + 0.6 * vsBrightness);

        // Color blending
        #ifndef COMPOSITE
            float noonFactorDM = noonFactor;
        #else
            float noonFactorDM = noonFactor * noonFactor;
        #endif
        
        vec3 dayLightColor = mix(sunsetClearLightColor, noonClearLightColor, noonFactorDM);
        vec3 dayAmbientColor = mix(sunsetClearAmbientColor, noonClearAmbientColor, noonFactorDM);

        vec3 clearLightColor = mix(nightClearLightColor, dayLightColor, sunVisibility2);
        vec3 clearAmbientColor = mix(nightClearAmbientColor, dayAmbientColor, sunVisibility2);

        vec3 rainLightColor = mix(nightRainLightColor, dayRainLightColor, sunVisibility2) * 2.5;
        vec3 rainAmbientColor = mix(nightRainAmbientColor, dayRainAmbientColor, sunVisibility2);

        vec3 lightColor = mix(clearLightColor, rainLightColor, rainFactor);
        vec3 ambientColor = mix(clearAmbientColor, rainAmbientColor, rainFactor);
        
    #elif defined NETHER
        // Nether lighting
        vec3 lightColor = vec3(0.0);
        vec3 ambientColor = (netherColor + 0.5 * lavaLightColor) * (0.9 + 0.45 * vsBrightness);
        
    #elif defined END
        // End lighting
        vec3 endLightColor = vec3(0.68, 0.51, 1.07);
        float endLightBalancer = 0.2 * vsBrightness;
        
        vec3 lightColor = endLightColor * (0.35 - endLightBalancer);
        vec3 ambientColor = endLightColor * (0.2 + endLightBalancer);
    #endif

#endif //INCLUDE_LIGHT_AND_AMBIENT_COLORS

// Cloud Color System
#ifndef INCLUDE_CLOUD_COLORS
    #define INCLUDE_CLOUD_COLORS

    #if defined OVERWORLD
        // Rain cloud color
        vec3 cloudRainColor = mix(nightMiddleSkyColor, dayMiddleSkyColor, sunFactor);

        // Ambient cloud color
        vec3 cloudAmbientColor = mix(
            ambientColor * (sunVisibility2 * (0.55 + 0.1 * noonFactor) + 0.35), 
            cloudRainColor * 0.5, 
            rainFactor
        );

        // Direct cloud light color
        vec3 cloudLightColor = mix(
            lightColor * (0.9 + 0.2 * noonFactor), 
            cloudRainColor * 0.25, 
            noonFactor * rainFactor
        );
    #else
        // Non-overworld dimension cloud colors
        vec3 cloudRainColor = vec3(0.4, 0.3, 0.3);
        vec3 cloudAmbientColor = ambientColor * 0.7;
        vec3 cloudLightColor = lightColor * 0.8;
    #endif

#endif //INCLUDE_CLOUD_COLORS

