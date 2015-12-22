#version 330 core

vertex:
  in vec2 position;

  void main()
  {    
    gl_Position = vec4(position*1.0, 0, 1);
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
    
    vec2 scaled = mat2(scale, 0, 0, 1) * middle;
    vec2 rotated = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * scaled;
    
    return rotated + vec2(0.5, 0.5);
  }
  
  void main()
  {
    vec2 coord = gl_FragCoord.xy * scale;
    vec4 state = texture(textureMap, fixedCoord(gl_FragCoord.xy * scale));
    
    /*if (state.r < 0.9 && state.g < 0.1 && state.b < 0.1)
      color.r = state.r;
    else
      color.r = 1-state.r;
    color.g = state.b;
    if (state.b > 0)
      color.b = 1-state.g;
    else
      color.b = 1-state.r;*/
    
    color = state;
    color.r = state.a - state.r*state.a;
    color.g = state.g * 1 + state.b*1;// + 1 - state.r;
    color.b = 1 - state.r + state.b*1;// + 1 - state.r;
    //color.a = state.a;
    color.a = 1.0;
  }
  