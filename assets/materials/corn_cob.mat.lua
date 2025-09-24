-- Corn cob material definition

return {
  -- Material properties
  name = 'corn_cob',
  type = 'vegetation',
  
  -- Shader properties
  
  -- Material properties
  properties = {
    -- Base color
    baseColor = {0.8, 0.7, 0.3, 1.0},
    
    -- Emissive color
    emissiveColor = {0.0, 0.0, 0.0, 1.0},
    
    -- Metallic and roughness
    metallic = 0.0,
    roughness = 0.8,
    
    -- Normal map
    normalMap = 'assets/textures/corn_cob_normal.png',
    normalScale = 1.0,
    
    -- Occlusion map
    occlusionMap = 'assets/textures/corn_cob_occlusion.png',
    occlusionStrength = 1.0,
    
    -- Emissive map
    emissiveMap = nil,
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
    baseColor = 'assets/textures/corn_cob_albedo.png',
    normal = 'assets/textures/corn_cob_normal.png',
    occlusion = 'assets/textures/corn_cob_occlusion.png',
    emissive = nil
  },
  
  -- Custom properties
  customProperties = {
    isVegetation = true,
    isTransparent = false,
    isUnlit = false,
    castShadows = true,
    receiveShadows = true
  }
}
