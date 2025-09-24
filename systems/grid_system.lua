return function(app)
  local util = app.util
  local grid = {
    cellSize = 1,
    bounds = {
      minX = -12,
      maxX = 12,
      minY = -12,
      maxY = 12
    },
    cells = {},
    hover = {
      x = 0,
      y = 0,
      world = { 0, 0, 0 },
      state = 'none'
    }
  }

  local function getCell(x, y)
    local column = grid.cells[x]
    if not column then
      column = {}
      grid.cells[x] = column
    end
    local cell = column[y]
    if not cell then
      cell = {
        occupied = false,
        blocking = false,
        entity = nil,
        highlight = 'none'
      }
      column[y] = cell
    end
    return cell
  end

  function grid:isWithin(x, y)
    return x >= self.bounds.minX and x <= self.bounds.maxX and y >= self.bounds.minY and y <= self.bounds.maxY
  end

  function grid:setOccupied(x, y, entity, blocking)
    local cell = getCell(x, y)
    cell.occupied = entity ~= nil
    cell.blocking = blocking or false
    cell.entity = entity
  end

  function grid:getOccupant(x, y)
    local column = self.cells[x]
    if not column then
      return nil
    end
    local cell = column[y]
    return cell and cell.entity or nil
  end

  function grid:setHighlight(x, y, state)
    local cell = getCell(x, y)
    cell.highlight = state
  end

  function grid:clearHighlights()
    for _, column in pairs(self.cells) do
      for _, cell in pairs(column) do
        cell.highlight = 'none'
      end
    end
  end

  function grid:eachCell(callback)
    for x = self.bounds.minX, self.bounds.maxX do
      for y = self.bounds.minY, self.bounds.maxY do
        callback(x, y, getCell(x, y))
      end
    end
  end

  function grid:worldToCell(wx, wz)
    local cx = util.round(wx / self.cellSize)
    local cy = util.round(wz / self.cellSize)
    return cx, cy
  end

  function grid:cellToWorld(cx, cy)
    return cx * self.cellSize, 0, cy * self.cellSize
  end

  app.grid = grid

  local system = {
    name = 'grid_system',
    updateOrder = -90,
    drawOrder = 10
  }

  local function computeRay()
    local camera = app.camera
    if not camera then
      return nil
    end
    local mouseX, mouseY = app.input:getMousePosition()
    local width, height
    if lovr.graphics.getDimensions then
      width, height = lovr.graphics.getDimensions()
    elseif lovr.graphics.getWidth and lovr.graphics.getHeight then
      width = lovr.graphics.getWidth()
      height = lovr.graphics.getHeight()
    elseif lovr.system and lovr.system.getWindowDimensions then
      width, height = lovr.system.getWindowDimensions()
    else
      width, height = 1280, 720
    end
    if not mouseX or not width or width == 0 then
      return nil
    end
    local ndcX = (mouseX / width) * 2 - 1
    local ndcY = 1 - (mouseY / height) * 2
    local aspect = width / height
    local fov = math.rad(67)
    local tanFov = math.tan(fov / 2)
    local viewX = ndcX * aspect * tanFov
    local viewY = ndcY * tanFov

    local fx = camera.target[1] - camera.position[1]
    local fy = camera.target[2] - camera.position[2]
    local fz = camera.target[3] - camera.position[3]
    local fLength = math.sqrt(fx * fx + fy * fy + fz * fz)
    if fLength < 1e-6 then
      return nil
    end
    fx, fy, fz = fx / fLength, fy / fLength, fz / fLength

    local upx, upy, upz = 0, 1, 0
    local rx = fy * upz - fz * upy
    local ry = fz * upx - fx * upz
    local rz = fx * upy - fy * upx
    local rLength = math.sqrt(rx * rx + ry * ry + rz * rz)
    if rLength == 0 then
      rx, ry, rz = 1, 0, 0
    else
      rx, ry, rz = rx / rLength, ry / rLength, rz / rLength
    end

    local ux = ry * fz - rz * fy
    local uy = rz * fx - rx * fz
    local uz = rx * fy - ry * fx

    local dirX = rx * viewX + ux * viewY + fx
    local dirY = ry * viewX + uy * viewY + fy
    local dirZ = rz * viewX + uz * viewY + fz
    local length = math.sqrt(dirX * dirX + dirY * dirY + dirZ * dirZ)
    dirX, dirY, dirZ = dirX / length, dirY / length, dirZ / length

    return {
      origin = { camera.position[1], camera.position[2], camera.position[3] },
      direction = { dirX, dirY, dirZ }
    }
  end

  function system:update(dt)
    local ray = computeRay()
    if not ray then
      return
    end
    local hit = app.util.rayPlane(ray.origin, ray.direction, { 0, 0, 0 }, { 0, 1, 0 })
    if not hit then
      return
    end

    grid.hover.world[1], grid.hover.world[2], grid.hover.world[3] = hit[1], hit[2], hit[3]
    local cx, cy = grid:worldToCell(hit[1], hit[3])
    grid.hover.x = cx
    grid.hover.y = cy
    local within = grid:isWithin(cx, cy)
    grid.hover.state = within and 'within' or 'out'

    app.events:emit('grid:hover', grid.hover)
  end

  function system:draw(pass)
    grid:eachCell(function(cx, cy, cell)
      local wx, _, wz = grid:cellToWorld(cx, cy)
      local tint
      if cell.highlight == 'valid' then
        tint = { 0.3, 0.9, 0.4, 0.25 }
      elseif cell.highlight == 'blocked' then
        tint = { 0.9, 0.3, 0.3, 0.25 }
      elseif cell.highlight == 'occupied' then
        tint = { 0.9, 0.8, 0.3, 0.2 }
      elseif cell.highlight == 'preview' then
        tint = { 0.3, 0.6, 0.9, 0.25 }
      elseif cell.highlight == 'hover' then
        tint = { 0.96, 0.82, 0.38, 0.45 }
      end
      if tint then
        pass:push('state')
        pass:setCullMode('none')
        pass:setColor(tint[1], tint[2], tint[3], tint[4])
        pass:plane(wx, 0.035, wz, grid.cellSize, grid.cellSize, -math.pi / 2, 1, 0, 0)
        pass:pop('state')
      end
    end)

    if grid.hover.state == 'within' then
      local wx, _, wz = grid:cellToWorld(grid.hover.x, grid.hover.y)
      pass:push('state')
      pass:setCullMode('none')
      pass:setDepthTest('lequal', true)
      pass:setColor(0.96, 0.82, 0.38, 0.45)
      pass:plane(wx, 0.04, wz, grid.cellSize, grid.cellSize, -math.pi / 2, 1, 0, 0)
      pass:setColor(0.96, 0.82, 0.38, 1.0)
      local half = grid.cellSize * 0.5
      pass:line(wx - half, 0.045, wz - half, wx + half, 0.045, wz - half)
      pass:line(wx + half, 0.045, wz - half, wx + half, 0.045, wz + half)
      pass:line(wx + half, 0.045, wz + half, wx - half, 0.045, wz + half)
      pass:line(wx - half, 0.045, wz + half, wx - half, 0.045, wz - half)
      pass:pop('state')
    end

    local minX, maxX = grid.bounds.minX - 0.5, grid.bounds.maxX + 0.5
    local minZ, maxZ = grid.bounds.minY - 0.5, grid.bounds.maxY + 0.5
    pass:push('state')
    pass:setCullMode('none')
    pass:setColor(1, 1, 1, 0.08)
    for x = grid.bounds.minX, grid.bounds.maxX + 1 do
      local wx = x - 0.5
      pass:line(wx, 0.025, minZ, wx, 0.025, maxZ)
    end
    for z = grid.bounds.minY, grid.bounds.maxY + 1 do
      local wz = z - 0.5
      pass:line(minX, 0.025, wz, maxX, 0.025, wz)
    end
    pass:pop('state')

    pass:setColor(1, 1, 1, 1)
  end

  return system
end
