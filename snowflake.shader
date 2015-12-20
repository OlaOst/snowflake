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
  
  uniform float diffusionFactor;
  uniform float waterToSlushFactor;
  uniform float freezingFactor;
  
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
    //vec4 average = (n + ne + w + c + e + sw + s) * (1.0 / 7.0);
    vec4 surroundingAverage = (n + ne + w + e + sw + s) * (1.0 / 6.0);
    
    vec4 average = c * (1-diffusionFactor) + surroundingAverage * diffusionFactor;
    
    float water = average.r;
    float slush = c.g;
    float ice = c.b;
    //float surroundingIce = average.b * 7 - ice;
    int surroundingIce =  n.b > 0.9 ? 1 : 0 + 
                         ne.b > 0.9 ? 1 : 0 + 
                          w.b > 0.9 ? 1 : 0 + 
                          e.b > 0.9 ? 1 : 0 + 
                         sw.b > 0.9 ? 1 : 0 + 
                          s.b > 0.9 ? 1 : 0;
    
    // frozen cell if st >= 1
    // surrounded by at least 1 frozen cell => boundary cell
    // boundary or frozen => receptive cell
    // water participating in diffusion = 0 for receptive cells
    
    // for all receptive cells: add y (vapor addition)
    // a is the diffusion coefficient
    // b is the fixed constant background vapor level
    
    //if (ice < 0.01)
    {
      // part of water in cell in contact with ice will turn into slush
      // slush will turn into ice if slush > water
      if (surroundingIce >= 1)
      {
        float waterToSlush = water * waterToSlushFactor;
        
        water -= waterToSlush;
        slush += waterToSlush;
      }
    }
    
    if (surroundingIce > 0)
    {
      //if ((surroundingIce >= 1 && surroundingIce <= 2 && slush > 0.3) ||
          //(surroundingIce >= 3 && surroundingIce <= 4 && slush > 0.6))
      //if (slush * 1.2 > surroundingIce)
      if (slush > freezingFactor)
      {
        ice = slush+water;
        slush = 0;
        //water = 0;
      }
    }
    
    color.r = water;
    color.g = slush;
    color.b = ice;
    color.a = c.a;
  }
  