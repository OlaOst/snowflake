import std.stdio;

import derelict.opengl3.gl;
import derelict.sdl2.sdl;

import gl3n.linalg;

import glamour.shader;
import glamour.vao;
import glamour.vbo;

void main()
{
	writeln("Edit source/app.d to start your project.");
  
  auto window = init();
  
  auto vao = new VAO();
  vao.bind();
  
  auto vertexBuffer = new Buffer([vec2(-1.0, -1.0), vec2(1.0, -1.0), vec2(1.0, 1.0), vec2(-1.0, 1.0)]);
  auto colorBuffer = new Buffer([vec4(1.0, 0.0, 0.0, 1.0), vec4(0.0, 1.0, 0.0, 1.0), vec4(0.0, 0.0, 1.0, 1.0), vec4(1.0, 1.0, 1.0, 1.0)]);
  
  auto shader = new Shader("test.shader");
  
  SDL_Event event;
  while (event.key.keysym.sym != SDLK_ESCAPE)
  {
    SDL_PollEvent(&event);
    
    vertexBuffer.bind();
    colorBuffer.bind();
    shader.bind();
    
    vertexBuffer.bind(shader, "position", GL_FLOAT, 2, 0, 0);
    colorBuffer.bind(shader, "color", GL_FLOAT, 4, 0, 0);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    SDL_GL_SwapWindow(window);
  }
  
  shader.remove();
  vertexBuffer.remove();
  colorBuffer.remove();
  vao.remove();
}

immutable int screenWidth = 800;
immutable int screenHeight = 600;

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