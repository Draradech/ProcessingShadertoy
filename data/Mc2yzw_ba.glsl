#version 330

uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

void mainImage(out vec4 fragColor, in vec2 fragCoord);

void main() {mainImage(gl_FragColor, gl_FragCoord.xy);}

// ########################## shadertoy code below ##########################

float t(vec2 uv) { return texture(iChannel0, uv).x / 9.; }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (iFrame == 0) { fragColor = vec4(0); return; }

    vec2 uv = fragCoord / iResolution.xy;
    vec2 d = 1.5 / iResolution.xy;
    vec3 o = vec3(-1,0,1);
    
    float blur = 0.;
    blur += t(uv + d * o.xx) + t(uv + d * o.yx) + t(uv + d * o.zx);
    blur += t(uv + d * o.xy) + t(uv + d * o.yy) + t(uv + d * o.zy);
    blur += t(uv + d * o.xz) + t(uv + d * o.yz) + t(uv + d * o.zz);
    
    vec2 uvc = (fragCoord * 2. - iResolution.xy) / iResolution.y;
    float dc = abs(length(uvc) - .2) - .01;
    float circle = smoothstep(0.01, 0., dc);
    
    fragColor = vec4(max(circle, blur), circle, blur, 1.);
}