import {vec3, vec4} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import { GUIController } from 'dat-gui';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 6,
  'Load Scene': loadScene, // A function pointer, essentially
  Color: "#FF0000",
  Shader: "noise",
  Speed: 0.0,
  Temperature : 0.5,
  Humidity : 0.5,
  LevelOfDetail: 0,
  LightDensity: 0.0,
  ContourLine: false,

};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

// Used to assign color to object
var objColor: vec4;
// Used to change shader
var prog: ShaderProgram;
var time = 0;
var speed = 0.0;
var lightDensity = 0.0;
var lod = 0.0;
var contour = false;
var temp = 0.5;
var hum = 0.5;


function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Initialize obj color
  objColor = vec4.fromValues(1, 0, 0, 1);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  
  // Change color of cube
  gui.addColor(controls,'Color').onChange(function(){
 

    console.log(controls.Color);

    let color = [];

    console.log(controls.Color.slice(1, 3));
    color[0] = parseInt(controls.Color.slice(1, 3), 16);
    color[1] = parseInt(controls.Color.slice(3, 5), 16);
    color[2] = parseInt(controls.Color.slice(5, 7), 16);

    console.log(color);

    objColor = vec4.fromValues(color[0] / 255, 
                                color[1] / 255,
                                color[2] / 255,
                                1);
  });

  // Change shader
  gui.add(controls, 'Shader', ['noise', 'lambert', 'custom']).onChange(function() {
    if(controls.Shader == 'lambert') {
      prog = lambert;
    } else if(controls.Shader == 'custom') {
      prog = custom;
    } else if(controls.Shader == 'noise') {
      prog = noise;
    }
    
  });

  // add control parameters for planet
  gui.add(controls, 'Speed', 0, 1).step(0.01).onChange(function() {
    speed = controls.Speed;
  });
  gui.add(controls, 'Temperature', 0, 1).step(0.01).onChange(function() {
    temp = controls.Temperature;
  });
  gui.add(controls, 'Humidity', 0, 1).step(0.01).onChange(function() {
    hum = controls.Humidity;
  });
  gui.add(controls, 'LevelOfDetail', 0, 1).step(0.01).onChange(function() {
    lod = controls.LevelOfDetail;
  });
  gui.add(controls, 'LightDensity', 0, 1).step(0.01).onChange(function() {
    lightDensity = controls.LightDensity;
  });
  gui.add(controls, 'ContourLine').onChange(function() {
    contour = controls.ContourLine;
  });



  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0, 0, 0, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  // Add custom shader
  const custom = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/custom-frag.glsl')),
  ]);

  const noise = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/noise-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/noise-frag.glsl')),
  ]);

  prog = noise;

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    renderer.render(camera, prog, [
      icosphere,
      // square,
      //cube,
    ], objColor, time, speed, lightDensity, lod, contour, temp, hum);
    time++;
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
