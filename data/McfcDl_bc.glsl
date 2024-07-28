#define R iResolution.xy
#define Main void mainImage(out vec4 Q, in vec2 U)

#define A(U) texture(iChannel1,(U)/R)

#define vel(v) .5*(v)*inversesqrt(1.+dot(v,v))

float ln (vec3 p, vec3 a, vec3 b) { 
    return length(p-a-(b-a)*(dot(p-a,b-a)/dot(b-a,b-a)));
}

Main {

    Q = A(U);
    vec4 dQ = vec4(0);
    #define K (1./4.)
    for (int x = -1; x <= 1; x++)
    for (int y = -1; y <= 1; y++)
    if (abs(x)!=abs(y)) {
        vec2 v = vec2(x,y);
        vec2 W = U+v;
        vec4 q = A(W);
        
        vec2 a = vel(Q.xy),
             b = vel(q.xy)+v;
        float ab = dot(v,b-a);
        
        vec2 o = U+v;
        o.x += .3*R.x;
    
        if (o.x <.5*R.x && abs(length(o-.5*R)-100.) < 4. || (o.x >.5*R.x && o.x < .5*R.x+250. && abs(abs(o.y-.5*R.y)-100.+.0012*(o.x-.5*R.x)*(o.x-.5*R.x)) < 4.)) 
         {
             dQ += vec4(Q.xyz,1)*K;
         }   
        else 
        
        {
            float i = dot(v,(0.5*v-a))/ab;
            float j = .5+.0*clamp(q.w,0.,1.);
            float k = .5+.0*clamp(Q.w,0.,1.);
            float wa = K*Q.w*min(i,j)/j;
            float wb = K*q.w*max(k+i-1.,0.)/k;
            dQ += vec4(Q.xyz,1)*wa+vec4(q.xyz,1)*wb;
        } 
        
    }
    if (dQ.w>0.) dQ.xyz /= dQ.w;
    Q = dQ;
    
    U.x += .3*R.x;
    
    Q = mix(Q,vec4(Q.xy,2,2),.2*exp(-.01*dot(U-.5*R,U-.5*R)));
    
    if (U.x <.5*R.x && abs(length(U-.5*R)-100.) < 4.) Q.xy *= 0.;
    if (U.x >.5*R.x && U.x < .5*R.x+250. && abs(abs(U.y-.5*R.y)-100.+.0012*(U.x-.5*R.x)*(U.x-.5*R.x)) < 4.) Q.xy *= 0.;

}