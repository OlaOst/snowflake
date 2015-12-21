import std.algorithm;
import std.random;
import std.range;
import std.stdio;

import derelict.opengl3.gl;
import derelict.sdl2.image;
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
  
  foreach (texture; textures)
  {
    texture.set_parameter(GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    texture.set_parameter(GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    texture.set_parameter(GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    texture.set_parameter(GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  }
  
  ubyte[] data = ubyte.min.repeat.take(textureSize * textureSize * 4).array;
  for (int y = 0; y < textureSize; y++)
    for (int x = 0; x < textureSize; x++)
      data[y * textureSize * 4 + x * 4 + 0] = cast(ubyte)(0.99 * 256); //uniform(ubyte.min, ubyte.max);
  
  // ice seed in the middle
  data[(textureSize/2) * textureSize * 4 + (textureSize/2) * 4 + 2] = ubyte.max;
  
  textures.each!(texture => texture.set_data(data, GL_RGBA, textureSize, textureSize, GL_RGBA, GL_UNSIGNED_BYTE));
  
  SDL_Event event;
  int index = 0;
  while (event.key.keysym.sym != SDLK_ESCAPE)
  {
    SDL_PollEvent(&event);
    
    if (event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_r)
    {
      textures.each!(texture => texture.set_data(data, GL_RGBA, textureSize, textureSize, GL_RGBA, GL_UNSIGNED_BYTE));
      
      diffusionFactor = uniform(0.1, 0.9);
      waterToSlushFactor = uniform(0.1, 0.9);
      freezingFactor = uniform(0.1, 0.9);
      
      writeln();  
      writeln("Diffusion factor: ", diffusionFactor);
      writeln("Slush factor:     ", waterToSlushFactor);
      writeln("Freezing factor:  ", freezingFactor);
    }
    
    // brownian motion
    for (int i = 0; i < 20; i++)
      diffusionFactor += uniform(-0.01, 0.01);
    diffusionFactor = std.algorithm.clamp(diffusionFactor, 0.01, 0.99);
    
    index++;
    
    //if ((index % 3) == 0)
    {
      auto front = index % 2;
      auto back = (index+1) % 2;
      
      stepAutomata(frameBuffer, textures[front], textures[back], textureSize, vertexBuffer, snowflakeShader);
    }
    
    if ((index % 2) == 0)
      toScreen(frameBuffer, displayShader, vertexBuffer, window);
  }
  
  frameBuffer.remove();
  textures.each!(texture => texture.remove());
  snowflakeShader.remove();
  displayShader.remove();
  vertexBuffer.remove();
  vao.remove();
}

float diffusionFactor = 0.5;
float waterToSlushFactor = 0.3;
float freezingFactor = 0.9;

void stepAutomata(FrameBuffer frameBuffer, Texture2D front, Texture2D back, int textureSize, Buffer vertexBuffer, Shader snowflakeShader)
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

immutable int screenWidth = 800;
immutable int screenHeight = 600;

SDL_Window* init()
{
  DerelictSDL2.load();
  DerelictSDL2Image.load();
  DerelictGL3.load();
  
  SDL_Init(SDL_INIT_VIDEO);
  IMG_Init(0);
  
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