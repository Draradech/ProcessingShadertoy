
#define RENDER_QUALITY 1 // Render iterations per frame (increase to reduce noise)

// fract noise - https://www.shadertoy.com/view/4djSRW
vec2 hash(vec3 p3) {
	p3 = fract(p3 * vec3(.1031, .103, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

// SDFs - https://iquilezles.org/articles/distfunctions2d/
float rbox(vec2 p, vec2 b, vec4 r) {
    r.xy = (p.x>0.) ? r.xy : r.zw;
    r.x  = (p.y>0.) ? r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.) + length(max(q,0.)) - r.x;
}
float seg(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p-a, ba = b-a;
    return -length(pa-ba*(clamp(dot(pa,ba)/dot(ba,ba),0.,1.)));
}

// hemisphere sampling
vec3 hemi(vec2 s, vec3 n) {
    vec3 t = vec3(1.+n.z-n.xy*n.xy, -n.x*n.y) / (1.+n.z);
    return sqrt(1.-s.x) * n + sqrt(s.x) *
           (cos(6.*s.y) * vec3(t.xz,-n.x) + 
            sin(6.*s.y) * vec3(t.zy,-n.y) );
}

// scene distance
float map(vec3 p) {
    vec2 pp = p.xy - vec2(.43, 0),
         ps = p.zx * vec2(1,-1) - vec2(0,.75);
    
    // "P" shape
    float P =  rbox(pp,  vec2(.3, 1),  vec4(0));
    P = min(P, rbox(pp - vec2(.4,.45), vec2(.55), vec4(.4, .4, 0, 0)));
    P = max(P,  seg(pp,  vec2(.3, -2), vec2(.3,.6)) + .1);   
    P = max(P,  abs(p.z+1.15) - .02);

    // "S" shape
    if (ps.x > ps.y*2.3 + .8) {
        ps.x *= sign(ps.y);
        ps.y  =  abs(ps.y) - .74;
    }
    float S = rbox(ps, vec2(1.1, .6), vec4(0, 0, .6, .6));
    S = max(S, seg(ps, vec2(-.5, 0),  vec2(5, 0)) + .1);
    S = max(S, abs(++p.y)-.02);
    
    // Combine shapes
    return min(min(min(min(P, S), p.x+1.5), p.y+.3), 1.4-p.z);
}

void mainImage(out vec4 O, vec2 F) {
    vec2 R = iResolution.xy,
         e = vec2(1,-1)*1e-4,      // epsilon for normal calculation
         h = hash(vec3(F, iTime)), // random hash
         o = F + h - .5,
         u = (o+o-R)/R.y; // clip-space UVs
    
    vec4 acc = vec4(0); // Final accumulated color
    
    for (int i = 0; i < RENDER_QUALITY; i++) 
    {
        // Setup orthographic camera
        vec3 ro = vec3(2., 1.15, -3),
             rd = normalize(-ro), 
             r  = cross(vec3(0,1,0), rd) * 1.4, p;

        ro += u.x*r + u.y*cross(rd, r) - vec3(.2,.4,0);

        // Setup path-tracing
        vec4 bcol = vec4(0),
             mask = vec4(1);

        for (int b = 0; b < 4; b++) { // 4 bounces
            // Raymarching
            float d, t = 0.;
            for (int j = 0; j < 40; j++) {
                p = ro + t * rd;
                t += d = map(p);
                if (d < .002) break;
            }
            if (t > 7.) break;
            p -= rd*.01;

            // Compute normal
            vec3 n = normalize(e.xyy*map(p + e.xyy) + e.yyx*map(p + e.yyx) + 
                               e.yxy*map(p + e.yxy) + e.xxx*map(p + e.xxx));
            // Colorize
            vec4 col = vec4(1,.9,.9,.04);

            if (abs(p.x) < 1.4 && abs(p.y) < 1.1 && abs(p.z) < 1.2) {
                if (p.z < -1.11)     col = vec4(1,0,.1, 1);
                else if (p.z < -.35) col = vec4(1,.8,0, 1);
                else if (p.z < .4)   col = vec4(0,.7,.6,1);
                else                 col = vec4(0,.4,.7,1);
            }

            mask *= col;
            bcol += mask * col.a * max(1. - abs(n.x)*.5, 0.);

            // Bounce direction
            h = hash(vec3(h*9., b));
            ro = p;
            rd = hemi(h, n*.999);
        }

        acc += bcol / float(RENDER_QUALITY); 
    }
            
    O = mix(texture(iChannel0, F/R), acc, .01);
}