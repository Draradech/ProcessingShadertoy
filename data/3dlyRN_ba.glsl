#version 330

uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

void mainImage(out vec4 fragColor, in vec2 fragCoord);

void main() {mainImage(gl_FragColor, gl_FragCoord.xy);}

// ########################## shadertoy code below ##########################
//#define DEBUG_CULLING
//#define DEBUG_LOOP
//#define DEBUG_LIST
#define EFFECT

#define FOV 0.5
#define ENTITY_MAX 5000
#define MARCH_STEP 100
#define MARCH_DISTANCE 20.0

#define SINGULARITY_RADIUS 6.667

#define QUATER 0.7853981633974483
#define HALF 1.5707963267948966
#define PI 3.141592653589793
#define CIRCLE 6.283185307179586

#define TS max( 1.0, sqrt( (iResolution.x * iResolution.y * 4.0) / float(ENTITY_MAX) ) )
#define TileSize (TS - mod(TS, 2.0))
#define listResolution (iResolution.xy - mod( iResolution.xy, vec2(TileSize) ))
#define EntityCount int(min( float(ENTITY_MAX), (listResolution.x / TileSize) * (listResolution.y / TileSize) * 4.0 ))

#define hasInResolution(pos,rez) all(bvec2(all(greaterThanEqual(ivec2(pos),ivec2(0.0))),bvec2(all(lessThan(ivec2(pos),ivec2(rez))))))

struct Camera {
	vec3 position;
	vec2 direction;//pitch yaw
	float fov;

};

struct Entity {
	vec3 position;
    float rotate;
    float radius;
    
};
    
struct Singularity
{
   	vec3 position;
    float radius;
    float force;
    
};
struct Project {
    vec2 uv;
    float radius;
    
};

const vec2 checkerOffset[4] = vec2[4](
	vec2( 0, 0),
    vec2(-1, 0),
    vec2( 0, 1),
    vec2( 0,-1)
);

vec2 getAspect ( const in vec2 resolution )
{
    return resolution.xy / min( resolution.x, resolution.y );
    
}

float getFrameTime ( const in float delta )
{
  	return delta * 100.0 / 2.0;
    
}

float hash ( const in float p )
{
    return (fract( sin( p ) * CIRCLE ) - 0.5) / 0.5;
    
}
  
float hashAbs ( const in float p )
{
    return fract( sin( p ) * CIRCLE );
    
}

float modI ( const in float a, const in float b )
{
    float m = a - floor( (a + 0.5) / b ) * b;
    
    return floor( m + 0.5 );
    
}

float atan2 ( const in float y, const in float x )
{
    return x == 0.0 ? sign( y ) * PI / 2.0 : atan( y, x );
    
}

vec3 rotate ( vec3 pos, vec3 axis,float theta )
{
    axis = normalize( axis );
    
    vec3 v = cross( pos, axis );
    vec3 u = cross( axis, v );
    
    return u * cos( theta ) + v * sin( theta ) + axis * dot( pos, axis );   
    
}

vec2 restoreCheckerCoord ( const in vec2 coord )
{
	return vec2(floor(coord.x) * 2.0 + mod(coord.y, 2.0), coord.y);

}

vec4 getCheckerPixel ( const in sampler2D tex, const in vec2 coord, const in vec2 rez, inout float div )
{
    vec2 cd = vec2(coord * vec2(0.5, 1.0));

	if (hasInResolution( cd, rez ))
	{
		div++;

		return texelFetch( tex, ivec2(cd), 0 );

	}

	return vec4(0.0);

}

vec4 restoreCheckerboardBuffer ( const in sampler2D tex, const in vec2 coord, const in vec2 rez )
{
	float ch = step( mod( coord.x + coord.y, 2.0 ), 0.5 );
	float div = 0.0;
	vec4 a = getCheckerPixel( tex, coord + vec2(1, 0) * ch, rez, div );
	vec4 b = getCheckerPixel( tex, coord + vec2(0, 1) * ch, rez, div );
	vec4 c = getCheckerPixel( tex, coord - vec2(1, 0) * ch, rez, div );
	vec4 d = getCheckerPixel( tex, coord - vec2(0, 1) * ch, rez, div );

	return (a + b + c + d) / 4.0;
	
}

//Copy to https://www.shadertoy.com/view/MdlGz4
vec3 yawPitchToDirection ( const in vec2 dir, const in vec2 uv , const in float fov )
{
	float xCos = cos( dir.x );
	float xSin = sin( dir.x );
	float yCos = cos( dir.y );
	float ySin = sin( dir.y );
	
	float gggxd = uv.x - 0.5;
	float ggyd = uv.y - 0.5;
	float ggzd = fov;
	
	float gggzd = ggzd * yCos + ggyd * ySin;
	
	return normalize( vec3(
		gggzd * xCos - gggxd * xSin,
		ggyd * yCos - ggzd * ySin,
		gggxd * xCos + gggzd * xSin
		
	) );

}

//Copy to https://www.shadertoy.com/view/MscSRr
Project projectSphere ( const in vec3 rdX, const in vec3 rdY, const in vec3 rdZ, const in vec3 ro, const in vec3 so, const in float sr, const in float fov )
{
	vec3 vel = so - ro;

	float cx = dot( vel, rdX );
	float cy = dot( vel, rdY );
	float cz = dot( vel, rdZ );
	
	float dz = dot( vel, rdZ );

    return Project(
		vec2(
            (cx / cz),
			(cy / cz)
            
        ) * fov,
		(sr * distance(vec2(1.0), vec2(0.0)) / dz) * fov
		
	);

}

