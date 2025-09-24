local Log = {}
Log.__index = Log

local function timestamp()
  return os.date('%Y-%m-%d %H:%M:%S')
end

local function ensureDirectory(path)
  local dir = path:match('(.+)/[^/]+$')
  if not dir or dir == '' then
    return
  end
  if package.config:sub(1, 1) == '\\' then
    os.execute(string.format('mkdir "%s" >NUL 2>NUL', dir))
  else
    os.execute(string.format('mkdir -p %q', dir))
  end
end

function Log.new(path)
  path = path or 'logs/boot.log'
  local source = lovr and lovr.filesystem and lovr.filesystem.getSource and lovr.filesystem.getSource() or '.'
  local absolute = source .. '/' .. path
  ensureDirectory(absolute)

  local file, err = io.open(absolute, 'w')
  if not file then
    print('[Log] Failed to initialize log at', absolute, err or '')
    return setmetatable({ path = absolute, file = nil }, Log)
  end

  file:write(string.format('[%s] log start\n', timestamp()))
  file:flush()
  print('[Log] writing to', absolute)
  return setmetatable({ path = absolute, file = file }, Log)
end

function Log:line(kind, message)
  if not self.file then
    return
  end
  local entry = string.format('[%s][%s] %s\n', timestamp(), kind or 'INFO', message)
  self.file:write(entry)
  self.file:flush()
end

function Log:info(message)
  self:line('INFO', message)
end

function Log:error(message)
  self:line('ERROR', message)
end

function Log:close()
  if self.file then
    self.file:close()
    self.file = nil
  end
end

return Log
