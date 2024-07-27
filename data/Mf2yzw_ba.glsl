vec4 tx(in vec2 p){return texture(iChannel0, p);}

float blur(in vec2 uv){
    vec3 e = vec3(1, 0, -1);
    vec2 px = 1. / iResolution.xy;
	float res = 0.;
	res +=      (tx(uv + e.xx * px).x + tx(uv + e.xz * px).x + tx(uv + e.zx * px).x + tx(uv + e.zz * px).x);
    res += 2. * (tx(uv + e.xy * px).x + tx(uv + e.yx * px).x + tx(uv + e.yz * px).x + tx(uv + e.zy * px).x);
	res += 4. * (tx(uv + e.yy * px).x);
    return res / 16.;     
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    if (iFrame == 0) { fragColor = vec4(length(fragCoord/iResolution.y)); return; }

    vec2 uv = fragCoord/iResolution.xy;
    float avgReactDiff = blur(uv);

    vec2 px = 1. / iResolution.xy;
    vec3 e = vec3(1, 0, -1);
	vec2 lap = vec2(tx(uv + e.xy * px).y - tx(uv - e.xy * px).y, tx(uv + e.yx * px).y - tx(uv - e.yx * px).y);
    uv = uv + lap * px * 2.;
    vec2 f = tx(uv).xy;
	float newReactDiff = f.x + .1 * (f.x -  f.y) - .003;
    fragColor = vec4(clamp(newReactDiff, 0., 1.), avgReactDiff / .98, 0., 0.);
}
