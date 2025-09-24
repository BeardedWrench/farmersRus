-- Lamp prop material definition

return {
  -- Material properties
  name = 'prop_lamp',
  type = 'prop',
  
  -- Shader properties
  
  -- Material properties
  properties = {
    -- Base color
    baseColor = {0.8, 0.8, 0.8, 1.0},
    
    -- Emissive color
    emissiveColor = {1.0, 1.0, 0.8, 1.0},
    
    -- Metallic and roughness
    metallic = 0.8,
    roughness = 0.2,
    
    -- Normal map
    normalMap = 'assets/textures/prop_lamp_normal.png',
    normalScale = 1.0,
    
    -- Occlusion map
    occlusionMap = 'assets/textures/prop_lamp_occlusion.png',
    occlusionStrength = 1.0,
    
    -- Emissive map
    emissiveMap = 'assets/textures/prop_lamp_emissive.png',
    emissiveIntensity = 1.0,
    
    -- Alpha
    alpha = 1.0,
    alphaTest = 0.5,
    
    -- Blending
    blendMode = 'opaque',
    blendSrc = 'one',
    blendDst = 'zero',
    
    -- Culling
    cullMode = 'back',
    
    -- Depth
    depthTest = true,
    depthWrite = true,
    
    -- Stencil
    stencilTest = false,
    stencilRef = 0,
    stencilMask = 0xFF,
    stencilFunc = 'always',
    stencilPass = 'keep',
    stencilFail = 'keep',
    stencilZFail = 'keep'
  },
  
  -- Textures
  textures = {
    baseColor = 'assets/textures/prop_lamp_albedo.png',
    normal = 'assets/textures/prop_lamp_normal.png',
    occlusion = 'assets/textures/prop_lamp_occlusion.png',
    emissive = 'assets/textures/prop_lamp_emissive.png'
  },
  
  -- Custom properties
  customProperties = {
    isProp = true,
    isTransparent = false,
    isUnlit = false,
    castShadows = true,
    receiveShadows = true,
    isLight = true
  }
}
