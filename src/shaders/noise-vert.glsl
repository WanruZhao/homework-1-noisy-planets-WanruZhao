#version 300 es
#define PERLIN

uniform mat4 u_Model;       
uniform mat4 u_ModelInvTr;  
uniform mat4 u_ViewProj;    
uniform int u_Time;
uniform vec3 u_Camera;
uniform float u_Speed;
uniform float u_LOD;
uniform float u_Temp;
uniform float u_Hum;


in vec4 vs_Pos;             
in vec4 vs_Nor;             
in vec4 vs_Col;             

out vec4 fs_Nor;            
out vec4 fs_LightVec;       
out float time;
out vec4 fs_Pos;
out float elevation;
out vec4 fs_ViewVec;



const vec4 lightPos = vec4(5, 5, 20, 1); 

#ifdef PERLIN
vec3 random3(vec3 p) {
    return normalize(2.0 * fract(sin(vec3(dot(p,vec3(127.1,311.7,234.8)),dot(p,vec3(269.5,183.3,453.6)),dot(p,vec3(82.5,845.3,5.7))))*43758.5453) - 1.0);
}      

float surflet(vec3 P, vec3 gridPoint)
{
    // Compute falloff function by converting linear distance to a polynomial
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float distZ = abs(P.z - gridPoint.z);
    float tX = 1.0 - 6.0 * pow(distX, 5.0) + 15.0 * pow(distX, 4.0) - 10.0 * pow(distX, 3.0);
    float tY = 1.0 - 6.0 * pow(distY, 5.0) + 15.0 * pow(distY, 4.0) - 10.0 * pow(distY, 3.0);
    float tZ = 1.0 - 6.0 * pow(distZ, 5.0) + 15.0 * pow(distZ, 4.0) - 10.0 * pow(distZ, 3.0);

    vec3 gradient = random3(gridPoint);
    vec3 diff = P - gridPoint;
    float height = dot(diff, gradient);
    
    return height * tX * tY * tZ;
}

float PerlinNoise(vec3 p)
{
    // Tile the space
    vec3 n0 = floor(p);
    vec3 n1 = n0 + vec3(1,0,0);
    vec3 n2 = n0 + vec3(1,1,0);
    vec3 n3 = n0 + vec3(0,1,0);
    vec3 n4 = n0 + vec3(0,1,1);
    vec3 n5 = n0 + vec3(0,0,1);
    vec3 n6 = n0 + vec3(1,1,1);
    vec3 n7 = n0 + vec3(1,0,1);

    return surflet(p, n0) + surflet(p, n1) + surflet(p, n2) + surflet(p, n3) +
           surflet(p, n4) + surflet(p, n5) + surflet(p, n6) + surflet(p, n7);
}
#endif

float getNoise1(vec4 p) {
    return abs(PerlinNoise(vec3(p + vec4(sin(u_Speed * time / 400.0), cos(u_Speed * time / 670.0), 0, 0)) * 2.0));
}

float getNoise2(vec4 p) {
    return abs(PerlinNoise(vec3(p + vec4(1.3, 23.2, 45.8, 0.0))* 5.0 * (1.0 + u_LOD)));
}


void main()
{


    time = float(u_Time);                        

    mat3 invTranspose = mat3(u_ModelInvTr);

    vec4 modelposition = u_Model * vs_Pos;

#ifdef PERLIN
    float summedNoise1 = 0.0;
    float summedNoise2 = 0.0;
    float amplitude = 0.5;

    for(int i = 2; i <= 64; i *= 2) {
        float perlin1 = getNoise1(modelposition);
        float perlin2 = getNoise2(modelposition);
        summedNoise1 += perlin1 * amplitude;
        summedNoise2 += perlin2 * amplitude;
        amplitude *= 0.5;
    }
    

#endif

    float dev1 = pow(0.5 - u_Temp, 2.0);

    elevation = summedNoise1 * 0.8 * (dev1 * 2.0 + 1.0 - (u_Hum - 0.5)) - 0.22 * (0.8 - u_LOD * 0.1) + dev1 * 0.75 * (1.0 - u_Hum) - 0.25 * (u_Hum - 0.5);
    
    if(elevation > 0.0) {


        elevation += summedNoise2 * 0.2 * u_LOD;
 
        vec4 offset = (0.75 - dev1 - (1.0 - u_Hum) * 0.25) * vec4(normalize(vec3(modelposition)) * elevation, 0) ;

        modelposition = offset + modelposition;
    } 


    fs_ViewVec = vec4(u_Camera, 1) - modelposition;

    fs_Nor = vec4(normalize(invTranspose * vec3(modelposition)), 0); 


    fs_LightVec = lightPos - modelposition;  

    gl_Position = u_ViewProj * modelposition;

    fs_Pos = modelposition;
                               
}
