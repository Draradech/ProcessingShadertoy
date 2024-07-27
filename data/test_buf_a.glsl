uniform vec3 iResolution;
uniform float iTime;
uniform int iFrame;
uniform vec4 iMouse;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

void mainImage(out vec4 fragColor, in vec2 fragCoord);

void main() {mainImage(gl_FragColor, gl_FragCoord.xy);}

// ########################## shadertoy code below ##########################

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float x;
    if(iFrame <= 0) x = 0.;
    else {
        x = texelFetch(iChannel0, ivec2(0), 0).x;
        x++;
    }
    
    if (floor(fragCoord) == vec2(0)) fragColor = vec4(x);
    else if (floor(fragCoord.x) == x) fragColor = vec4(1);
    else fragColor = vec4(0);
}
