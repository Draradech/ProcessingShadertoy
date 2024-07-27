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

const vec3 sun_direction = vec3(0.0, 1.0, 0.0);

float op ( const in float x1, const in float x2 )
{
    return x1 < x2 ? x1 : x2;
    
}

bool boundingSphere ( const in vec3 rd, const in vec3 ro, const in vec3 so, const in float sr )
{
    return length( cross( rd, so - ro ) ) < sr;
    
}

float diffuse ( vec3 light, vec3 normal, float power )
{
	return 1.0 - (1.0 - clamp( dot( normal, light ), 0.0, 1.0 )) * power;

}
float phong ( const in vec3 rd, const in vec3 ld, const in vec3 normal, const in float fresnel, const in float roughness, const in float metallic )
{
	vec4 parametes = vec4(0.1, fresnel, roughness, metallic);
	vec3 n = normal;
	vec3 invLight = ld;
	vec3 invEye = rd;
	vec3 halfLE = normalize( invLight - invEye );

	float rough = parametes.z;
	float alpha2 = pow( rough, 4.0 );
	float D = alpha2 / (PI * pow( dot( n, halfLE ) * dot( n, halfLE ) * (alpha2 - 1.0) + 1.0, 2.0 ));
	float fre = parametes.y + (1.0 - parametes.y) * pow( clamp( dot( invEye, halfLE ), 0.0, 1.0 ), 5.0 );
	float nv = clamp( dot( invEye, n ), 0.0, 1.0 );
	float nl = clamp( dot( invLight, n ), 0.0, 1.0 );
	float G = 1.0 / (nv + sqrt( alpha2 + (1.0 - alpha2) * nv * nv) ) / (nl + sqrt( alpha2 + (1.0 - alpha2) * nl * nl ));
	float specular = D * fre * G;
	float diffuse = (1.0 - fre) * clamp( dot( n, invLight ), 0.0, 1.0 ) / PI;
	float meta = parametes.w;

	return clamp( mix( diffuse, specular, meta ), 0.0, 1.0 );

}

//Copy to https://www.shadertoy.com/view/Xds3zN
float udSphere ( const vec3 p, const float r )
{
	return length( p ) - r;
    
}
float udRoundBox ( const vec3 p, const vec3 b, const float r )
{
	return length( max( abs( p ) - b, 0.0 ) ) - r;
    
}

float mapRock ( const in Entity entity, const in int index, const in vec3 pos )
{    
    float h = 1e15;

    vec3 p = rotate(
        pos - entity.position,
        vec3(
            hash( float(index) * 0.12345 ),
            hash( float(index) * 0.54321 ),
            hash( float(index) * 0.23154 )
        ),
        entity.rotate

    );

    h = op( h, udRoundBox( p, vec3( entity.radius * 0.5 ), 0.025 ) );
    
    return h;
    
}

vec3 getNormalRock ( const in Entity entity, const in int index, const in vec3 pos )
{
    vec2 e = vec2(0.001, 0.0);
    
    return normalize( 0.000001 + mapRock( entity, index, pos ) - vec3(mapRock( entity, index, pos - e.xyy ), mapRock( entity, index, pos - e.yxy ), mapRock( entity, index, pos - e.yyx )) );
    
}

float mapSingularity ( const in Singularity singularity, const in vec3 pos )
{    
    float h = 1e15;

    h = op( h, udSphere( pos - singularity.position, singularity.radius ) );

    return h;
    
}

vec3 getNormalSingularity ( const in Singularity singularity, const in vec3 pos )
{
    vec2 e = vec2(0.001, 0.0);
    
    return normalize( 0.000001 + mapSingularity( singularity, pos ) - vec3(mapSingularity( singularity, pos - e.xyy ), mapSingularity( singularity, pos - e.yxy ), mapSingularity( singularity, pos - e.yyx )) );
    
}

bool march ( const in vec3 rd, const in vec3 ro, const in int index, const in Entity entity, const in int count, const in vec3 background, inout float dist, inout float depth, inout vec3 color )
{
    vec3 pos = ro;
    float d = 1e10;
    
   	for (int i = 0; i < MARCH_STEP; i++)
    {
        float dst = length( ro - pos );
        
        if (dst > dist)
        {
            return false;
            
        }

        d = op( d, mapRock( entity, index, pos ) );

        if (d > 0.0001)
        {
            pos += rd * d;

            continue;

        }

        vec3 normal = getNormalRock( entity, index, pos );

        Singularity singularity = getSingularity( iTime );

        vec3 material = vec3(1.0, 0.75, 1.0);

        vec3 dir = normalize( singularity.position - pos );
        float radius = SINGULARITY_RADIUS * 1.25 * (0.5 + sin( abs( singularity.force ) * PI ) * 0.5);
        float power = (1.0 - min( 1.0, length( singularity.position - pos ) / radius )) * (1.0 - abs( singularity.force ));

        vec3 sun_light = phong( rd, sun_direction, normal, material.x, material.y, material.z ) * vec3(0.5, 0.5, 0.75);
        vec3 sin_light = phong( rd, dir, normal, material.x, material.y, material.z ) * diffuse( dir, normal, 1.0 ) * power * vec3(0.75, 0.75, 1.0);

        depth = min( 1.0, dst / MARCH_DISTANCE );
        color = mix( sun_light * 0.25 + sin_light * 25.0, background, depth );
        dist = dst;

        return true;


    }
    
    return false;
}

