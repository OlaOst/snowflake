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
    
    //vec4 average = (nw + n + ne + w + c + e + sw + s + se) * (1.0 / 9.0);
    vec4 average = (n + ne + w + c + e + sw + s) * (1.0 / 7.0);
    
    float water = average.r;
    float slush = c.g;
    float ice = c.b;
    float surroundingIce = average.b - ice;
    
    // part of water in cell in contact with ice will turn into slush
    // slush will turn into ice if slush > water
    float waterToSlushFactor = 0.1;
    if (surroundingIce > 0.1)
    {
      float waterToSlush = water * waterToSlushFactor;
      
      water -= waterToSlush;
      water = 0.0;
      slush += waterToSlush;
    }
    
    if (slush > 0.9)
    {
      ice = 1.0;
      slush = 0.0;
    }
    
    color = c;
    color.r = water;
    color.g = slush;
    color.b = ice;
  }
  