#version 330 core

vertex:
  in vec2 position;

  void main()
  {
    gl_Position = vec4(position*0.9, 0, 1);
  }

fragment:
  uniform vec2 scale;
  uniform sampler2D textureMap;
  out vec4 color;
  
  void main()
  {
    color = texture(textureMap, gl_FragCoord.xy * scale);
  }
  