local Save = {}

local function isArray(tbl)
  local count = 0
  for k in pairs(tbl) do
    if type(k) ~= 'number' then
      return false
    end
    count = count + 1
  end
  for i = 1, count do
    if tbl[i] == nil then
      return false
    end
  end
  return true
end

local function escape(str)
  return str:gsub('[%z\1-\31\"]', function(c)
    local byte = string.byte(c)
    local map = {
      [8] = '\\b',
      [9] = '\\t',
      [10] = '\\n',
      [12] = '\\f',
      [13] = '\\r'
    }
    return map[byte] or ('\\u%04x'):format(byte)
  end)
end

local function encode(value)
  local t = type(value)
  if t == 'nil' then
    return 'null'
  elseif t == 'number' then
    return tostring(value)
  elseif t == 'boolean' then
    return value and 'true' or 'false'
  elseif t == 'string' then
    return '"' .. escape(value) .. '"'
  elseif t == 'table' then
    if isArray(value) then
      local parts = {}
      for i = 1, #value do
        parts[#parts + 1] = encode(value[i])
      end
      return '[' .. table.concat(parts, ',') .. ']'
    else
      local parts = {}
      for k, v in pairs(value) do
        parts[#parts + 1] = encode(tostring(k)) .. ':' .. encode(v)
      end
      return '{' .. table.concat(parts, ',') .. '}'
    end
  else
    return 'null'
  end
end

local function skipWhitespace(str, index)
  local _, finish = str:find('^[%s]*', index)
  return (finish or index - 1) + 1
end

local function parseString(str, index)
  index = index + 1
  local buffer = {}
  while index <= #str do
    local char = str:sub(index, index)
    if char == '"' then
      return table.concat(buffer), index + 1
    elseif char == '\\' then
      local nextChar = str:sub(index + 1, index + 1)
      if nextChar == 'u' then
        local hex = str:sub(index + 2, index + 5)
        buffer[#buffer + 1] = string.char(tonumber(hex, 16))
        index = index + 6
      else
        local map = { b = '\b', f = '\f', n = '\n', r = '\r', t = '\t', ['\\'] = '\\', ['"'] = '"' }
        buffer[#buffer + 1] = map[nextChar] or nextChar
        index = index + 2
      end
    else
      buffer[#buffer + 1] = char
      index = index + 1
    end
  end
  return nil, index
end

local function parseNumber(str, index)
  local pattern = '^%-?%d+%.?%d*[eE]?[%+%-]?%d*'
  local s, e = str:find(pattern, index)
  if not s then
    return nil, index
  end
  local value = tonumber(str:sub(s, e))
  return value, e + 1
end

local function parseLiteral(str, index, literal, value)
  if str:sub(index, index + #literal - 1) == literal then
    return value, index + #literal
  end
  return nil, index
end

local function parseValue(str, index)
  index = skipWhitespace(str, index)
  local char = str:sub(index, index)
  if char == '{' then
    local object = {}
    index = index + 1
    index = skipWhitespace(str, index)
    if str:sub(index, index) == '}' then
      return object, index + 1
    end
    while index <= #str do
      local key
      key, index = parseValue(str, index)
      index = skipWhitespace(str, index)
      if str:sub(index, index) ~= ':' then
        return nil, index
      end
      index = skipWhitespace(str, index + 1)
      local value
      value, index = parseValue(str, index)
      object[key] = value
      index = skipWhitespace(str, index)
      local nextChar = str:sub(index, index)
      if nextChar == '}' then
        return object, index + 1
      elseif nextChar ~= ',' then
        return nil, index
      end
      index = index + 1
    end
  elseif char == '[' then
    local array = {}
    index = index + 1
    index = skipWhitespace(str, index)
    if str:sub(index, index) == ']' then
      return array, index + 1
    end
    local i = 1
    while index <= #str do
      local value
      value, index = parseValue(str, index)
      array[i] = value
      i = i + 1
      index = skipWhitespace(str, index)
      local nextChar = str:sub(index, index)
      if nextChar == ']' then
        return array, index + 1
      elseif nextChar ~= ',' then
        return nil, index
      end
      index = index + 1
    end
  elseif char == '"' then
    return parseString(str, index)
  elseif char == '-' or char:match('%d') then
    return parseNumber(str, index)
  elseif str:sub(index, index + 3) == 'true' then
    return true, index + 4
  elseif str:sub(index, index + 4) == 'false' then
    return false, index + 5
  elseif str:sub(index, index + 3) == 'null' then
    return nil, index + 4
  end
  return nil, index
end

local SOURCE_PATH = lovr and lovr.filesystem and lovr.filesystem.getSource and lovr.filesystem.getSource() or '.'
local SAVE_DIRECTORY = SOURCE_PATH .. '/saves'
local SAVE_FILE = SAVE_DIRECTORY .. '/save.json'

local function ensureSaveDirectory()
  if package.config:sub(1,1) == '\\' then
    os.execute(string.format('mkdir "%s" >NUL 2>NUL', SAVE_DIRECTORY))
  else
    os.execute(string.format('mkdir -p %q', SAVE_DIRECTORY))
  end
end

function Save.encode(data)
  return encode(data)
end

function Save.decode(str)
  local value, index = parseValue(str, 1)
  if value == nil then
    return nil
  end
  return value
end

function Save.tryLoad()
  ensureSaveDirectory()
  local file = io.open(SAVE_FILE, 'r')
  if not file then
    return nil
  end
  local contents = file:read('*a')
  file:close()
  if not contents or contents == '' then
    return nil
  end
  local ok, data = pcall(Save.decode, contents)
  if ok then
    return data
  end
  print('Failed to decode save file: ' .. tostring(data))
  return nil
end

function Save.write(data)
  ensureSaveDirectory()
  local json = Save.encode(data)
  local file, err = io.open(SAVE_FILE, 'w')
  if not file then
    print('Failed to open save file for writing: ' .. tostring(err))
    return
  end
  file:write(json)
  file:close()
end

return Save
