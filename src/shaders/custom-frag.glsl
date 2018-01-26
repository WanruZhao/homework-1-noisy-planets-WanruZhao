#version 300 es

precision highp float;

uniform vec4 u_Color; 

in float time;

in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col;


void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color + vec4(0.5 * sin(time / 200.0f), 0.5 * cos(time / 200.0f), 0.5 * sin(time / 100.0f), 0);

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.0f, 1.0f);

        float ambientTerm = 0.5;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        vec3 colorOrigin = diffuseColor.rgb * lightIntensity;

        // Discretize colors
        for(int i = 0; i < 3; i++) {

            if(colorOrigin[i] < 0.2f) {
                colorOrigin[i] = 0.1f;
            }
            else if(colorOrigin[i] < 0.4f) {
                colorOrigin[i] = 0.3f;
            }
            else if(colorOrigin[i] < 0.6f) {
                colorOrigin[i] = 0.5f;
            }
            else if(colorOrigin[i] < 0.8f) {
                colorOrigin[i] = 0.7f;
            }
            else {
                colorOrigin[i] = 0.9f;
            }

        }

        // Compute final shaded color
        
        out_Col = vec4(colorOrigin, 1);
}
