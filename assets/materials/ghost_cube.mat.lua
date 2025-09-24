-- Ghost cube material definition

return {
  -- Material properties
  name = 'ghost_cube',
  type = 'preview',
  
  -- Shader properties
  
  -- Material properties
  properties = {
    -- Base color
    baseColor = {0.5, 0.8, 0.5, 0.5},
    
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
    alpha = 0.5,
    alphaTest = 0.5,
    
    -- Blending
    blendMode = 'alpha',
    blendSrc = 'src_alpha',
    blendDst = 'one_minus_src_alpha',
    
    -- Culling
    cullMode = 'back',
    
    -- Depth
    depthTest = true,
    depthWrite = false,
    
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
    baseColor = nil,
    normal = nil,
    occlusion = nil,
    emissive = nil
  },
  
  -- Custom properties
  customProperties = {
    isPreview = true,
    isTransparent = true,
    isUnlit = false,
    castShadows = false,
    receiveShadows = false
  }
}
