// Luminara Shader Lite Low Profile - Enhanced Glowing Flowers System (Reduced Emission)
// Only bright, colorful flowers (NO GRASS of any kind)

#ifdef GBUFFERS_TERRAIN
    DoFoliageColorTweaks(color.rgb, shadowMult, snowMinNdotU, viewPos, nViewPos, lViewPos, dither);

    #ifdef COATED_TEXTURES
        doTileRandomisation = false;
    #endif
#endif

// Double-check: STRICT grass exclusion to prevent ANY grass glow
bool hasStrongGreenDominance = (color.g > 0.3 && color.g > color.r * 1.1 && color.g > color.b * 1.1) ||
                               (color.g > 0.4 && (color.r + color.b) < 0.6); // Extra grass protection
if (hasStrongGreenDominance) {
    // This looks like grass, skip ALL flower effects
    materialMask = 0.0;
    emission = 0.0; // Force no emission for grass-like materials
} else {
    // REDUCED flower lighting system - subtle glow only
    float brightness = dot(color.rgb, vec3(0.299, 0.587, 0.114));

    // Very selective flower color detection with REDUCED emission
    if (color.r > color.g + 0.15 && color.r > color.b + 0.15 && color.r > 0.5 && brightness > 0.4) {
        // Red flowers (Rose, Poppy, Red Tulip) - REDUCED glow
        emission = 0.8 + brightness * 0.6; // Much lower values
        color.rgb *= vec3(1.04, 0.98, 0.96); // Subtle enhancement
    } else if (color.b > color.r + 0.15 && color.b > color.g + 0.15 && color.b > 0.5 && brightness > 0.4) {
        // Blue flowers (Cornflower, Blue Orchid) - REDUCED glow
        emission = 0.9 + brightness * 0.7; // Much lower values
        color.rgb *= vec3(0.96, 0.98, 1.05); // Subtle enhancement
    } else if (color.r > 0.7 && color.g > 0.7 && color.b < 0.3 && brightness > 0.5) {
        // Yellow flowers (Dandelion, Sunflower) - REDUCED glow
        emission = 1.0 + brightness * 0.8; // Much lower values
        color.rgb *= vec3(1.05, 1.04, 0.95); // Subtle enhancement
    } else if (color.r > 0.5 && color.g < 0.35 && color.b > 0.5 && brightness > 0.4) {
        // Purple/Magenta flowers (Allium, Purple Tulip) - REDUCED glow
        emission = 0.9 + brightness * 0.7; // Much lower values
        color.rgb *= vec3(1.04, 0.96, 1.04); // Subtle enhancement
    } else if (color.r > 0.6 && color.g > 0.45 && color.b < 0.35 && brightness > 0.4) {
        // Orange flowers (Orange Tulip) - REDUCED glow
        emission = 1.0 + brightness * 0.8; // Much lower values
        color.rgb *= vec3(1.05, 1.03, 0.95); // Subtle enhancement
    } else if (color.r > 0.7 && color.g > 0.7 && color.b > 0.7 && brightness > 0.5) {
        // White flowers (White Tulip, Oxeye Daisy) - REDUCED glow
        emission = 0.8 + brightness * 0.6; // Much lower values
        color.rgb *= vec3(1.02, 1.02, 1.02); // Very subtle enhancement
    } else if (color.r > 0.6 && color.g > 0.4 && color.b > 0.6 && brightness > 0.4) {
        // Pink flowers (Pink Tulip) - REDUCED glow
        emission = 0.7 + brightness * 0.5; // Much lower values
        color.rgb *= vec3(1.03, 0.99, 1.01); // Very subtle enhancement
    } else {
        // No clear flower pattern detected - NO emission
        emission = 0.0;
    }

    // Only apply effects if we detected a clear flower AND emission is reasonable
    if (emission > 0.0 && emission < 2.5) { // Cap maximum emission
        // Add very subtle time-based flickering
        vec3 worldPosFlower = playerPos + cameraPosition;
        float timeNoise = sin(frameTimeCounter * 1.2 + dot(worldPosFlower.xz, vec2(12.9898, 78.233))) * 0.5 + 0.5;
        timeNoise = timeNoise * 0.05 + 0.95; // Very gentle flickering
        emission *= timeNoise;

        // Modest night enhancement
        float timeOfDay = sunAngle;
        float isNight = float(timeOfDay > 0.52 && timeOfDay < 0.98);
        float nightFactor = 1.0 + isNight * 0.2; // Reduced enhancement
        emission *= nightFactor;

        // Distance-based brightness adjustment - fade out at distance
        float distanceFactor = 1.0 - min(lViewPos / 48.0, 0.7); // Stronger distance fade
        emission *= (0.5 + 0.5 * distanceFactor); // More conservative base

        materialMask = 0.0; // No SSAO for glowing flowers
    } else {
        // Force no emission for anything that doesn't clearly match flower criteria
        emission = 0.0;
    }
}
