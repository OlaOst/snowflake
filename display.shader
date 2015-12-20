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
  
  vec2 fixedCoord(vec2 coord)
  {
    vec2 middle = coord - vec2(0.5, 0.5);
    float angle = 3.1415 / 4;
    float scale = sqrt(3) / 3;
    
    vec2 scaled = mat2(scale, 0, 0, 1.0) * middle;
    vec2 rotated = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * scaled;
    
    return rotated + vec2(0.5, 0.5);
  }
  
  void main()
  {
    vec2 coord = gl_FragCoord.xy * scale;
    color = texture(textureMap, fixedCoord(gl_FragCoord.xy * scale));
  }
  