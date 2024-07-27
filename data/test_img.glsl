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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    uv *= .1;
    fragColor = vec4(0);
    fragColor.r = texture(iChannel0, uv).x;
    fragColor.g = texture(iChannel1, uv).x;
    fragColor.b = texture(iChannel2, uv).x;
}
