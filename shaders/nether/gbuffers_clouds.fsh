#version 130

#define FRAGMENT_SHADER
#define NETHER
#define GBUFFERS_CLOUDS

// Simple pass-through for vanilla clouds
uniform sampler2D tex;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec4 color = texture2D(tex, texcoord) * glcolor;
    
    /* DRAWBUFFERS:063 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
    gl_FragData[2] = vec4(1.0 - color.rgb, color.a);
}
