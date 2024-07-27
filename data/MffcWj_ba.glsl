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

#define F 10.
#define G .9
#define S .007
#define K 4.
#define KL (2. * K + 1.)
#define KS (KL * KL)

vec4 wrapFetch(ivec2 p)
{
    ivec2 r = ivec2(textureSize(iChannel0, 0));
    p = (p + r) % r;
    return texelFetch(iChannel0, p, 0);
}

float hash(float v)
{
    return fract(sin(v) * 5897.);
}

float frand(vec2 c)
{
    return hash(c.x + 983. * hash(c.y + 911. * hash(iDate.w)));
}

float init(vec2 c)
{
    vec2 uv = c / iResolution.xy;
    float d = 2.;
    for (float i = 0.; i < 50.; i++)
    {
        vec2 u = vec2(frand(vec2(i, 0)), frand(vec2(i, 1)));
        d = min(d, length(u - uv));
    }
    return 1. - step(.05, d);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    ivec2 px = ivec2(fragCoord);

    if (iFrame == 0 || iMouse.w > 0.)
    {
        fragColor.x = init(fragCoord);
        fragColor.y = 0.;
        return;
    }
    
    float vsum = 0.;
    vec4 self = wrapFetch(px);

    for (float dx = -K; dx <= K; dx++)
    {
        for (float dy = -K; dy <= K; dy++)
        {
            vec4 n = wrapFetch(px + ivec2(dx, dy));
            vsum += (n.x + n.y / (F * G));
        }
    }

    if (self.x > 1.)
    {
        fragColor.x = 0.;
        fragColor.y = F;
    }
    else
    {
        fragColor.y = max(self.y - 1., 0.);
        fragColor.x = (vsum / KS) * ((F - self.y) / F);
        if (self.y == 0.) fragColor.x += S * self.x;
    }
}