Camera createCamera ( const in vec4 mouse, const in float time )
{
    float t = time / 10.0;
    vec3 pos = vec3((MARCH_DISTANCE / 2.0) + (MARCH_DISTANCE / 4.0) * sin( t ), MARCH_DISTANCE / 4.0, (MARCH_DISTANCE / 2.0) + (MARCH_DISTANCE / 4.0) * cos( t ));
    vec2 dir = vec2( atan2( pos.z - (MARCH_DISTANCE / 2.0), pos.x - (MARCH_DISTANCE / 2.0) ), -HALF - QUATER + 0.1);
    
    return Camera( pos, dir, FOV );
    
}

Entity getEntity ( const in sampler2D buf, const in int index, const in int length, const in vec2 resolution )
{
    int i = length + index + 1;
    vec4 entity = texelFetch( buf, ivec2(modI( float(i), resolution.x ), floor( float(i) / resolution.x )), 0  );
    vec3 pos = entity.rgb;
    float rotate = entity.a;
    float scale = 0.325 + hashAbs( float(index) * 0.87965 * float(index) ) * 0.125;

    if (pos.x == 0.0 && pos.y == 0.0 && pos.z == 0.0)
    {
        pos = vec3(
            hashAbs( float(index) * 0.012345 ) * MARCH_DISTANCE,
           	hashAbs( float(index) * 0.023154 ) * MARCH_DISTANCE,
            hashAbs( float(index) * 0.035312 ) * MARCH_DISTANCE

        );
        
        rotate = hashAbs( float(index) * 0.045131 );

    }
    
    pos = mod( pos, vec3(MARCH_DISTANCE) );
    
    return Entity( pos, rotate, scale );
    
}

Singularity getSingularity ( const in float time )
{
    float speed = 2.0;
    float radius = SINGULARITY_RADIUS;
    
    int index = int(floor( time / speed ));
    
   	vec3 pos = vec3(
        radius / 2.0 + hashAbs( float(index + 5) * 0.151 ) * (MARCH_DISTANCE - radius),
        radius / 2.0 + hashAbs( float(index + 5) * 0.781 ) * (MARCH_DISTANCE - radius),
        radius / 2.0 + hashAbs( float(index + 5) * 0.914 ) * (MARCH_DISTANCE - radius)
    
    );
    
    float force = cos( mod( time, speed ) / speed * PI );
    
    radius *= max( 0.0, sin( force * PI / 2.0 ) );
    
    return Singularity( pos, radius, force );
    
}

vec3 getForce ( const in sampler2D buffer, const in int index, const in int length, const in vec2 resolution )
{
    int i = index + 1;
    vec3 force = texelFetch( buffer, ivec2(modI( float(i), resolution.x ), floor( float(i) / resolution.x )), 0 ).rgb;
    
    return force;
    
}

vec4 computeForce ( const in int index, const in int count )
{
   	Entity entity = getEntity( iChannel0, index, count,  iResolution.xy  );
   	vec3 force = getForce( iChannel0, index, count, iResolution.xy );
    Singularity singularity = getSingularity( iTime );
    
    float dist = length( entity.position - singularity.position );
    float delta = getFrameTime( iTimeDelta );
    
    if (dist < singularity.radius)
    {
        float impact = mix( 0.000, 0.005, dist / singularity.radius) * max( 0.0, singularity.force );
        vec3 add = (singularity.position - entity.position) * impact;
        
        force += add * delta;
        
    }
    
    force -= force * 0.02 * delta;
    
    return vec4(force, 0.0);
    
}

vec4 computeEntity ( const in int index, const in int count )
{
   	Entity entity = getEntity( iChannel0, index, count,  iResolution.xy  );
   	vec3 force = getForce( iChannel0, index, count, iResolution.xy );
    
    vec3 pos = entity.position;
    float rotate = entity.rotate;
    float delta = getFrameTime( iTimeDelta );
    
    pos += force * delta;
    rotate += (force.x + force.y + force.z) * delta * (sign( hash( float(index) * 0.233 ) ) * 1.5);
    
    return vec4(pos, rotate);
    
}

void mainImage ( out vec4 fragColor, in vec2 fragCoord )
{
    int compute_point = int(fragCoord.y) * int(iResolution.x) + int(fragCoord.x);
    
    if (compute_point == 0)
    {
        fragColor = vec4(iResolution.xy, 0.0, 0.0);
        
    }
    else
    {
        vec3 resolution = texelFetch( iChannel0, ivec2(0), 0 ).rgb;
        
        compute_point -= 1;
        
        if (resolution.x == iResolution.x && resolution.y == iResolution.y)
        {
            int count = EntityCount;
            
            if (compute_point < count)
            {
                fragColor = computeForce( compute_point, count );

            }
            else if (compute_point < count * 2)
            {
                fragColor = computeEntity( compute_point - count, count );

            }
            else
            {
            	fragColor = vec4(0.0);
                
            }
            
        }
        else
        {
            fragColor = vec4(0.0);
            
        }
        
    }
    
}