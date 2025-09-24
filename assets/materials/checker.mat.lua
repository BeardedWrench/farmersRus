-- Checker material definition

return {
  -- Material properties
  name = 'checker',
  type = 'ui',
  
  -- Shader properties
  
  -- Material properties
  properties = {
    -- Base color
    baseColor = {1.0, 1.0, 1.0, 1.0},
    
    -- Emissive color
    emissiveColor = {0.0, 0.0, 0.0, 1.0},
    
    -- Metallic and roughness
    metallic = 0.0,
    roughness = 0.8,
    
    -- Normal map
    normalMap = nil,
    normalScale = 1.0,
    
    -- Occlusion map
    occlusionMap = nil,
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
    cullMode = 'none',
    
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
    baseColor = 'assets/textures/checker.png',
    normal = nil,
    occlusion = nil,
    emissive = nil
  },
  
  -- Custom properties
  customProperties = {
    isUI = true,
    isTransparent = false,
    isUnlit = true,
    castShadows = false,
    receiveShadows = false
  }
}
