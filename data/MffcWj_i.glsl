#version 330

uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

void mainImage(out vec4 fragColor, in vec2 fragCoord);

void main() {mainImage(gl_FragColor, gl_FragCoord.xy);}

// ########################## shadertoy code below ##########################

#define COLORS 1

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float v = texture(iChannel0, (fragCoord + .5) / iResolution.xy).x / 1.1;
    v = pow(v, 1.3);

#if COLORS == 1
    fragColor = vec4(pow(v, 1.0), pow(v, 2.5), pow(v, 6.0), 1.0);
#elif COLORS == 2
    fragColor = mix(vec4(0., .45, .9, 1.), vec4(1., .45, 0., 1.), v);
#endif

}
