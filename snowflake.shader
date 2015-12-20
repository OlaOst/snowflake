#version 330 core

vertex:
  in vec2 position;
  
  void main()
  {
    gl_Position = vec4(position, 0, 1);
  }

fragment:
  uniform sampler2D textureMap;
  uniform float scale;
  
  out vec4 color;
  
  vec4 get(int x, int y)
  {
    return texture2D(textureMap, (gl_FragCoord.xy + vec2(x, y)) * scale);
  }
  
  void main()
  {
    vec4 nw = get(-1,  1);
    vec4 n  = get( 0,  1);
    vec4 ne = get( 1,  1);
    vec4  w = get(-1,  0);
    vec4  c = get( 0,  0);
    vec4  e = get( 1,  0);
    vec4 sw = get(-1, -1);
    vec4 s  = get( 0, -1);
    vec4 se = get( 1, -1);
    
    float water = (nw.r + n.r + ne.r + w.r + c.r + e.r + sw.r + s.r + se.r) / 9.0;
    
    float slush = c.g;
    float ice = c.b;
    
    color = c;
    
    color.r = water;
  }
  