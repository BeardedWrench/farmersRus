-- Sell stand material definition

return {
  -- Material properties
  name = 'shop_sell',
  type = 'building',
  
  -- Shader properties
  
  -- Material properties
  properties = {
    -- Base color
    baseColor = {0.7, 0.5, 0.3, 1.0},
    
    -- Emissive color
    emissiveColor = {0.0, 0.0, 0.0, 1.0},
    
    -- Metallic and roughness
    metallic = 0.0,
    roughness = 0.8,
    
    -- Normal map
    normalMap = 'assets/textures/shop_sell_normal.png',
    normalScale = 1.0,
    
    -- Occlusion map
    occlusionMap = 'assets/textures/shop_sell_occlusion.png',
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
    baseColor = 'assets/textures/shop_sell_albedo.png',
    normal = 'assets/textures/shop_sell_normal.png',
    occlusion = 'assets/textures/shop_sell_occlusion.png',
    emissive = nil
  },
  
  -- Custom properties
  customProperties = {
    isBuilding = true,
    isTransparent = false,
    isUnlit = false,
    castShadows = true,
    receiveShadows = true
  }
}
