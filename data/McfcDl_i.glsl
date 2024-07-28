#define R iResolution.xy
#define Main void mainImage(out vec4 Q, in vec2 U)

#define A(U) texture(iChannel0,(U)/R)

#define vel(v) .5*(v)*inversesqrt(1.+dot(v,v))

float ln (vec3 p, vec3 a, vec3 b) { 
    return length(p-a-(b-a)*(dot(p-a,b-a)/dot(b-a,b-a)));
}

Main {

    vec4 q = A(U);

    
    vec4 n = A(U+vec2(0,1));
    vec4 e = A(U+vec2(1,0));
    vec4 s = A(U-vec2(0,1));
    vec4 w = A(U-vec2(1,0));
    
    vec3 no = normalize(vec3(e.z*e.w-w.z*w.w,n.z*n.w-s.z*s.w,.1));
    
    
    Q = max(sin(-1.+1.*(q.z*q.w+q.z+q.w-3.)+vec4(1,2,3,4)),0.);

}