bool marchRock ( const in vec3 rd, const in vec3 ro, const in int index, const in int count, const in vec3 background, inout float dist, inout float depth, inout vec3 color )
{
   	Entity entity = getEntity( iChannel0, index, count, iResolution.xy );

    return dist > length( ro - entity.position ) - entity.radius / 2.0 && boundingSphere( rd, ro, entity.position, entity.radius ) && march( rd, ro, index, entity, count, background, dist, depth, color );
    
}

void marchSingularity ( const in vec3 rd, const in vec3 ro, const in float dist, inout vec3 color, inout vec2 distortion )
{  
    Singularity singularity = getSingularity( iTime );
    
    if (
        singularity.radius <= 0.0 ||
        !boundingSphere( rd, ro, singularity.position, singularity.radius )
        
    )
    {
        return;
        
    }
    
    vec3 pos = ro;
    float d = 1e10;
    
   	for (int i = 0; i < MARCH_STEP; i++)
    {
        float dst = length( ro - pos );
        
        if (dst < dist)
        {
            d = op( d, mapSingularity( singularity, pos ) );

            if (d > 0.0001)
            {
                pos += rd * d;

                continue;

            }

            float radius = singularity.radius;
            vec3 normal = getNormalSingularity( singularity, pos );
            vec3 p = pos + normal;
            
            distortion = (cross( p, singularity.position ).xz - cross( singularity.position, p ).xz) * (1.0 - singularity.radius / SINGULARITY_RADIUS);
            
        }
        
        break;
        
    }
    
}

vec4 rendering ( const in vec3 rd, const in vec3 ro, const in vec2 uv, const in vec2 resolution )
{
    vec3 background = mix( vec3(0.0), vec3(0.25, 0.25, 0.375), dot( rd, sun_direction ) );
    float depth = -1.0;
    vec3 color = background;
    vec2 distortion = vec2(0.0);
    
    vec2 tile = vec2(TileSize);
    
	ivec2 AABB_coord = ivec2(floor(uv * resolution) / floor(resolution / tile));
    
    vec2 tile_resolution = vec2(ivec2(listResolution / tile));
    
    ivec2 tile_start_coord = ivec2(vec2(AABB_coord) * tile_resolution);
    ivec2 tile_end_coord =  ivec2(vec2(AABB_coord + 1) * tile_resolution);
    
    ivec2 tile_fix_resolution = tile_end_coord - tile_start_coord;
    
    int add = 0;
    
    float dist = MARCH_DISTANCE;
    int count = EntityCount;

    for (int index = 0, len = EntityCount / 4; index < len; index++)
    {
        ivec2 tile_coord = ivec2(
           modI( float(index), float(tile_fix_resolution.x) ),
           index / tile_fix_resolution.x
            
        );
        
        vec4 pixel = texelFetch( iChannel1, tile_start_coord + tile_coord, 0 );
        
        int entity_index = index * 4;

        pixel.r == 1.0 && marchRock( rd, ro, entity_index + 0, count, background, dist, depth, color );
        pixel.g == 1.0 && marchRock( rd, ro, entity_index + 1, count, background, dist, depth, color );
        pixel.b == 1.0 && marchRock( rd, ro, entity_index + 2, count, background, dist, depth, color );
        pixel.a == 1.0 && marchRock( rd, ro, entity_index + 3, count, background, dist, depth, color );

    }
    
    marchSingularity( rd, ro, dist, color, distortion );
    
    #ifdef DEBUG_LOOP
        color += vec3(float(end - start) / float(count), 0.0, 0.0);
    #endif
    
    #ifdef DEBUG_CULLING
        color += vec3(float(add) / 25.0, 0.0, 0.0);

    #endif
    
    if (depth > 0.0)
    {
    	depth = (depth < 0.25 ? (1.0 - depth / 0.25) : (depth - 0.25) * 0.25);
        
    }
    
    return vec4(color.b, depth, distortion.rg);
    
}

void mainImage ( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 resolution = iResolution.xy;
    vec2 coord = fragCoord;
    
    if (coord.x <= floor(resolution.x / 2.0))
    {
    	vec2 uv = restoreCheckerCoord( coord ) / resolution;
        Camera cam = createCamera( iMouse, iTime );
        vec3 rd = yawPitchToDirection( cam.direction, (uv - 0.5) * getAspect( resolution.xy ) + 0.5, cam.fov );

        fragColor = rendering( rd, cam.position, uv, resolution );
        
    }
    else
    {
        discard;
        
    }

}