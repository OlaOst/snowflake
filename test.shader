#version 330 core

vertex:
  in vec2 position;
  in vec4 color;

  out vec4 vertexColor;
  
  void main()
  {  
    vertexColor = color;
    gl_Position = vec4(position*0.9, 0, 1);
  }

fragment:
  in vec4 vertexColor;
  out vec4 color;
  
  void main()
  {
    color = vertexColor;
  }