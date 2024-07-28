#define R iResolution.xy
#define Main void mainImage(out vec4 Q, in vec2 U)

#define A(U) texture(iChannel3,(U)/R)

#define vel(v) .5*(v)*inversesqrt(1.+dot(v,v))

float ln (vec3 p, vec3 a, vec3 b) { 
    return length(p-a-(b-a)*(dot(p-a,b-a)/dot(b-a,b-a)));
}

Main {

    Q = A(U);
    for (int x = -1; x <= 1; x++)
    for (int y = -1; y <= 1; y++)
    if (abs(x)!=abs(y)) {
        vec2 v = vec2(x,y);
        vec4 q = A(U+v);
        Q.xy -= .1*(q.w*q.z)*v/dot(v,v)/Q.w;
        Q.z -= .2*q.w*dot(v/dot(v,v),q.xy);
    }
    
    if (iFrame < 1) {
       Q = vec4(0,0,1,1);
    
    }
    
    
    U.x += .3*R.x;
    
    Q = mix(Q,vec4(Q.xy,3,3),.2*exp(-.01*dot(U-.5*R,U-.5*R)));
    
    if (U.x <.5*R.x && abs(length(U-.5*R)-100.) < 4.) Q.xy *= 0., Q.w = 1.;
    if (U.x >.5*R.x && U.x < .5*R.x+250. && abs(abs(U.y-.5*R.y)-100.+.0012*(U.x-.5*R.x)*(U.x-.5*R.x)) < 4.) Q.xy *= 0., Q.w = 1.;
}