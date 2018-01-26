#version 300 es

#define EPSILON 0.0001

precision highp float;

uniform float u_LightDensity;
uniform bool u_ContourLine;
uniform float u_Temp;
uniform float u_Hum;

in float time;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_ViewVec;
in float elevation;

out vec4 out_Col;

const vec3 color[6] = vec3[](
    vec3(0.92, 0.94, 1), //ice
    vec3(0.50, 0.55, 0.55), //rock
    vec3(0.10, 0.6, 0.1), //forest
    vec3(0.7, 0.75, 0.5), //sand
    vec3(0.20, 0.5, 0.86), //sea
    vec3(0.14, 0.3, 0.64) //deep sea
);

float rand(float n){return fract(sin(n) * 43758.5453123);}

void main()
{
        
        
        vec3 diffuseColor;

        float isOcean = 0.0;

        float sandD = (0.5 - u_Hum) * (u_Temp);
        float sandBaseD = sandD > 0.0 ? sandD : 0.0;
        float iceD = (u_Temp - 0.5) * (1.0 - u_Hum) * 0.5;
        float iceDBase = iceD > -0.2? iceD : -0.2;

        float thr[9] = float[](-0.08, -0.02, EPSILON, 0.01 + sandBaseD , 0.10 + sandBaseD + iceDBase, 0.15 + sandBaseD + iceDBase, 
                                0.18 + sandBaseD + iceDBase, 0.19 + sandBaseD + iceDBase, 0.2 + sandBaseD + iceDBase);



        if(elevation < thr[0]) { // deep sea
            diffuseColor = color[5];
            isOcean = 1.0;
        } else if(elevation < thr[1]) {
            diffuseColor = mix(color[5], color[4], (elevation - thr[0]) / (thr[1] - thr[0]));
            isOcean = 1.0;
        } else if(elevation < thr[2]) { // sea
            diffuseColor = color[4];
            isOcean = 1.0;
        } else if(elevation < thr[3]) { // sand
            diffuseColor = color[3];
        } else if(elevation < thr[4]) {
            diffuseColor = mix(color[3], color[2], (elevation - thr[3]) / (thr[4] - thr[3]));
        } else if(elevation < thr[5]) { // forest
            diffuseColor = color[2];
        } else if(elevation < thr[6]) {
            diffuseColor = mix(color[2], color[1], (elevation - thr[5]) / (thr[6] - thr[5]));
        } else if(elevation < thr[7]) { // rock
            diffuseColor = color[1];
        } else if(elevation < thr[8]) {
            diffuseColor = mix(color[1], color[0], (elevation - thr[7]) / (thr[8] - thr[7]));
        } else { // ice
            isOcean = 0.8;
            diffuseColor = color[0];
        }


        // Lambertian
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        

        diffuseTerm = clamp(diffuseTerm, 0.0f, 1.0f);
        float ambientTerm = 0.2 + isOcean * 0.05;
        float lightIntensity = diffuseTerm + ambientTerm;

        // Specular term used to make Blinn-Phong for ocean and ice part
        float specularTerm;
        float exp = 40.0f;
        float factor = dot(normalize(0.5f * (fs_LightVec + fs_ViewVec)), normalize(fs_Nor));
        if(factor < EPSILON) {
            specularTerm = 0.0;
        } else {
            specularTerm = pow(factor, exp);
        }
        if(specularTerm < EPSILON) {
            specularTerm = 0.0;
        }

        
        vec3 colorOrigin = clamp(diffuseColor.rgb * lightIntensity + isOcean * specularTerm * vec3(1, 1, 1), vec3(0, 0, 0), vec3(0.9, 0.9, 1));
        out_Col = vec4(colorOrigin, 1);

        // city light on the night side
        if(dot(fs_LightVec, fs_Nor) < - 0.5 && isOcean < 0.5 && !u_ContourLine) {
            float n = rand(elevation * 100.0);
            if(n < 0.08 * u_LightDensity) out_Col = vec4(1, 1, 1, 1);
        }

        if(isOcean < 0.5 && u_ContourLine) {
            float n = rand(elevation / 2000.0);
            if(n < 0.09) out_Col = vec4(1, 1, 1, 1);
        }


}
