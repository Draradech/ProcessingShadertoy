//Rotation matrix trick learned from FabriceNeyret2
#define R mat2(cos(vec4(0,11,33,0)//
//
//Shortened main function with resolution
#define M void mainImage(out vec4 O, vec2 I) {vec3 r = iResolution//
//
//Sample texture0 using screen uvs.
#define T texture(iChannel0,I/r.xy)

/*
    "Dust" by @XorDev

    I wanted to see how small I could make a volumetric lighting shader.

    This is alteration of "Radioactive":
    https://shadertoy.com/view/mdG3Wy

    This pass simply outputs the results from buffer A
    
    <512 Chars playlist: shadertoy.com/playlist/N3SyzR
*/

M;
    //Output iChannel0 texture
    O = T;
}