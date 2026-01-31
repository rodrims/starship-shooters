---@diagnostic disable-next-line: lowercase-global
fennel = require("lib.fennel")
debug.traceback = fennel.traceback
table.insert(package.loaders, function(module)
  local filename = module

  -- the fnl lsp only understands (require :src.file)
  -- but at runtime this becomes "src/file.lua" instead of .fnl
  -- so, we help out a bit here, though it's a bit hacky
  if filename:sub(-4) ~= ".fnl" then
    filename = filename:gsub("%.", "/") .. ".fnl"
  end

   if love.filesystem.getInfo(filename) then
      return function(...)
         return fennel.eval(love.filesystem.read(filename), {env=_G, filename=filename}, ...), filename
      end
   end
end)
-- jump into Fennel
require("main.fnl")
