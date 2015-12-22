import std.algorithm;
import std.random;
import std.range;
import std.stdio;

import derelict.opengl3.gl;
import derelict.sdl2.sdl;

import gl3n.linalg;

import glamour.fbo;
import glamour.shader;
import glamour.texture;
import glamour.vao;
import glamour.vbo;

void main()
{ 
  auto window = init();
  
  auto vao = new VAO();
  vao.bind();
  
  auto vertexBuffer = new Buffer([vec2(-1.0, -1.0), 
                                  vec2(1.0, -1.0), 
                                  vec2(1.0, 1.0), 
                                  vec2(-1.0, 1.0)]);
                               
  auto snowflakeShader = new Shader("snowflake.shader");
  auto displayShader = new Shader("display.shader");
  
  int textureSize = 1024;
  
  auto frameBuffer = new FrameBuffer();
  
  auto textures = [new Texture2D(), new Texture2D()];
  
  ubyte[] data = ubyte.min.repeat.take(textureSize * textureSize * 4).array;
  for (int y = 0; y < textureSize; y++)
    for (int x = 0; x < textureSize; x++)
      data[y * textureSize * 4 + x * 4 + 0] = cast(ubyte)(0.99 * 256); //uniform(ubyte.min, ubyte.max);
      //data[y * textureSize * 4 + x * 4 + 0] = uniform(ubyte.min, ubyte.max);
  
  // ice seed in the middle
  data[(textureSize/2) * textureSize * 4 + (textureSize/2) * 4 + 2] = ubyte.max;
  
  // try a line
  //for (int x = textureSize/3; x < textureSize/3*2; x++)
    //data[x * textureSize * 4 + x * 4 + 2] = ubyte.max;
  
  //textures.each!(texture => texture.set_data(data, GL_RGBA, textureSize, textureSize, GL_RGBA, GL_UNSIGNED_BYTE));
  
  reset(textures, data, textureSize);
  
  SDL_Event event;
  int iteration = 0;
  while (event.key.keysym.sym != SDLK_ESCAPE && event.type != SDL_QUIT)
  {
    SDL_PollEvent(&event);
    
    if (event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_r)
    {
      reset(textures, data, textureSize);
    }
    
    // brownian motion
    for (int i = 0; i < 25; i++)
    {
      diffusionFactor += uniform(-0.01, 0.01);
      waterToSlushFactor += uniform(-0.01, 0.01);
      //freezingFactor += uniform(-0.01, 0.01);
    }
    diffusionFactor = std.algorithm.clamp(diffusionFactor, 0.01, 0.99);
    waterToSlushFactor = std.algorithm.clamp(waterToSlushFactor, 0.01, 0.99);
    freezingFactor = std.algorithm.clamp(freezingFactor, 0.01, 0.99);
    
    iteration++;
    
    //if ((iteration % 3) == 0)
    {
      auto front = iteration % 2;
      auto back = (iteration+1) % 2;
      
      stepAutomata(frameBuffer, textures[front], textures[back], textureSize, vertexBuffer, snowflakeShader, iteration);
    }
    
    if ((iteration % 10) == 0)
      toScreen(frameBuffer, displayShader, vertexBuffer, window);
  }
  
  frameBuffer.remove();
  textures.each!(texture => texture.remove());
  snowflakeShader.remove();
  displayShader.remove();
  vertexBuffer.remove();
  vao.remove();
}

float diffusionFactor;
float waterToSlushFactor;
float freezingFactor;

void reset(Texture2D[] textures, ubyte[] data, int textureSize)
{
  textures.each!(texture => texture.set_data(data, GL_RGBA, textureSize, textureSize, GL_RGBA, GL_UNSIGNED_BYTE));
      
  foreach (texture; textures)
  {
    texture.set_parameter(GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    texture.set_parameter(GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    texture.set_parameter(GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    texture.set_parameter(GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  }
      
  diffusionFactor = uniform(0.1, 0.9);
  //diffusionFactor = 0.5;
  waterToSlushFactor = uniform(0.1, 0.9);
  freezingFactor = uniform(0.1, 0.9);
  
  writeln();  
  writeln("Diffusion factor: ", diffusionFactor);
  writeln("Slush factor:     ", waterToSlushFactor);
  writeln("Freezing factor:  ", freezingFactor);
}

void stepAutomata(FrameBuffer frameBuffer, Texture2D front, Texture2D back, int textureSize, Buffer vertexBuffer, Shader snowflakeShader, int iteration)
{
  frameBuffer.bind();
  frameBuffer.attach(back, GL_COLOR_ATTACHMENT0);
  
  checkgl!glViewport(0, 0, textureSize, textureSize);
  front.bind();
  
  vertexBuffer.bind();
  snowflakeShader.bind();
  
  vertexBuffer.bind(snowflakeShader, "position", GL_FLOAT, 2, 0, 0);
  
  snowflakeShader.uniform1f("scale", 1.0 / textureSize);
  snowflakeShader.uniform1f("diffusionFactor", diffusionFactor);
  snowflakeShader.uniform1f("waterToSlushFactor", waterToSlushFactor);
  snowflakeShader.uniform1f("freezingFactor", freezingFactor);
  snowflakeShader.uniform1i("iteration", iteration);
  
  checkgl!glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
  
}

void toScreen(FrameBuffer frameBuffer, Shader displayShader, Buffer vertexBuffer, SDL_Window* window)
{
  frameBuffer.unbind();
  checkgl!glViewport(0, 0, screenWidth, screenHeight);
  
  vertexBuffer.bind();
  displayShader.bind();
  
  vertexBuffer.bind(displayShader, "position", GL_FLOAT, 2, 0, 0);
  displayShader.uniform("scale", vec2(1.0 / screenWidth, 1.0 / screenHeight));
  
  checkgl!glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
  
  SDL_GL_SwapWindow(window);
  checkgl!glClearColor(0.0, 0.0, 0.33, 1.0);
  checkgl!glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

immutable int screenWidth = 1024;
immutable int screenHeight = 768;

SDL_Window* init()
{
  DerelictSDL2.load();
  DerelictGL3.load();
  
  SDL_Init(SDL_INIT_VIDEO);
  
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

  auto window = SDL_CreateWindow("Snowflake", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, screenWidth, screenHeight, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
  
  auto context = SDL_GL_CreateContext(window);

  SDL_GL_SetSwapInterval(1);
  
  glViewport(0, 0, screenWidth, screenHeight);
  
  DerelictGL3.reload();
  
  return window;
}