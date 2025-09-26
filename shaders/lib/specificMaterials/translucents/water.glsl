// ============================== Step 1: Color Prep ============================== //
#if MC_VERSION >= 11300
    #if WATERCOLOR_MODE >= 2
        vec3 glColorM = glColor.rgb;

        #if WATERCOLOR_MODE >= 3
            glColorM.g = max(glColorM.g, 0.39);
        #endif

        #ifdef GBUFFERS_WATER
            translucentMultCalculated = true;
            translucentMult.rgb = normalize(sqrt2(glColor.rgb));
            translucentMult.g *= 0.88;
        #endif

        glColorM = sqrt1(glColorM) * vec3(1.0, 0.85, 0.8);
    #else
        vec3 glColorM = vec3(0.43, 0.6, 0.8);
    #endif

    #if WATER_STYLE < 3
        vec3 colorPM = pow2(colorP.rgb);
        color.rgb = colorPM * glColorM;
    #else
        vec3 colorPM = vec3(0.25);
        color.rgb = 0.375 * glColorM;
    #endif
#else
    #if WATER_STYLE < 3
        color.rgb = mix(color.rgb, vec3(GetLuminance(color.rgb)), 0.88);
        color.rgb = pow2(color.rgb) * vec3(2.3, 3.5, 3.1) * 0.9;
    #else
        color.rgb = vec3(0.13, 0.2, 0.27);
    #endif
#endif

#ifdef WATERCOLOR_CHANGED
    color.rgb *= vec3(WATERCOLOR_RM, WATERCOLOR_GM, WATERCOLOR_BM);
#endif
// ============================== End of Step 1 ============================== //

#define PHYSICS_OCEAN_INJECTION
#if defined GENERATED_NORMALS && (WATER_STYLE >= 2 || defined PHYSICS_OCEAN) && !defined DH_WATER
    noGeneratedNormals = true;
#endif

#if defined GBUFFERS_WATER || defined DH_WATER
    lmCoordM.y = min(lmCoord.y * 1.07, 1.0); // Iris/Sodium skylight inconsistency workaround
    
    float fresnel2 = pow2(fresnel);
    float fresnel4 = pow2(fresnel2);

    // ============================== Step 2: Water Normals (Simplified for Vanilla Look) ============================== //
    reflectMult = 0.1; // Minimal reflection for vanilla look

    #if WATER_MAT_QUALITY >= 3
        materialMask = OSIEBCA * 241.0; // Water
    #endif

    // Disabled complex water effects for vanilla appearance
    // Keep only basic water properties

    // Disabled complex normal mapping for vanilla water appearance
    // Keep surface flat and simple like vanilla Minecraft
    // ============================== End of Step 2 ============================== //

    // ============================== Step 3: Water Material Features (Simplified) ============================== //
    #if WATER_MAT_QUALITY >= 2
        if (isEyeInWater != 1) {
            // Simple vanilla-like water alpha
            #ifdef GBUFFERS_WATER
                float depthT = texelFetch(depthtex1, texelCoord, 0).r;
            #elif defined DH_WATER
                float depthT = texelFetch(dhDepthTex1, texelCoord, 0).r;
            #endif
            vec3 screenPosT = vec3(screenPos.xy, depthT);
            #ifdef TAA
                vec3 viewPosT = ScreenToView(vec3(TAAJitter(screenPosT.xy, -0.5), screenPosT.z));
            #else
                vec3 viewPosT = ScreenToView(screenPosT);
            #endif
            float lViewPosT = length(viewPosT);
            float lViewPosDifM = lViewPos - lViewPosT;

            // Simple vanilla-like transparency
            color.a = 0.8; // Fixed alpha for vanilla look

            #ifdef DISTANT_HORIZONS
                if (depthT == 1.0) color.a *= smoothstep(far, far * 0.9, lViewPos);
            #endif

            float waterFog = max0(1.0 - exp(lViewPosDifM * 0.15)); // Simplified fog
            color.a *= 0.4 + 0.6 * waterFog; // Less complex alpha blending
            ////

            // No foam effects for vanilla look
            ////
        } else { // Underwater
            noDirectionalShading = true;

            reflectMult = 0.5;

            #if MC_VERSION < 11300 && WATER_STYLE >= 3
                color.a = 0.7;
            #endif

            #ifdef GBUFFERS_WATER
                #if WATER_STYLE == 1
                    translucentMult.rgb *= 1.0 - fresnel4;
                #else
                    translucentMult.rgb *= 1.0 - 0.9 * max(0.5 * sqrt(fresnel4), fresnel4);
                #endif
            #endif
        }
    #else
        shadowMult = vec3(0.0);
    #endif
    // ============================== End of Step 3 ============================== //

    // ============================== Step 4: Final Tweaks (Vanilla Style) ============================== //
    reflectMult *= 0.1; // Minimal reflections for vanilla look

    color.a = mix(color.a, 1.0, fresnel4 * 0.3); // Reduced fresnel effect

    #ifdef GBUFFERS_WATER
        smoothnessG = 0.0; // No smoothness for flat vanilla water
        highlightMult = 0.1; // Minimal highlights for vanilla appearance
    #endif
    // ============================== End of Step 4 ============================== //
#endif
